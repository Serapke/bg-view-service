module GameReviews
  class Updater
    def initialize(user_id, game_id:, rating:, review_text: nil)
      @user_id = user_id
      @game_id = game_id.to_i
      @rating = rating
      @review_text = review_text
    end

    def call
      reviews = UserService.get_user_reviews(user_id)
      existing = reviews.find { |r| r['gameId'] == game_id }

      if existing
        UserService.update_review(user_id, review_id: existing['id'], rating: rating, review_text: review_text)
      else
        UserService.create_review(user_id, game_id: game_id, rating: rating, review_text: review_text)
      end
    end

    private

    attr_reader :user_id, :game_id, :rating, :review_text
  end
end
