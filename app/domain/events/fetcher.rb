module Events
  class Fetcher
    def initialize(user_id, event_id:)
      @user_id = user_id
      @event_id = event_id
    end

    def call
      EventService.get_event(@user_id, event_id: @event_id)
    rescue EventService::NotFoundError => e
      raise EventNotFoundError, e.message
    end
  end

  class EventNotFoundError < StandardError; end
end
