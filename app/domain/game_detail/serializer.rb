module GameDetail
  class Serializer
    def self.serialize(game:, in_collection:, user_rating:)
      new.serialize(game: game, in_collection: in_collection, user_rating: user_rating)
    end

    def serialize(game:, in_collection:, user_rating:)
      game.merge(
        'in_collection' => in_collection,
        'user_rating' => user_rating
      )
    end
  end
end
