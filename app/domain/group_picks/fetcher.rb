module GroupPicks
  class Fetcher
    def initialize(host_user_ids:, extra_game_ids:, player_user_ids:,
                   player_count: nil, max_playing_time: nil, max_difficulty: nil)
      @host_user_ids    = normalize_ids(host_user_ids)
      @extra_game_ids   = normalize_ids(extra_game_ids)
      @player_user_ids  = normalize_ids(player_user_ids)
      @player_count     = player_count
      @max_playing_time = max_playing_time
      @max_difficulty   = max_difficulty
    end

    def call
      ranked = RecommenderService.get_group_picks(
        host_user_ids:    host_user_ids,
        extra_game_ids:   extra_game_ids,
        player_user_ids:  player_user_ids,
        player_count:     player_count,
        max_playing_time: max_playing_time,
        max_difficulty:   max_difficulty
      )
      return [] if ranked.empty?

      ids           = ranked.map { |r| r['id'] }
      games_by_id   = GameDiscoveryService.get_games_by_ids(ids).to_a.index_by { |g| g['id'] }
      owners_by_gid = build_owners_map
      extras_set    = extra_game_ids.to_set

      ranked.map do |r|
        game = games_by_id[r['id']]
        next unless game

        owners  = owners_by_gid[r['id']] || []
        enriched = game.merge('in_collection' => owners.any?, 'user_rating' => nil)
        {
          game:               enriched,
          score:              r['score'],
          owned_by_host_ids:  owners,
          is_extra:           extras_set.include?(r['id'])
        }
      end.compact
    end

    private

    attr_reader :host_user_ids, :extra_game_ids, :player_user_ids,
                :player_count, :max_playing_time, :max_difficulty

    def build_owners_map
      owners = Hash.new { |h, k| h[k] = [] }
      host_user_ids.each do |uid|
        collection = UserService.get_user_collection(uid.to_s) rescue { 'games' => [] }
        (collection['games'] || []).each do |g|
          next unless g['status'] == 'OWN'

          gid = g['gameId']&.to_i
          owners[gid] << uid if gid
        end
      end
      owners
    end

    def normalize_ids(ids)
      Array(ids).map(&:to_i).uniq.reject(&:zero?)
    end
  end
end
