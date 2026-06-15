module GameDetail
  class Serializer
    def self.serialize(game:, in_collection:, user_rating:, recommendations:)
      new.serialize(
        game: game,
        in_collection: in_collection,
        user_rating: user_rating,
        recommendations: recommendations
      )
    end

    def serialize(game:, in_collection:, user_rating:, recommendations:)
      game.merge(
        'in_collection' => in_collection,
        'user_rating' => user_rating,
        'recommendations' => recommendations
      )
    end
  end
end
