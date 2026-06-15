module Browse
  class Fetcher
    def initialize(user_id, page:, per_page:, sort:)
      @user_id = user_id
      @page = page
      @per_page = per_page
      @sort = sort
    end

    def call
      response = GameDiscoveryService.browse(page: @page, per_page: @per_page, sort: @sort)
      games = response['board_games'] || []

      collection_items = fetch_collection_items
      user_ratings = fetch_user_ratings

      {
        enriched_games: enrich(games, collection_items, user_ratings),
        page:           response['page']        || @page,
        per_page:       response['per_page']    || @per_page,
        total:          response['total']       || games.length,
        total_pages:    response['total_pages'] || 1
      }
    end

    private

    def fetch_collection_items
      response = UserService.get_user_collection(@user_id)
      (response['games'] || []).each_with_object({}) { |g, acc| acc[g['gameId']] = g }
    end

    def fetch_user_ratings
      reviews = UserService.get_user_reviews(@user_id)
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
