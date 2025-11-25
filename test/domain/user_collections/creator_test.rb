require "test_helper"

class UserCollections::CreatorTest < ActiveSupport::TestCase
  test "successfully creates collection item with all parameters" do
    user_id = "user123"
    game_id = 1
    notes = "Great strategy game!"
    label_names = ["Strategy", "Wishlist"]

    game = {
      "id" => 1,
      "name" => "Catan",
      "rating" => 7.5
    }

    collection_item = {
      "id" => 10,
      "gameId" => 1,
      "notes" => notes,
      "modifiedAt" => "2025-01-20T14:30:00Z",
      "labels" => [
        { "id" => 1, "name" => "Strategy" },
        { "id" => 2, "name" => "Wishlist" }
      ]
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:add_game_to_collection)
      .with(user_id, game_id: game_id, notes: notes, label_names: label_names)
      .returns(collection_item)

    creator = UserCollections::Creator.new(user_id, game_id: game_id, notes: notes, label_names: label_names)
    result = creator.call

    assert_equal collection_item, result[:collection_item]
    assert_equal game, result[:game]
  end

  test "successfully creates collection item with minimal parameters" do
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
      "notes" => nil,
      "modifiedAt" => "2025-01-20T14:30:00Z",
      "labels" => []
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:add_game_to_collection)
      .with(user_id, game_id: game_id, notes: nil, label_names: [])
      .returns(collection_item)

    creator = UserCollections::Creator.new(user_id, game_id: game_id)
    result = creator.call

    assert_equal collection_item, result[:collection_item]
    assert_equal game, result[:game]
  end

  test "successfully creates collection item with notes but no labels" do
    user_id = "user123"
    game_id = 1
    notes = "Fun party game"

    game = {
      "id" => 1,
      "name" => "Codenames",
      "rating" => 8.0
    }

    collection_item = {
      "id" => 11,
      "gameId" => 1,
      "notes" => notes,
      "modifiedAt" => "2025-01-20T15:00:00Z",
      "labels" => []
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:add_game_to_collection)
      .with(user_id, game_id: game_id, notes: notes, label_names: [])
      .returns(collection_item)

    creator = UserCollections::Creator.new(user_id, game_id: game_id, notes: notes)
    result = creator.call

    assert_equal collection_item, result[:collection_item]
    assert_equal game, result[:game]
  end

  test "raises GameNotFoundError when game does not exist" do
    user_id = "user123"
    game_id = 999

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(nil)

    creator = UserCollections::Creator.new(user_id, game_id: game_id)

    error = assert_raises(UserCollections::GameNotFoundError) do
      creator.call
    end

    assert_equal "Game with ID 999 not found", error.message
  end

  test "does not call UserService when game is not found" do
    user_id = "user123"
    game_id = 999

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(nil)
    UserService.expects(:add_game_to_collection).never

    creator = UserCollections::Creator.new(user_id, game_id: game_id)

    assert_raises(UserCollections::GameNotFoundError) do
      creator.call
    end
  end

  test "propagates UserService errors" do
    user_id = "user123"
    game_id = 1

    game = {
      "id" => 1,
      "name" => "Catan",
      "rating" => 7.5
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:add_game_to_collection).raises(StandardError.new("Service unavailable"))

    creator = UserCollections::Creator.new(user_id, game_id: game_id)

    error = assert_raises(StandardError) do
      creator.call
    end

    assert_equal "Service unavailable", error.message
  end

  test "propagates GameDiscoveryService errors" do
    user_id = "user123"
    game_id = 1

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).raises(StandardError.new("Discovery service down"))

    creator = UserCollections::Creator.new(user_id, game_id: game_id)

    error = assert_raises(StandardError) do
      creator.call
    end

    assert_equal "Discovery service down", error.message
  end

  test "creates collection item with single label" do
    user_id = "user123"
    game_id = 2
    label_names = ["Favorite"]

    game = {
      "id" => 2,
      "name" => "Azul",
      "rating" => 7.8
    }

    collection_item = {
      "id" => 12,
      "gameId" => 2,
      "notes" => nil,
      "modifiedAt" => "2025-01-20T16:00:00Z",
      "labels" => [{ "id" => 3, "name" => "Favorite" }]
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:add_game_to_collection)
      .with(user_id, game_id: game_id, notes: nil, label_names: label_names)
      .returns(collection_item)

    creator = UserCollections::Creator.new(user_id, game_id: game_id, label_names: label_names)
    result = creator.call

    assert_equal collection_item, result[:collection_item]
    assert_equal game, result[:game]
  end
end
