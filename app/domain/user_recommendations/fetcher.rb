module UserRecommendations
  class Fetcher
    def initialize(user_id)
      @user_id = user_id
    end

    def call
      ids = RecommenderService.get_user_recommended_game_ids(user_id)
      return [] if ids.empty?

      games            = GameDiscoveryService.get_games_by_ids(ids) || []
      ordered          = order_by_ids(games, ids)
      collection_items = fetch_collection_items
      user_ratings     = fetch_user_ratings
      enrich(ordered, collection_items, user_ratings)
    rescue StandardError => e
      Rails.logger.error "UserRecommendations::Fetcher error: #{e.message}"
      []
    end

    private

    attr_reader :user_id

    def order_by_ids(games, ids)
      by_id = games.index_by { |g| g['id'] }
      ids.map { |id| by_id[id] }.compact
    end

    def fetch_collection_items
      response = UserService.get_user_collection(user_id)
      (response['games'] || []).each_with_object({}) do |g, acc|
        acc[g['gameId']] = g
      end
    end

    def fetch_user_ratings
      reviews = UserService.get_user_reviews(user_id)
      reviews.each_with_object({}) { |r, acc| acc[r['gameId']] = r['rating'] }
    end

    def enrich(games, collection_items, user_ratings)
      games.map do |game|
        {
          game:          game,
          in_collection: collection_items.key?(game['id']),
          user_rating:   user_ratings[game['id']]
        }
      end
    end
  end
end
