require "test_helper"

class GameDiscoveryServiceTest < ActiveSupport::TestCase
  setup do
    @base_url = ENV.fetch('GAME_DISCOVERY_SERVICE_URL', 'http://localhost:3002')
  end

  test "get_games_by_ids returns parsed board_games array on success" do
    game_ids = [1, 2]
    games_data = {
      "board_games" => [
        {
          "id" => 1,
          "name" => "Catan",
          "rating" => 7.5
        },
        {
          "id" => 2,
          "name" => "Ticket to Ride",
          "rating" => 8.0
        }
      ]
    }

    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1,2")
      .to_return(
        status: 200,
        body: games_data.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = GameDiscoveryService.get_games_by_ids(game_ids)

    assert_equal games_data["board_games"], result
  end

  test "get_games_by_ids returns empty array when given empty array" do
    result = GameDiscoveryService.get_games_by_ids([])

    assert_equal [], result
  end

  test "get_games_by_ids formats IDs as comma-separated string" do
    game_ids = [1, 2, 3]

    stub = stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1,2,3")
      .to_return(
        status: 200,
        body: { "board_games" => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    GameDiscoveryService.get_games_by_ids(game_ids)

    assert_requested stub
  end

  test "get_games_by_ids handles single game ID" do
    game_ids = [42]

    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=42")
      .to_return(
        status: 200,
        body: {
          "board_games" => [
            { "id" => 42, "name" => "Test Game", "rating" => 9.0 }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = GameDiscoveryService.get_games_by_ids(game_ids)

    assert_equal 1, result.length
    assert_equal 42, result[0]["id"]
    assert_equal "Test Game", result[0]["name"]
  end

  test "get_games_by_ids raises error on 404" do
    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1")
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(StandardError) do
      GameDiscoveryService.get_games_by_ids([1])
    end

    assert_match(/Failed to fetch games: 404/, error.message)
  end

  test "get_games_by_ids raises error on 500" do
    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(StandardError) do
      GameDiscoveryService.get_games_by_ids([1])
    end

    assert_match(/Failed to fetch games: 500/, error.message)
  end

  test "get_games_by_ids raises error on invalid JSON" do
    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1")
      .to_return(
        status: 200,
        body: "not valid json",
        headers: { 'Content-Type' => 'application/json' }
      )

    error = assert_raises(StandardError) do
      GameDiscoveryService.get_games_by_ids([1])
    end

    assert_equal "Invalid response format from game discovery service", error.message
  end

  test "get_games_by_ids handles empty board_games array" do
    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=999")
      .to_return(
        status: 200,
        body: { "board_games" => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = GameDiscoveryService.get_games_by_ids([999])

    assert_equal [], result
  end

  test "get_games_by_ids handles missing board_games key" do
    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1")
      .to_return(
        status: 200,
        body: {}.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = GameDiscoveryService.get_games_by_ids([1])

    assert_nil result
  end

  test "get_games_by_ids handles connection errors" do
    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=1")
      .to_timeout

    assert_raises(StandardError) do
      GameDiscoveryService.get_games_by_ids([1])
    end
  end

  test "get_games_by_ids handles large number of IDs" do
    game_ids = (1..100).to_a
    ids_param = game_ids.join(',')

    stub_request(:get, "#{@base_url}/api/v1/board_games?ids=#{ids_param}")
      .to_return(
        status: 200,
        body: { "board_games" => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = GameDiscoveryService.get_games_by_ids(game_ids)

    assert_equal [], result
  end
end