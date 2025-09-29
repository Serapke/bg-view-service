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
end