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
        notes: collection_item['notes'],
        labels: collection_item['labels'] || [],
        modified_at: collection_item['modifiedAt']
      }
    end
  end
end