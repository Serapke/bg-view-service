class GameDiscoveryService
  BASE_URL = ENV.fetch('GAME_DISCOVERY_SERVICE_URL', 'http://localhost:3002')

  def self.get_game_by_id(game_id)
    connection = Faraday.new(url: BASE_URL)
    response = connection.get("/api/v1/board_games/#{game_id}")

    if response.success?
      JSON.parse(response.body)
    elsif response.status == 404
      nil
    else
      raise StandardError, "Failed to fetch game: #{response.status} - #{response.reason_phrase}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "GameDiscoveryService JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response format from game discovery service"
  rescue StandardError => e
    Rails.logger.error "GameDiscoveryService error: #{e.message}"
    raise e
  end

  def self.get_games_by_ids(game_ids)
    return [] if game_ids.empty?

    connection = Faraday.new(url: BASE_URL)
    response = connection.get("/api/v1/board_games", { ids: game_ids.join(',') })

    if response.success?
      JSON.parse(response.body).dig('board_games')
    else
      raise StandardError, "Failed to fetch games: #{response.status} - #{response.reason_phrase}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "GameDiscoveryService JSON parsing error: #{e.message}"
    raise StandardError, "Invalid response format from game discovery service"
  rescue StandardError => e
    Rails.logger.error "GameDiscoveryService error: #{e.message}"
    raise e
  end
end