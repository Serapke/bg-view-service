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

  def self.get_games_by_ids(game_ids, filters: {})
    return [] if game_ids.empty?

    connection = Faraday.new(url: BASE_URL)
    params = { ids: game_ids.join(',') }
    params[:player_count] = filters[:player_count] if filters[:player_count]
    params[:max_playing_time] = filters[:max_playing_time] if filters[:max_playing_time]
    params[:game_types] = filters[:game_types] if filters[:game_types]
    params[:min_rating] = filters[:min_rating] if filters[:min_rating]

    response = connection.get("/api/v1/board_games", params)

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