class Api::V1::Views::ViewsController < ApplicationController
  def user_collections
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      # Get user's collection from user service (forwarding the user_id header)
      user_collection = UserService.get_user_collection(user_id)

      # Extract game IDs from the collection
      game_ids = user_collection.dig('games')&.map { |item| item['gameId'] }&.compact || []

      # Get game details from game discovery service
      games = if game_ids.any?
                GameDiscoveryService.get_games_by_ids(game_ids)
              else
                []
              end

      # Combine user collection data with game details
      enriched_collection = user_collection.dig('games')&.map do |collection_item|
        game = games.find { |g| g['id'] == collection_item['gameId'] }
        collection_item_json(collection_item, game) if game
      end&.compact || []

      render json: {
        user_id: user_id,
        collection: enriched_collection,
        total_games: enriched_collection.size
      }

    rescue StandardError => e
      Rails.logger.error "Error fetching user collection: #{e.message}"
      render json: { error: 'Failed to fetch user collection' }, status: :internal_server_error
    end
  end

  def collection_item_json(collection_item, game)
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