module GameDetail
  class Fetcher
    def initialize(user_id, game_id:)
      @user_id = user_id
      @game_id = game_id.to_i
    end

    def call
      game = GameDiscoveryService.get_game_by_id(game_id)
      raise GameNotFoundError, game_id if game.nil?

      collection_item = find_collection_item

      {
        game: game,
        in_collection: !collection_item.nil?,
        user_rating: collection_item&.dig('userRating')
      }
    end

    private

    attr_reader :user_id, :game_id

    def find_collection_item
      collection = UserService.get_user_collection(user_id)
      items = collection['games'] || []
      items.find { |item| item['gameId'] == game_id }
    end
  end
end
