module GameSearch
  class Searcher
    def initialize(user_id, name:, filters: {})
      @user_id = user_id
      @name    = name
      @filters = filters
    end

    def call
      games            = GameDiscoveryService.search(name, filters: filters)
      collection_items = fetch_collection_items
      enrich(games, collection_items)
    end

    private

    attr_reader :user_id, :name, :filters

    def fetch_collection_items
      response = UserService.get_user_collection(user_id)
      (response['games'] || []).each_with_object({}) do |g, acc|
        acc[g['gameId']] = g
      end
    end

    def enrich(games, collection_items)
      games.map do |game|
        item = collection_items[game['id']]
        {
          game:          game,
          in_collection: !item.nil?,
          user_rating:   item&.dig('userRating')
        }
      end
    end
  end
end
