class EventService
  BASE_URL = ENV.fetch('EVENT_SERVICE_URL', 'http://localhost:3005')

  class ClientError < StandardError; end
  class NotFoundError < StandardError; end

  def self.create_event(user_id, user_ids:, title: nil, scheduled_date: nil)
    connection = Faraday.new(url: BASE_URL) do |conn|
      conn.request :json
      conn.response :json
    end

    response = connection.post("/api/v1/events") do |req|
      req.headers['X-User-ID'] = user_id
      req.headers['Content-Type'] = 'application/json'
      req.body = { userIds: user_ids, title: title, scheduledDate: scheduled_date }
    end

    if response.success?
      response.body
    elsif response.status < 500
      message = response.body.is_a?(Hash) ? response.body['error'] : nil
      raise ClientError, message || "Failed to create event"
    else
      raise StandardError, "Failed to create event: #{response.status}"
    end
  rescue StandardError => e
    Rails.logger.error "EventService error: #{e.message}"
    raise e
  end

  def self.get_event(user_id, event_id:)
    connection = Faraday.new(url: BASE_URL)

    response = connection.get("/api/v1/events/#{event_id}") do |req|
      req.headers['X-User-ID'] = user_id
    end

    if response.success?
      JSON.parse(response.body)
    elsif response.status == 404
      raise NotFoundError, "Event with ID #{event_id} not found"
    elsif response.status < 500
      message =
        begin
          JSON.parse(response.body)['error']
        rescue StandardError
          nil
        end
      raise ClientError, message || "Failed to fetch event"
    else
      raise StandardError, "Failed to fetch event: #{response.status}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "EventService JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response format from event service"
  rescue StandardError => e
    Rails.logger.error "EventService error: #{e.message}"
    raise e
  end

  def self.patch_event(user_id, event_id:, play_id:)
    connection = Faraday.new(url: BASE_URL) do |conn|
      conn.request :json
      conn.response :json
    end

    response = connection.patch("/api/v1/events/#{event_id}") do |req|
      req.headers['X-User-ID'] = user_id
      req.headers['Content-Type'] = 'application/json'
      req.body = { playId: play_id }
    end

    if response.success?
      response.body
    elsif response.status == 404
      raise NotFoundError, "Event with ID #{event_id} not found"
    elsif response.status < 500
      message = response.body.is_a?(Hash) ? response.body['error'] : nil
      raise ClientError, message || "Failed to update event"
    else
      raise StandardError, "Failed to update event: #{response.status}"
    end
  rescue StandardError => e
    Rails.logger.error "EventService error: #{e.message}"
    raise e
  end

  def self.list_events(user_id)
    connection = Faraday.new(url: BASE_URL)

    response = connection.get("/api/v1/events") do |req|
      req.headers['X-User-ID'] = user_id
    end

    if response.success?
      body = JSON.parse(response.body)
      body['events'] || []
    elsif response.status < 500
      message =
        begin
          JSON.parse(response.body)['error']
        rescue StandardError
          nil
        end
      raise ClientError, message || "Failed to list events"
    else
      raise StandardError, "Failed to list events: #{response.status}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "EventService JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response format from event service"
  rescue StandardError => e
    Rails.logger.error "EventService error: #{e.message}"
    raise e
  end
end
