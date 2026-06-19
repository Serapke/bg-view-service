module Events
  class ListFetcher
    def initialize(user_id)
      @user_id = user_id
    end

    def call
      EventService.list_events(@user_id)
    end
  end
end
