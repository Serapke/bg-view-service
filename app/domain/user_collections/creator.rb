module UserCollections
  class Creator
    def initialize(user_id, game_id:, notes: nil, label_names: [])
      @user_id = user_id
      @game_id = game_id
      @notes = notes
      @label_names = label_names
    end

    def call
      game = fetch_and_validate_game!
      collection_item = add_to_user_collection
      { collection_item: collection_item, game: game }
    end

    private

    attr_reader :user_id, :game_id, :notes, :label_names

    def fetch_and_validate_game!
      game = GameDiscoveryService.get_game_by_id(game_id)
      raise GameNotFoundError, "Game with ID #{game_id} not found" if game.nil?
      game
    end

    def add_to_user_collection
      UserService.add_game_to_collection(
        user_id,
        game_id: game_id,
        notes: notes,
        label_names: label_names
      )
    end
  end

  class GameNotFoundError < StandardError; end
end