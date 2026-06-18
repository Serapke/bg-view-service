module Events
  class Creator
    def initialize(user_id, user_ids:, title: nil)
      @user_id = user_id
      @user_ids = user_ids
      @title = title
    end

    def call
      EventService.create_event(@user_id, user_ids: @user_ids, title: @title)
    end
  end
end
