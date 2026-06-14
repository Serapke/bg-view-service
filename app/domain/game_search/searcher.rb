module GameSearch
  class Searcher
    def initialize(user_id, name:, filters: {})
      @user_id = user_id
      @name    = name
      @filters = filters
    end

    def call
      games          = GameDiscoveryService.search(name, filters: filters)
      collection_ids = fetch_collection_ids
      enrich(games, collection_ids)
    end

    private

    attr_reader :user_id, :name, :filters

    def fetch_collection_ids
      response = UserService.get_user_collection(user_id)
      (response['games'] || []).map { |g| g['gameId'] }.to_set
    end

    def enrich(games, collection_ids)
      games.map { |game| { game: game, in_collection: collection_ids.include?(game['id']) } }
    end
  end
end
