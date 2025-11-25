module UserCollections
  class Enricher
    def initialize(user_id)
      @user_id = user_id
    end

    def call
      user_collection = fetch_user_collection
      game_ids = extract_game_ids(user_collection)
      games = fetch_games(game_ids)
      enrich_collection(user_collection, games)
    end

    private

    attr_reader :user_id

    def fetch_user_collection
      UserService.get_user_collection(user_id)
    end

    def extract_game_ids(user_collection)
      user_collection.dig('games')&.map { |item| item['gameId'] }&.compact || []
    end

    def fetch_games(game_ids)
      return [] if game_ids.empty?

      GameDiscoveryService.get_games_by_ids(game_ids)
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