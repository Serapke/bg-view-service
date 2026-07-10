module Events
  MAX_RECOMMENDED = 8

  class Fetcher
    def initialize(user_id, event_id:)
      @user_id = user_id
      @event_id = event_id
    end

    def call
      event = EventService.get_event(@user_id, event_id: @event_id)
      enrich(event)
    rescue EventService::NotFoundError => e
      raise EventNotFoundError, e.message
    end

    private

    def enrich(event)
      rec = event['recommendation']
      return event.merge('recommendation' => empty_rec) unless rec

      participant_count = Array(event['participantIds']).size.to_i
      filters = participant_count > 0 ? { player_count: participant_count } : {}

      owned_games      = fetch_in_order(Array(rec['ownedGameIds']), filters).first(MAX_RECOMMENDED)
      acquirable_games = fetch_in_order(Array(rec['acquirableGameIds']), filters).first(MAX_RECOMMENDED)

      viewer_collection = viewer_collection_ids
      viewer_ratings    = viewer_ratings_by_game_id
      owned_game_ids    = owned_games.map { |g| g['id'] }
      plays_counts      = UserService.get_plays_counts_this_year(@user_id, owned_game_ids)

      event.merge(
        'recommendation' => {
          'status' => rec['status'],
          'error'  => rec['error'],
          'ownedGames'      => enrich_for_viewer(owned_games, viewer_collection, viewer_ratings, plays_counts),
          'acquirableGames' => enrich_for_viewer(acquirable_games, viewer_collection, viewer_ratings)
        }
      )
    end

    def fetch_in_order(ids, filters)
      return [] if ids.empty?

      games = GameDiscoveryService.get_games_by_ids(ids, filters: filters) || []
      by_id = games.index_by { |g| g['id'] }
      ids.map { |id| by_id[id] }.compact
    end

    def enrich_for_viewer(games, viewer_collection, viewer_ratings, plays_counts = {})
      games.map do |g|
        {
          'game' => g,
          'in_collection' => viewer_collection.include?(g['id']),
          'user_rating' => viewer_ratings[g['id']],
          'plays_this_year' => plays_counts[g['id'].to_s]&.to_i || 0
        }
      end
    end

    def viewer_collection_ids
      response = UserService.get_user_collection(@user_id)
      (response['games'] || []).map { |g| g['gameId'] }.to_set
    rescue StandardError
      Set.new
    end

    def viewer_ratings_by_game_id
      reviews = UserService.get_user_reviews(@user_id) || []
      reviews.each_with_object({}) { |r, acc| acc[r['gameId']] = r['rating'] }
    rescue StandardError
      {}
    end

    def empty_rec
      { 'status' => 'pending', 'error' => nil, 'ownedGames' => [], 'acquirableGames' => [] }
    end
  end

  class EventNotFoundError < StandardError; end
end
