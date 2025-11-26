class UserService
  BASE_URL = ENV.fetch('USER_SERVICE_URL', 'http://localhost:8080')

  def self.get_user_collection(user_id)
    connection = Faraday.new(url: BASE_URL)
    response = connection.get("/api/v1/collections") do |req|
      req.headers['X-User-ID'] = user_id
    end

    if response.success?
      JSON.parse(response.body)
    else
      raise StandardError, "Failed to fetch user collection: #{response.status} - #{response.reason_phrase}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "UserService JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response format from user service"
  rescue StandardError => e
    Rails.logger.error "UserService error: #{e.message}"
    raise e
  end

  def self.add_game_to_collection(user_id, game_id:, notes: nil, label_names: [])
    connection = Faraday.new(url: BASE_URL) do |conn|
      conn.request :json
      conn.response :json
    end

    response = connection.post("/api/v1/collections/games") do |req|
      req.headers['X-User-ID'] = user_id
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        gameId: game_id,
        notes: notes,
        labelNames: label_names
      }
    end

    if response.success?
      response.body
    else
      raise StandardError, "Failed to add game to collection: #{response.status} - #{response.reason_phrase}"
    end
  rescue StandardError => e
    Rails.logger.error "UserService error: #{e.message}"
    raise e
  end

  def self.remove_game_from_collection(user_id, game_id:)
    connection = Faraday.new(url: BASE_URL)

    response = connection.delete("/api/v1/collections/games/#{game_id}") do |req|
      req.headers['X-User-ID'] = user_id
    end

    if response.success?
      true
    else
      raise StandardError, "Failed to remove game from collection: #{response.status} - #{response.reason_phrase}"
    end
  rescue StandardError => e
    Rails.logger.error "UserService error: #{e.message}"
    raise e
  end

  def self.create_review(user_id, game_id:, rating:, review_text:)
    connection = Faraday.new(url: BASE_URL) do |conn|
      conn.request :json
      conn.response :json
    end

    response = connection.post("/api/v1/reviews") do |req|
      req.headers['X-User-ID'] = user_id
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        gameId: game_id,
        rating: rating,
        reviewText: review_text
      }
    end

    if response.success?
      response.body
    else
      raise StandardError, "Failed to create review: #{response.status} - #{response.reason_phrase}"
    end
  rescue StandardError => e
    Rails.logger.error "UserService error: #{e.message}"
    raise e
  end
end