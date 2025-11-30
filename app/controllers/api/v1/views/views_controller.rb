class Api::V1::Views::ViewsController < ApplicationController
  def user_collections
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      filters = build_collection_filters
      enriched_items = UserCollections::Fetcher.new(user_id, filters: filters).call
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

  def review_game
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      result = GameReviews::Creator.new(
        user_id,
        game_id: params[:game_id],
        rating: params[:rating],
        review_text: params[:review_text]
      ).call

      serialized_review = GameReviews::Serializer.serialize(result[:review])

      render json: serialized_review, status: :created
    rescue GameReviews::GameNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "Error creating review: #{e.message}"
      render json: { error: 'Failed to create review' }, status: :internal_server_error
    end
  end

  private

  def build_collection_filters
    filters = {}
    filters[:min_user_rating] = params[:min_user_rating] if params[:min_user_rating].present?
    filters[:player_count] = params[:player_count] if params[:player_count].present?
    filters[:max_playing_time] = params[:max_playing_time] if params[:max_playing_time].present?
    filters[:game_types] = params[:game_types] if params[:game_types].present?
    filters[:min_rating] = params[:min_rating] if params[:min_rating].present?
    filters
  end
end