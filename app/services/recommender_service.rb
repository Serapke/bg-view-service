class RecommenderService
  BASE_URL = ENV.fetch('RECOMMENDER_SERVICE_URL', 'http://localhost:3004')

  def self.get_recommended_game_ids(game_id)
    connection = Faraday.new(url: BASE_URL)
    response = connection.get("/api/v1/recommendations/games/#{game_id}")

    if response.success?
      JSON.parse(response.body).dig('recommended_game_ids') || []
    elsif response.status == 404
      []
    else
      raise StandardError, "Failed to fetch recommendations: #{response.status} - #{response.reason_phrase}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "RecommenderService JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response format from recommender service"
  rescue StandardError => e
    Rails.logger.error "RecommenderService error: #{e.message}"
    raise e
  end
end
