class Api::V1::Views::ViewsController < ApplicationController
  def user_collections
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      enriched_items = UserCollections::Enricher.new(user_id).call
      response = UserCollections::Serializer.serialize_collection(user_id, enriched_items)
      render json: response
    rescue StandardError => e
      Rails.logger.error "Error fetching user collection: #{e.message}"
      render json: { error: 'Failed to fetch user collection' }, status: :internal_server_error
    end
  end

  def add_game
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      result = UserCollections::Creator.new(
        user_id,
        game_id: params[:game_id],
        notes: params[:notes],
        label_names: params[:label_names] || []
      ).call

      serialized_item = UserCollections::Serializer.serialize_item(
        result[:collection_item],
        result[:game]
      )

      render json: serialized_item, status: :created
    rescue UserCollections::GameNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "Error adding game to collection: #{e.message}"
      render json: { error: 'Failed to add game to collection' }, status: :internal_server_error
    end
  end

  def remove_game
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      UserCollections::Remover.new(user_id, game_id: params[:game_id]).call
      render json: { message: 'Game removed from collection successfully' }, status: :ok
    rescue StandardError => e
      Rails.logger.error "Error removing game from collection: #{e.message}"
      render json: { error: 'Failed to remove game from collection' }, status: :internal_server_error
    end
  end
end