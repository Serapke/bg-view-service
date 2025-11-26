module GameReviews
  class Serializer
    def self.serialize(review)
      new.serialize(review)
    end

    def serialize(review)
      {
        id: review['id'],
        game_id: review['gameId'],
        rating: review['rating'],
        review_text: review['reviewText'],
        created_at: review['createdAt']
      }
    end
  end
end
