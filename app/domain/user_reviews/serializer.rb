module UserReviews
  class Serializer
    def self.serialize_list(user_id, enriched_items)
      new.serialize_list(user_id, enriched_items)
    end

    def serialize_list(user_id, enriched_items)
      {
        user_id: user_id,
        total_reviews: enriched_items.size,
        reviews: enriched_items.map { |item| serialize_item(item[:review], item[:game]) }
      }
    end

    def serialize_item(review, game)
      {
        id: review['id'],
        rating: review['rating'],
        review_text: review['reviewText'],
        created_at: review['createdAt'],
        updated_at: review['updatedAt'],
        game: {
          id: game['id'],
          name: game['name'],
          rating: game['rating'],
          rating_count: game['rating_count'],
          game_types: game['game_types'],
          image_url: game['image_url'],
          thumbnail_url: game['thumbnail_url'],
          players: {
            min: game['min_players'],
            max: game['max_players']
          },
          playing_time: {
            min: game['min_playing_time'],
            max: game['max_playing_time']
          }
        }
      }
    end
  end
end
