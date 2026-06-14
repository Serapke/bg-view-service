module GameSearch
  class Serializer
    def self.serialize_results(enriched_games)
      results = enriched_games.map { |item| serialize_game(item[:game], item[:in_collection]) }
      { board_games: results, total: results.size }
    end

    def self.serialize_game(game, in_collection)
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
        in_collection:    in_collection
      }
    end
  end
end
