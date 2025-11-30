module UserCollections
  class Fetcher
    def initialize(user_id, filters: {})
      @user_id = user_id
      @min_user_rating = filters[:min_user_rating]&.to_i
      @player_count = filters[:player_count]
      @max_playing_time = filters[:max_playing_time]
      @game_types = filters[:game_types]
      @min_rating = filters[:min_rating]
    end

    def call
      user_collection = fetch_user_collection
      filtered_collection = filter_by_user_rating(user_collection)
      game_ids = extract_game_ids(filtered_collection)
      games = fetch_games(game_ids)
      enrich_collection(filtered_collection, games)
    end

    private

    attr_reader :user_id, :min_user_rating, :player_count, :max_playing_time, :game_types, :min_rating

    def fetch_user_collection
      UserService.get_user_collection(user_id)
    end

    def filter_by_user_rating(user_collection)
      return user_collection unless min_user_rating

      games = user_collection['games'] || []
      filtered_games = games.select do |game|
        user_rating = game['userRating']
        user_rating && user_rating >= min_user_rating
      end

      { 'games' => filtered_games }
    end

    def extract_game_ids(user_collection)
      user_collection.dig('games')&.map { |item| item['gameId'] }&.compact || []
    end

    def fetch_games(game_ids)
      return [] if game_ids.empty?

      discovery_filters = build_discovery_filters
      GameDiscoveryService.get_games_by_ids(game_ids, filters: discovery_filters)
    end

    def build_discovery_filters
      filters = {}
      filters[:player_count] = player_count if player_count
      filters[:max_playing_time] = max_playing_time if max_playing_time
      filters[:game_types] = game_types if game_types
      filters[:min_rating] = min_rating if min_rating
      filters
    end

    def enrich_collection(user_collection, games)
      collection_items = user_collection.dig('games') || []

      collection_items.map do |collection_item|
        game = find_game_by_id(games, collection_item['gameId'])

        unless game
          Rails.logger.warn(
            "Game not found in discovery service - user_id: #{user_id}, game_id: #{collection_item['gameId']}"
          )
          next
        end

        { collection_item: collection_item, game: game }
      end.compact
    end

    def find_game_by_id(games, game_id)
      games.find { |g| g['id'] == game_id }
    end
  end
end