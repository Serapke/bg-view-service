module UserReviews
  class Fetcher
    def initialize(user_id)
      @user_id = user_id
    end

    def call
      reviews = UserService.get_user_reviews(user_id)
      game_ids = reviews.map { |r| r['gameId'] }.compact.uniq
      games = game_ids.empty? ? [] : GameDiscoveryService.get_games_by_ids(game_ids)
      enrich(reviews, games)
    end

    private

    attr_reader :user_id

    def enrich(reviews, games)
      games_by_id = games.index_by { |g| g['id'] }

      reviews.map do |review|
        game = games_by_id[review['gameId']]

        unless game
          Rails.logger.warn(
            "Game not found in discovery service - user_id: #{user_id}, game_id: #{review['gameId']}"
          )
          next
        end

        { review: review, game: game }
      end.compact
    end
  end
end
