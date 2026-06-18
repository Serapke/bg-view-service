require "test_helper"

class GameReviews::RemoverTest < ActiveSupport::TestCase
  test "deletes existing review for given game" do
    user_id = "user123"
    game_id = 42

    reviews = [
      { "id" => 100, "gameId" => 42, "rating" => 8 },
      { "id" => 101, "gameId" => 7, "rating" => 5 }
    ]

    UserService.stubs(:get_user_reviews).with(user_id).returns(reviews)
    UserService.expects(:delete_review).with(user_id, review_id: 100).returns(true)

    result = GameReviews::Remover.new(user_id, game_id: game_id).call

    assert_equal true, result
  end

  test "is a no-op when no review exists for the game" do
    user_id = "user123"
    game_id = 999

    UserService.stubs(:get_user_reviews).with(user_id).returns([])
    UserService.expects(:delete_review).never

    result = GameReviews::Remover.new(user_id, game_id: game_id).call

    assert_equal false, result
  end

  test "coerces game_id to integer when matching" do
    user_id = "user123"
    reviews = [{ "id" => 100, "gameId" => 42, "rating" => 8 }]

    UserService.stubs(:get_user_reviews).with(user_id).returns(reviews)
    UserService.expects(:delete_review).with(user_id, review_id: 100).returns(true)

    GameReviews::Remover.new(user_id, game_id: "42").call
  end

  test "propagates UserService errors" do
    user_id = "user123"
    reviews = [{ "id" => 100, "gameId" => 42, "rating" => 8 }]

    UserService.stubs(:get_user_reviews).with(user_id).returns(reviews)
    UserService.stubs(:delete_review).raises(UserService::ClientError.new("Forbidden"))

    error = assert_raises(UserService::ClientError) do
      GameReviews::Remover.new(user_id, game_id: 42).call
    end

    assert_equal "Forbidden", error.message
  end
end
