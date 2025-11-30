module UserCollections
  class Serializer
    def self.serialize_collection(user_id, enriched_items)
      new.serialize_collection(user_id, enriched_items)
    end

    def self.serialize_item(collection_item, game)
      new.serialize_item(collection_item, game)
    end

    def serialize_collection(user_id, enriched_items)
      {
        user_id: user_id,
        collection: enriched_items.map { |item| serialize_item(item[:collection_item], item[:game]) },
        total_games: enriched_items.size
      }
    end

    def serialize_item(collection_item, game)
      {
        id: game['id'],
        name: game['name'],
        rating: game['rating'],
        difficulty_score: game['difficulty_score'],
        game_categories: game['game_categories'],
        game_types: game['game_types'],
        players: {
          min: game['min_players'],
          max: game['max_players']
        },
        playing_time: {
          min: game['min_playing_time'],
          max: game['max_playing_time']
        },
        notes: collection_item['notes'],
        labels: collection_item['labels'] || [],
        user_rating: collection_item['userRating'],
        modified_at: collection_item['modifiedAt']
      }
    end
  end
end