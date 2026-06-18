module GameReviews
  class Remover
    def initialize(user_id, game_id:)
      @user_id = user_id
      @game_id = game_id.to_i
    end

    def call
      reviews = UserService.get_user_reviews(user_id)
      existing = reviews.find { |r| r['gameId'] == game_id }
      return false unless existing

      UserService.delete_review(user_id, review_id: existing['id'])
      true
    end

    private

    attr_reader :user_id, :game_id
  end
end
