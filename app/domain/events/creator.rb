module Events
  class Creator
    def initialize(user_id, user_ids:, title: nil, scheduled_date: nil)
      @user_id = user_id
      @user_ids = user_ids
      @title = title
      @scheduled_date = scheduled_date
    end

    def call
      EventService.create_event(@user_id, user_ids: @user_ids, title: @title, scheduled_date: @scheduled_date)
    end
  end
end
