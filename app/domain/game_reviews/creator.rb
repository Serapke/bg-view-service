module GameReviews
  class Creator
    def initialize(user_id, game_id:, rating:, review_text:)
      @user_id = user_id
      @game_id = game_id
      @rating = rating
      @review_text = review_text
    end

    def call
      game = fetch_and_validate_game!
      review = create_review
      { review: review, game: game }
    end

    private

    attr_reader :user_id, :game_id, :rating, :review_text

    def fetch_and_validate_game!
      game = GameDiscoveryService.get_game_by_id(game_id)
      raise GameNotFoundError, "Game with ID #{game_id} not found" if game.nil?
      game
    end

    def create_review
      UserService.create_review(
        user_id,
        game_id: game_id,
        rating: rating,
        review_text: review_text
      )
    end
  end

  class GameNotFoundError < StandardError; end
end
