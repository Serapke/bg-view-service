require "test_helper"

class GroupPicks::FetcherTest < ActiveSupport::TestCase
  test "enriches ranked ids with game data, owners, and extra flag" do
    RecommenderService.stubs(:get_group_picks).returns([
      { "id" => 10, "score" => 8.0 },
      { "id" => 20, "score" => 7.0 }
    ])
    GameDiscoveryService.stubs(:get_games_by_ids).with([10, 20]).returns([
      { "id" => 10, "name" => "Catan" },
      { "id" => 20, "name" => "Azul" }
    ])
    UserService.stubs(:get_user_collection).with("1").returns({
      "games" => [
        { "gameId" => 10, "status" => "OWN" },
        { "gameId" => 30, "status" => "WANT" }
      ]
    })

    picks = GroupPicks::Fetcher.new(
      host_user_ids:    [1],
      extra_game_ids:   [20],
      player_user_ids:  [1]
    ).call

    assert_equal 2, picks.size
    assert_equal 10, picks[0][:game]["id"]
    assert_equal true, picks[0][:game]["in_collection"]
    assert_nil picks[0][:game]["user_rating"]
    assert_equal [1], picks[0][:owned_by_host_ids]
    assert_equal false, picks[0][:is_extra]
    assert_equal true, picks[1][:is_extra]
    assert_equal false, picks[1][:game]["in_collection"]
    assert_equal [], picks[1][:owned_by_host_ids]
  end

  test "returns empty when recommender returns nothing" do
    RecommenderService.stubs(:get_group_picks).returns([])

    picks = GroupPicks::Fetcher.new(
      host_user_ids: [1], extra_game_ids: [], player_user_ids: [1]
    ).call

    assert_equal [], picks
  end

  test "wishlist games are not credited as owned by hosts" do
    RecommenderService.stubs(:get_group_picks).returns([{ "id" => 30, "score" => 8.0 }])
    GameDiscoveryService.stubs(:get_games_by_ids).with([30]).returns([
      { "id" => 30, "name" => "Citadels" }
    ])
    UserService.stubs(:get_user_collection).with("1").returns({
      "games" => [{ "gameId" => 30, "status" => "WANT" }]
    })

    picks = GroupPicks::Fetcher.new(
      host_user_ids: [1], extra_game_ids: [30], player_user_ids: [1]
    ).call

    assert_equal 1, picks.size
    assert_equal [], picks[0][:owned_by_host_ids]
    assert_equal true, picks[0][:is_extra]
  end

  test "drops picks whose game metadata is missing" do
    RecommenderService.stubs(:get_group_picks).returns([{ "id" => 10, "score" => 8.0 }])
    GameDiscoveryService.stubs(:get_games_by_ids).returns([])
    UserService.stubs(:get_user_collection).returns({ "games" => [] })

    picks = GroupPicks::Fetcher.new(
      host_user_ids: [1], extra_game_ids: [], player_user_ids: [1]
    ).call

    assert_equal [], picks
  end
end
