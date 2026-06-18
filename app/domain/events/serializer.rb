module Events
  class Serializer
    def self.serialize(event)
      {
        id: event['id'],
        creator_id: event['creatorId'],
        title: event['title'],
        participant_ids: event['participantIds'],
        created_at: event['createdAt']
      }
    end
  end
end
