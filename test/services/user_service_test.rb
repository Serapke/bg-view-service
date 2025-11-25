require "test_helper"

class UserServiceTest < ActiveSupport::TestCase
  setup do
    @base_url = ENV.fetch('USER_SERVICE_URL', 'http://localhost:8080')
    @user_id = "user123"
  end

  test "get_user_collection returns parsed JSON on success" do
    collection_data = {
      "games" => [
        {
          "gameId" => 1,
          "notes" => "Great game!",
          "labels" => ["favorite"],
          "modifiedAt" => "2025-01-15T10:00:00Z"
        }
      ]
    }

    stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(
        status: 200,
        body: collection_data.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = UserService.get_user_collection(@user_id)

    assert_equal collection_data, result
  end

  test "get_user_collection sends X-User-ID header" do
    stub = stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(
        status: 200,
        body: { "games" => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    UserService.get_user_collection(@user_id)

    assert_requested stub
  end

  test "get_user_collection raises error on 404" do
    stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(StandardError) do
      UserService.get_user_collection(@user_id)
    end

    assert_match(/Failed to fetch user collection: 404/, error.message)
  end

  test "get_user_collection raises error on 500" do
    stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(StandardError) do
      UserService.get_user_collection(@user_id)
    end

    assert_match(/Failed to fetch user collection: 500/, error.message)
  end

  test "get_user_collection raises error on invalid JSON" do
    stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(
        status: 200,
        body: "not valid json",
        headers: { 'Content-Type' => 'application/json' }
      )

    error = assert_raises(StandardError) do
      UserService.get_user_collection(@user_id)
    end

    assert_equal "Invalid response format from user service", error.message
  end

  test "get_user_collection handles empty collection" do
    stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(
        status: 200,
        body: { "games" => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = UserService.get_user_collection(@user_id)

    assert_equal({ "games" => [] }, result)
  end

  test "get_user_collection handles connection errors" do
    stub_request(:get, "#{@base_url}/api/v1/collections")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_timeout

    assert_raises(StandardError) do
      UserService.get_user_collection(@user_id)
    end
  end

  # Tests for add_game_to_collection

  test "add_game_to_collection successfully adds game with all parameters" do
    game_id = 1
    notes = "Great strategy game!"
    label_names = ["Strategy", "Wishlist"]

    request_body = {
      gameId: game_id,
      notes: notes,
      labelNames: label_names
    }

    response_body = {
      "id" => 10,
      "gameId" => game_id,
      "notes" => notes,
      "modifiedAt" => "2025-01-20T14:30:00Z",
      "labels" => [
        { "id" => 1, "name" => "Strategy" },
        { "id" => 2, "name" => "Wishlist" }
      ]
    }

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(
        headers: {
          'X-User-ID' => @user_id,
          'Content-Type' => 'application/json'
        },
        body: request_body
      )
      .to_return(
        status: 201,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = UserService.add_game_to_collection(@user_id, game_id: game_id, notes: notes, label_names: label_names)

    assert_equal response_body, result
  end

  test "add_game_to_collection successfully adds game with minimal parameters" do
    game_id = 1

    request_body = {
      gameId: game_id,
      notes: nil,
      labelNames: []
    }

    response_body = {
      "id" => 10,
      "gameId" => game_id,
      "notes" => nil,
      "modifiedAt" => "2025-01-20T14:30:00Z",
      "labels" => []
    }

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(
        headers: {
          'X-User-ID' => @user_id,
          'Content-Type' => 'application/json'
        },
        body: request_body
      )
      .to_return(
        status: 201,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = UserService.add_game_to_collection(@user_id, game_id: game_id)

    assert_equal response_body, result
  end

  test "add_game_to_collection adds game with notes but no labels" do
    game_id = 2
    notes = "Fun party game"

    request_body = {
      gameId: game_id,
      notes: notes,
      labelNames: []
    }

    response_body = {
      "id" => 11,
      "gameId" => game_id,
      "notes" => notes,
      "modifiedAt" => "2025-01-20T15:00:00Z",
      "labels" => []
    }

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(
        headers: {
          'X-User-ID' => @user_id,
          'Content-Type' => 'application/json'
        },
        body: request_body
      )
      .to_return(
        status: 201,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = UserService.add_game_to_collection(@user_id, game_id: game_id, notes: notes)

    assert_equal response_body, result
  end

  test "add_game_to_collection adds game with labels but no notes" do
    game_id = 3
    label_names = ["Favorite", "Co-op"]

    request_body = {
      gameId: game_id,
      notes: nil,
      labelNames: label_names
    }

    response_body = {
      "id" => 12,
      "gameId" => game_id,
      "notes" => nil,
      "modifiedAt" => "2025-01-20T16:00:00Z",
      "labels" => [
        { "id" => 3, "name" => "Favorite" },
        { "id" => 4, "name" => "Co-op" }
      ]
    }

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(
        headers: {
          'X-User-ID' => @user_id,
          'Content-Type' => 'application/json'
        },
        body: request_body
      )
      .to_return(
        status: 201,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = UserService.add_game_to_collection(@user_id, game_id: game_id, label_names: label_names)

    assert_equal response_body, result
  end

  test "add_game_to_collection sends correct headers" do
    game_id = 1

    stub = stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(
        headers: {
          'X-User-ID' => @user_id,
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 201,
        body: { "id" => 10, "gameId" => game_id }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    UserService.add_game_to_collection(@user_id, game_id: game_id)

    assert_requested stub
  end

  test "add_game_to_collection raises error on 400" do
    game_id = 1

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 400, body: "Bad Request")

    error = assert_raises(StandardError) do
      UserService.add_game_to_collection(@user_id, game_id: game_id)
    end

    assert_match(/Failed to add game to collection: 400/, error.message)
  end

  test "add_game_to_collection raises error on 404" do
    game_id = 999

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(StandardError) do
      UserService.add_game_to_collection(@user_id, game_id: game_id)
    end

    assert_match(/Failed to add game to collection: 404/, error.message)
  end

  test "add_game_to_collection raises error on 500" do
    game_id = 1

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(StandardError) do
      UserService.add_game_to_collection(@user_id, game_id: game_id)
    end

    assert_match(/Failed to add game to collection: 500/, error.message)
  end

  test "add_game_to_collection handles connection errors" do
    game_id = 1

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_timeout

    assert_raises(StandardError) do
      UserService.add_game_to_collection(@user_id, game_id: game_id)
    end
  end

  test "add_game_to_collection handles connection refused" do
    game_id = 1

    stub_request(:post, "#{@base_url}/api/v1/collections/games")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_raise(Faraday::ConnectionFailed)

    assert_raises(StandardError) do
      UserService.add_game_to_collection(@user_id, game_id: game_id)
    end
  end

  # Tests for remove_game_from_collection

  test "remove_game_from_collection successfully removes game" do
    game_id = 1

    stub_request(:delete, "#{@base_url}/api/v1/collections/games/#{game_id}")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 204)

    result = UserService.remove_game_from_collection(@user_id, game_id: game_id)

    assert_equal true, result
  end

  test "remove_game_from_collection sends X-User-ID header" do
    game_id = 1

    stub = stub_request(:delete, "#{@base_url}/api/v1/collections/games/#{game_id}")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 204)

    UserService.remove_game_from_collection(@user_id, game_id: game_id)

    assert_requested stub
  end

  test "remove_game_from_collection raises error on 404" do
    game_id = 999

    stub_request(:delete, "#{@base_url}/api/v1/collections/games/#{game_id}")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(StandardError) do
      UserService.remove_game_from_collection(@user_id, game_id: game_id)
    end

    assert_match(/Failed to remove game from collection: 404/, error.message)
  end

  test "remove_game_from_collection raises error on 500" do
    game_id = 1

    stub_request(:delete, "#{@base_url}/api/v1/collections/games/#{game_id}")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(StandardError) do
      UserService.remove_game_from_collection(@user_id, game_id: game_id)
    end

    assert_match(/Failed to remove game from collection: 500/, error.message)
  end

  test "remove_game_from_collection handles connection errors" do
    game_id = 1

    stub_request(:delete, "#{@base_url}/api/v1/collections/games/#{game_id}")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_timeout

    assert_raises(StandardError) do
      UserService.remove_game_from_collection(@user_id, game_id: game_id)
    end
  end

  test "remove_game_from_collection handles connection refused" do
    game_id = 1

    stub_request(:delete, "#{@base_url}/api/v1/collections/games/#{game_id}")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_raise(Faraday::ConnectionFailed)

    assert_raises(StandardError) do
      UserService.remove_game_from_collection(@user_id, game_id: game_id)
    end
  end
end