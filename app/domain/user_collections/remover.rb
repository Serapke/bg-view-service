module UserCollections
  class Remover
    def initialize(user_id, game_id:)
      @user_id = user_id
      @game_id = game_id
    end

    def call
      remove_from_user_collection
    end

    private

    attr_reader :user_id, :game_id

    def remove_from_user_collection
      UserService.remove_game_from_collection(user_id, game_id: game_id)
    end
  end
end
