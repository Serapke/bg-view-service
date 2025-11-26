require "test_helper"

class GameReviews::CreatorTest < ActiveSupport::TestCase
  test "successfully creates review with all parameters" do
    user_id = "user123"
    game_id = 1
    rating = 8.5
    review_text = "Amazing game with great mechanics!"

    game = {
      "id" => 1,
      "name" => "Catan",
      "rating" => 7.5
    }

    review = {
      "id" => 100,
      "gameId" => 1,
      "rating" => rating,
      "reviewText" => review_text,
      "createdAt" => "2025-01-22T10:00:00Z"
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:create_review)
      .with(user_id, game_id: game_id, rating: rating, review_text: review_text)
      .returns(review)

    creator = GameReviews::Creator.new(user_id, game_id: game_id, rating: rating, review_text: review_text)
    result = creator.call

    assert_equal review, result[:review]
    assert_equal game, result[:game]
  end

  test "raises GameNotFoundError when game does not exist" do
    user_id = "user123"
    game_id = 999
    rating = 8.0
    review_text = "Test review"

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(nil)

    creator = GameReviews::Creator.new(user_id, game_id: game_id, rating: rating, review_text: review_text)

    error = assert_raises(GameReviews::GameNotFoundError) do
      creator.call
    end

    assert_equal "Game with ID 999 not found", error.message
  end

  test "does not call UserService when game is not found" do
    user_id = "user123"
    game_id = 999
    rating = 8.0
    review_text = "Test review"

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(nil)
    UserService.expects(:create_review).never

    creator = GameReviews::Creator.new(user_id, game_id: game_id, rating: rating, review_text: review_text)

    assert_raises(GameReviews::GameNotFoundError) do
      creator.call
    end
  end

  test "propagates UserService errors" do
    user_id = "user123"
    game_id = 1
    rating = 8.0
    review_text = "Test review"

    game = {
      "id" => 1,
      "name" => "Catan",
      "rating" => 7.5
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.stubs(:create_review).raises(StandardError.new("Service unavailable"))

    creator = GameReviews::Creator.new(user_id, game_id: game_id, rating: rating, review_text: review_text)

    error = assert_raises(StandardError) do
      creator.call
    end

    assert_equal "Service unavailable", error.message
  end

  test "propagates GameDiscoveryService errors" do
    user_id = "user123"
    game_id = 1
    rating = 8.0
    review_text = "Test review"

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).raises(StandardError.new("Discovery service down"))

    creator = GameReviews::Creator.new(user_id, game_id: game_id, rating: rating, review_text: review_text)

    error = assert_raises(StandardError) do
      creator.call
    end

    assert_equal "Discovery service down", error.message
  end

  test "calls UserService with correct parameters" do
    user_id = "user456"
    game_id = 42
    rating = 9.5
    review_text = "Perfect game!"

    game = {
      "id" => 42,
      "name" => "Azul",
      "rating" => 7.8
    }

    review = {
      "id" => 200,
      "gameId" => 42,
      "rating" => rating,
      "reviewText" => review_text,
      "createdAt" => "2025-01-22T12:00:00Z"
    }

    GameDiscoveryService.stubs(:get_game_by_id).with(game_id).returns(game)
    UserService.expects(:create_review)
      .with(user_id, game_id: game_id, rating: rating, review_text: review_text)
      .returns(review)

    creator = GameReviews::Creator.new(user_id, game_id: game_id, rating: rating, review_text: review_text)
    creator.call
  end
end
