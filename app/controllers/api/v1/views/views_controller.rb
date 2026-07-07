class Api::V1::Views::ViewsController < ApplicationController
  def search_games
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    name = params[:name]
    return render json: { error: 'name parameter is required' }, status: :bad_request if name.blank?

    begin
      filters        = build_search_filters
      searcher       = GameSearch::Searcher.new(user_id, name: name, filters: filters)
      enriched_games = searcher.call
      result         = GameSearch::Serializer.serialize_results(enriched_games, importing: searcher.importing?)
      render json: result
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error searching games: #{e.message}"
      render json: { error: 'Failed to search games' }, status: :internal_server_error
    end
  end

  def trending
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      enriched_games = Trending::Fetcher.new(user_id).call
      result         = GameSearch::Serializer.serialize_results(enriched_games)
      render json: result
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error fetching trending games: #{e.message}"
      render json: { error: 'Failed to fetch trending games' }, status: :internal_server_error
    end
  end

  def recommendations
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      enriched_games = UserRecommendations::Fetcher.new(user_id).call
      result         = GameSearch::Serializer.serialize_results(enriched_games)
      render json: result
    rescue StandardError => e
      Rails.logger.error "Error fetching recommendations: #{e.message}"
      render json: { error: 'Failed to fetch recommendations' }, status: :internal_server_error
    end
  end

  def group_picks
    picks = GroupPicks::Fetcher.new(
      host_user_ids:    params[:host_user_ids],
      extra_game_ids:   params[:extra_game_ids],
      player_user_ids:  params[:player_user_ids],
      player_count:     params[:player_count],
      max_playing_time: params[:max_playing_time],
      max_difficulty:   params[:max_difficulty]
    ).call
    render json: GroupPicks::Serializer.serialize(picks)
  rescue StandardError => e
    Rails.logger.error "Error fetching group picks: #{e.message}"
    render json: { error: 'Failed to fetch group picks' }, status: :internal_server_error
  end

  def browse
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      result = Browse::Fetcher.new(
        user_id,
        page: params[:page],
        per_page: params[:per_page],
        sort: params[:sort]
      ).call
      render json: GameSearch::Serializer.serialize_paginated(
        result[:enriched_games],
        page: result[:page],
        per_page: result[:per_page],
        total: result[:total],
        total_pages: result[:total_pages]
      )
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error browsing games: #{e.message}"
      render json: { error: 'Failed to browse games' }, status: :internal_server_error
    end
  end

  def game_detail
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      result = GameDetail::Fetcher.new(user_id, game_id: params[:id]).call
      render json: GameDetail::Serializer.serialize(**result)
    rescue GameDetail::GameNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error fetching game detail: #{e.message}"
      render json: { error: 'Failed to fetch game detail' }, status: :internal_server_error
    end
  end

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
        label_names: params[:label_names] || [],
        status: params[:status]
      ).call

      serialized_item = UserCollections::Serializer.serialize_item(
        result[:collection_item],
        result[:game]
      )

      render json: serialized_item, status: :created
    rescue UserCollections::GameNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
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

  def user_reviews
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      enriched_items = UserReviews::Fetcher.new(user_id).call
      response = UserReviews::Serializer.serialize_list(user_id, enriched_items)
      render json: response
    rescue StandardError => e
      Rails.logger.error "Error fetching user reviews: #{e.message}"
      render json: { error: 'Failed to fetch user reviews' }, status: :internal_server_error
    end
  end

  def upsert_review
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      GameReviews::Updater.new(
        user_id,
        game_id: params[:game_id],
        rating: params[:rating],
        review_text: params[:review_text]
      ).call
      render json: { message: 'Rating updated' }, status: :ok
    rescue GameReviews::GameNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error upserting review: #{e.message}"
      render json: { error: 'Failed to update rating' }, status: :internal_server_error
    end
  end

  def delete_review
    user_id = request.headers['X-User-ID']

    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      GameReviews::Remover.new(user_id, game_id: params[:game_id]).call
      render json: { message: 'Rating removed' }, status: :ok
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error removing review: #{e.message}"
      render json: { error: 'Failed to remove rating' }, status: :internal_server_error
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
    rescue UserService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error creating review: #{e.message}"
      render json: { error: 'Failed to create review' }, status: :internal_server_error
    end
  end

  def create_event
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    user_ids = params[:userIds] || params[:user_ids]
    return render json: { error: 'userIds is required' }, status: :bad_request if user_ids.nil?
    return render json: { error: 'userIds must be an array' }, status: :bad_request unless user_ids.is_a?(Array)

    begin
      event = Events::Creator.new(user_id, user_ids: user_ids, title: params[:title]).call
      render json: Events::Serializer.serialize(event), status: :created
    rescue EventService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error creating event: #{e.message}"
      render json: { error: 'Failed to create event' }, status: :internal_server_error
    end
  end

  def get_event
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      event = Events::Fetcher.new(user_id, event_id: params[:id]).call
      render json: Events::Serializer.serialize_with_recommendation(event), status: :ok
    rescue Events::EventNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue EventService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error fetching event: #{e.message}"
      render json: { error: 'Failed to fetch event' }, status: :internal_server_error
    end
  end

  def user_events
    user_id = request.headers['X-User-ID']
    return render json: { error: 'X-User-ID header is required' }, status: :unauthorized if user_id.blank?

    begin
      events = Events::ListFetcher.new(user_id).call
      render json: { events: events.map { |e| Events::Serializer.serialize(e) } }, status: :ok
    rescue EventService::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error listing events: #{e.message}"
      render json: { error: 'Failed to list events' }, status: :internal_server_error
    end
  end

  private

  def build_search_filters
    filters = {}
    filters[:player_count]     = params[:player_count]     if params[:player_count].present?
    filters[:max_playing_time] = params[:max_playing_time] if params[:max_playing_time].present?
    filters[:game_types]       = params[:game_types]       if params[:game_types].present?
    filters[:min_rating]       = params[:min_rating]       if params[:min_rating].present?
    filters
  end

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