Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :views do
        get 'search', to: 'views#search_games'
        get 'trending', to: 'views#trending'
        get 'recommendations', to: 'views#recommendations'
        post 'group_picks', to: 'views#group_picks'
        get 'browse', to: 'views#browse'
        get 'games/:id', to: 'views#game_detail'
        get 'collections', to: 'views#user_collections'
        post 'collections/games', to: 'views#add_game'
        delete 'collections/games/:game_id', to: 'views#remove_game'
        get 'reviews', to: 'views#user_reviews'
        post 'reviews', to: 'views#review_game'
        patch 'reviews', to: 'views#upsert_review'
        delete 'reviews/:game_id', to: 'views#delete_review'
        post  'events', to: 'views#create_event'
        get   'events', to: 'views#user_events'
        get   'events/:id', to: 'views#get_event'
        patch 'events/:id', to: 'views#update_event'
        get    'events/:id/plays', to: 'views#event_plays'
        delete 'events/:id', to: 'views#delete_event'
      end
    end
  end
end
