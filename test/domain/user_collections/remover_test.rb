require "test_helper"

class UserCollections::RemoverTest < ActiveSupport::TestCase
  test "successfully removes game from collection" do
    user_id = "user123"
    game_id = 1

    UserService.stubs(:remove_game_from_collection)
      .with(user_id, game_id: game_id)
      .returns(true)

    remover = UserCollections::Remover.new(user_id, game_id: game_id)
    result = remover.call

    assert_equal true, result
  end

  test "calls UserService with correct parameters" do
    user_id = "user456"
    game_id = 42

    UserService.expects(:remove_game_from_collection)
      .with(user_id, game_id: game_id)
      .returns(true)

    remover = UserCollections::Remover.new(user_id, game_id: game_id)
    remover.call
  end

  test "propagates UserService errors" do
    user_id = "user123"
    game_id = 1

    UserService.stubs(:remove_game_from_collection)
      .raises(StandardError.new("Service unavailable"))

    remover = UserCollections::Remover.new(user_id, game_id: game_id)

    error = assert_raises(StandardError) do
      remover.call
    end

    assert_equal "Service unavailable", error.message
  end

  test "handles game not found in user collection" do
    user_id = "user123"
    game_id = 999

    UserService.stubs(:remove_game_from_collection)
      .raises(StandardError.new("Failed to remove game from collection: 404 - Not Found"))

    remover = UserCollections::Remover.new(user_id, game_id: game_id)

    error = assert_raises(StandardError) do
      remover.call
    end

    assert_match(/404 - Not Found/, error.message)
  end
end
