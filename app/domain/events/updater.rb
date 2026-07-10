module Events
  class Updater
    def initialize(user_id, event_id:, **kwargs)
      @user_id = user_id
      @event_id = event_id
      @kwargs = kwargs
    end

    def call
      EventService.patch_event_fields(@user_id, event_id: @event_id, **@kwargs)
    end
  end
end
