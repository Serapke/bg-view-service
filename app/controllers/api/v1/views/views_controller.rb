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
end