module GameSearch
  class Serializer
    def self.serialize_results(enriched_games, importing: false)
      results = enriched_games.map { |item| serialize_game(item[:game], item[:in_collection], item[:user_rating]) }
      { board_games: results, total: results.size, importing: importing }
    end

    def self.serialize_paginated(enriched_games, page:, per_page:, total:, total_pages:)
      results = enriched_games.map { |item| serialize_game(item[:game], item[:in_collection], item[:user_rating]) }
      { board_games: results, page: page, per_page: per_page, total: total, total_pages: total_pages }
    end

    def self.serialize_game(game, in_collection, user_rating)
      {
        id:               game['id'],
        name:             game['name'],
        rating:           game['rating'],
        rating_count:     game['rating_count'],
        difficulty_score: game['difficulty_score'],
        game_categories:  game['game_categories'],
        game_types:       game['game_types'],
        min_players:      game['min_players'],
        max_players:      game['max_players'],
        min_playing_time: game['min_playing_time'],
        max_playing_time: game['max_playing_time'],
        image_url:        game['image_url'],
        thumbnail_url:    game['thumbnail_url'],
        in_collection:    in_collection,
        user_rating:      user_rating
      }
    end
  end
end
