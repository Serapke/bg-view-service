require "test_helper"

class Api::V1::Views::ViewsControllerTest < ActionDispatch::IntegrationTest
  test "user_collections returns unauthorized when X-User-ID header is missing" do
    get api_v1_views_collections_path

    assert_response :unauthorized
    assert_equal "X-User-ID header is required", JSON.parse(response.body)["error"]
  end

  test "user_collections returns enriched collection with valid user_id" do
    user_id = "user123"

    # Stub UserService response
    user_collection = {
      "games" => [
        {
          "gameId" => 1,
          "notes" => "Great game!",
          "labels" => ["favorite"],
          "modifiedAt" => "2025-01-15T10:00:00Z"
        },
        {
          "gameId" => 2,
          "notes" => "Fun with friends",
          "labels" => [],
          "modifiedAt" => "2025-01-16T11:00:00Z"
        }
      ]
    }

    # Stub GameDiscoveryService response
    games = [
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

    UserService.stubs(:get_user_collection).returns(user_collection)
    GameDiscoveryService.stubs(:get_games_by_ids).returns(games)

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :success

    json_response = JSON.parse(response.body)

    assert_equal user_id, json_response["user_id"]
    assert_equal 2, json_response["total_games"]
    assert_equal 2, json_response["collection"].size

    # Check first game
    first_game = json_response["collection"][0]
    assert_equal 1, first_game["id"]
    assert_equal "Catan", first_game["name"]
    assert_equal 7.5, first_game["rating"]
    assert_equal "Great game!", first_game["notes"]
    assert_equal ["favorite"], first_game["labels"]
    assert_equal "2025-01-15T10:00:00Z", first_game["modified_at"]

    # Check second game
    second_game = json_response["collection"][1]
    assert_equal 2, second_game["id"]
    assert_equal "Ticket to Ride", second_game["name"]
    assert_equal 8.0, second_game["rating"]
    assert_equal "Fun with friends", second_game["notes"]
    assert_equal [], second_game["labels"]
    assert_equal "2025-01-16T11:00:00Z", second_game["modified_at"]
  end

  test "user_collections handles empty collection" do
    user_id = "user123"

    # Stub UserService response with empty games
    user_collection = {
      "games" => []
    }

    UserService.stubs(:get_user_collection).returns(user_collection)

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :success

    json_response = JSON.parse(response.body)

    assert_equal user_id, json_response["user_id"]
    assert_equal 0, json_response["total_games"]
    assert_equal [], json_response["collection"]
  end

  test "user_collections handles missing games key in user collection" do
    user_id = "user123"

    # Stub UserService response without games key
    user_collection = {}

    UserService.stubs(:get_user_collection).returns(user_collection)

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :success

    json_response = JSON.parse(response.body)

    assert_equal user_id, json_response["user_id"]
    assert_equal 0, json_response["total_games"]
    assert_equal [], json_response["collection"]
  end

  test "user_collections handles UserService error" do
    user_id = "user123"

    UserService.stubs(:get_user_collection).raises(StandardError.new("Service unavailable"))

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :internal_server_error
    assert_equal "Failed to fetch user collection", JSON.parse(response.body)["error"]
  end

  test "user_collections handles GameDiscoveryService error" do
    user_id = "user123"

    user_collection = {
      "games" => [
        {
          "gameId" => 1,
          "notes" => "Great game!",
          "labels" => ["favorite"],
          "modifiedAt" => "2025-01-15T10:00:00Z"
        }
      ]
    }

    UserService.stubs(:get_user_collection).returns(user_collection)
    GameDiscoveryService.stubs(:get_games_by_ids).raises(StandardError.new("Service unavailable"))

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :internal_server_error
    assert_equal "Failed to fetch user collection", JSON.parse(response.body)["error"]
  end

  test "user_collections handles collection items with missing labels" do
    user_id = "user123"

    user_collection = {
      "games" => [
        {
          "gameId" => 1,
          "notes" => "Great game!",
          "modifiedAt" => "2025-01-15T10:00:00Z"
          # labels key is missing
        }
      ]
    }

    games = [
      {
        "id" => 1,
        "name" => "Catan",
        "rating" => 7.5
      }
    ]

    UserService.stubs(:get_user_collection).returns(user_collection)
    GameDiscoveryService.stubs(:get_games_by_ids).returns(games)

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :success

    json_response = JSON.parse(response.body)
    first_game = json_response["collection"][0]

    assert_equal [], first_game["labels"]
  end

  test "user_collections handles game not found in discovery service" do
    user_id = "user123"

    user_collection = {
      "games" => [
        {
          "gameId" => 999,
          "notes" => "Missing game",
          "labels" => [],
          "modifiedAt" => "2025-01-15T10:00:00Z"
        }
      ]
    }

    UserService.stubs(:get_user_collection).returns(user_collection)
    # GameDiscoveryService returns empty array (game not found)
    GameDiscoveryService.stubs(:get_games_by_ids).returns([])

    get api_v1_views_collections_path, headers: { "X-User-ID" => user_id }

    assert_response :success

    json_response = JSON.parse(response.body)

    # Games without details from discovery service are filtered out
    assert_equal 0, json_response["collection"].size
    assert_equal 0, json_response["total_games"]
  end
end