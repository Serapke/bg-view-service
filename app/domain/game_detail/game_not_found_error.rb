module GameDetail
  class GameNotFoundError < StandardError
    def initialize(game_id)
      super("Game with id #{game_id} not found")
    end
  end
end
