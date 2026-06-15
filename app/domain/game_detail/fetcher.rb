module GameDetail
  class Fetcher
    def initialize(user_id, game_id:)
      @user_id = user_id
      @game_id = game_id.to_i
    end

    def call
      game = GameDiscoveryService.get_game_by_id(game_id)
      raise GameNotFoundError, game_id if game.nil?

      {
        game: game,
        in_collection: in_collection?,
        user_rating: fetch_user_rating,
        recommendations: fetch_recommendations
      }
    end

    private

    attr_reader :user_id, :game_id

    def in_collection?
      collection = UserService.get_user_collection(user_id)
      items = collection['games'] || []
      items.any? { |item| item['gameId'] == game_id }
    end

    def fetch_user_rating
      reviews = UserService.get_user_reviews(user_id)
      review = reviews.find { |r| r['gameId'] == game_id }
      review&.dig('rating')
    end

    def fetch_recommendations
      ids = RecommenderService.get_recommended_game_ids(game_id)
      return [] if ids.empty?

      GameDiscoveryService.get_games_by_ids(ids) || []
    rescue StandardError => e
      Rails.logger.error "Failed to fetch recommendations for game #{game_id}: #{e.message}"
      []
    end
  end
end
