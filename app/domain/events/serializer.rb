module Events
  class Serializer
    def self.serialize(event)
      {
        id: event['id'],
        creator_id: event['creatorId'],
        title: event['title'],
        scheduled_date: event['scheduledDate'],
        participant_ids: event['participantIds'],
        game_play_ids: event['gamePlayIds'] || [],
        created_at: event['createdAt']
      }
    end

    def self.serialize_with_recommendation(event)
      base = serialize(event)
      rec = event['recommendation']
      return base unless rec

      base.merge(
        recommendation: {
          status: rec['status'],
          error: rec['error'],
          owned_games: serialize_games(rec['ownedGames']),
          acquirable_games: serialize_games(rec['acquirableGames'])
        }
      )
    end

    def self.serialize_games(items)
      Array(items).map do |item|
        GameSearch::Serializer.serialize_game(item['game'], item['in_collection'], item['user_rating'], item['plays_this_year'] || 0)
      end
    end
  end
end
