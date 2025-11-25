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
          "labels" => [{ "id" => 1, "name" => "favorite" }],
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
    assert_equal 1, first_game["labels"].size
    assert_equal "favorite", first_game["labels"][0]["name"]
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
          "labels" => [{ "id" => 1, "name" => "favorite" }],
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

  # Tests for add_game endpoint

  test "add_game returns unauthorized when X-User-ID header is missing" do
    post api_v1_views_collections_games_path, params: { game_id: 1 }

    assert_response :unauthorized
    assert_equal "X-User-ID header is required", JSON.parse(response.body)["error"]
  end

  test "add_game successfully adds game to collection" do
    user_id = "user123"
    game_id = 1

    game = {
      "id" => 1,
      "name" => "Catan",
      "rating" => 7.5
    }

    collection_item = {
      "id" => 10,
      "gameId" => 1,
      "notes" => "Wishlist item",
      "modifiedAt" => "2025-01-20T14:30:00Z",
      "labels" => [
        { "id" => 1, "name" => "Strategy" },
        { "id" => 2, "name" => "Wishlist" }
      ]
    }

    GameDiscoveryService.stubs(:get_game_by_id).with("1").returns(game)
    UserService.stubs(:add_game_to_collection).returns(collection_item)

    post api_v1_views_collections_games_path,
         params: { game_id: game_id, notes: "Wishlist item", label_names: ["Strategy", "Wishlist"] },
         headers: { "X-User-ID" => user_id }

    assert_response :created

    json_response = JSON.parse(response.body)

    assert_equal 1, json_response["id"]
    assert_equal "Catan", json_response["name"]
    assert_equal 7.5, json_response["rating"]
    assert_equal "Wishlist item", json_response["notes"]
    assert_equal 2, json_response["labels"].size
    assert_equal "Strategy", json_response["labels"][0]["name"]
    assert_equal "Wishlist", json_response["labels"][1]["name"]
    assert_equal "2025-01-20T14:30:00Z", json_response["modified_at"]
  end

  test "add_game returns not found when game does not exist" do
    user_id = "user123"
    game_id = 999

    GameDiscoveryService.stubs(:get_game_by_id).with("999").returns(nil)

    post api_v1_views_collections_games_path,
         params: { game_id: game_id },
         headers: { "X-User-ID" => user_id }

    assert_response :not_found
    assert_equal "Game with ID 999 not found", JSON.parse(response.body)["error"]
  end

  test "add_game handles UserService error" do
    user_id = "user123"
    game_id = 1

    game = { "id" => 1, "name" => "Catan", "rating" => 7.5 }

    GameDiscoveryService.stubs(:get_game_by_id).with("1").returns(game)
    UserService.stubs(:add_game_to_collection).raises(StandardError.new("Service unavailable"))

    post api_v1_views_collections_games_path,
         params: { game_id: game_id },
         headers: { "X-User-ID" => user_id }

    assert_response :internal_server_error
    assert_equal "Failed to add game to collection", JSON.parse(response.body)["error"]
  end

  test "add_game handles missing label_names parameter" do
    user_id = "user123"
    game_id = 1

    game = { "id" => 1, "name" => "Catan", "rating" => 7.5 }

    collection_item = {
      "id" => 10,
      "gameId" => 1,
      "notes" => "Great game",
      "modifiedAt" => "2025-01-20T14:30:00Z",
      "labels" => []
    }

    GameDiscoveryService.stubs(:get_game_by_id).with("1").returns(game)
    UserService.stubs(:add_game_to_collection).returns(collection_item)

    post api_v1_views_collections_games_path,
         params: { game_id: game_id, notes: "Great game" },
         headers: { "X-User-ID" => user_id }

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal [], json_response["labels"]
  end

  # Tests for remove_game endpoint

  test "remove_game returns unauthorized when X-User-ID header is missing" do
    delete "/api/v1/views/collections/games/1"

    assert_response :unauthorized
    assert_equal "X-User-ID header is required", JSON.parse(response.body)["error"]
  end

  test "remove_game successfully removes game from collection" do
    user_id = "user123"
    game_id = 1

    remover = mock('remover')
    remover.expects(:call).returns(true)
    UserCollections::Remover.expects(:new).with(user_id, game_id: "1").returns(remover)

    delete "/api/v1/views/collections/games/#{game_id}",
           headers: { "X-User-ID" => user_id }

    assert_response :ok

    json_response = JSON.parse(response.body)
    assert_equal "Game removed from collection successfully", json_response["message"]
  end

  test "remove_game handles removal errors" do
    user_id = "user123"
    game_id = 1

    remover = mock('remover')
    remover.expects(:call).raises(StandardError.new("Service unavailable"))
    UserCollections::Remover.expects(:new).with(user_id, game_id: "1").returns(remover)

    delete "/api/v1/views/collections/games/#{game_id}",
           headers: { "X-User-ID" => user_id }

    assert_response :internal_server_error
    assert_equal "Failed to remove game from collection", JSON.parse(response.body)["error"]
  end
end