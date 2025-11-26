require "test_helper"

class GameReviews::SerializerTest < ActiveSupport::TestCase
  test "serializes review data" do
    review = {
      "id" => 100,
      "gameId" => 1,
      "rating" => 8.5,
      "reviewText" => "Amazing game with great mechanics!",
      "createdAt" => "2025-01-22T10:00:00Z"
    }

    result = GameReviews::Serializer.serialize(review)

    assert_equal 100, result[:id]
    assert_equal 1, result[:game_id]
    assert_equal 8.5, result[:rating]
    assert_equal "Amazing game with great mechanics!", result[:review_text]
    assert_equal "2025-01-22T10:00:00Z", result[:created_at]
  end

  test "serializes review with different game_id" do
    review = {
      "id" => 200,
      "gameId" => 42,
      "rating" => 9.0,
      "reviewText" => "Excellent!",
      "createdAt" => "2025-01-22T11:00:00Z"
    }

    result = GameReviews::Serializer.serialize(review)

    assert_equal 200, result[:id]
    assert_equal 42, result[:game_id]
    assert_equal 9.0, result[:rating]
    assert_equal "Excellent!", result[:review_text]
    assert_equal "2025-01-22T11:00:00Z", result[:created_at]
  end

  test "serializes all review fields correctly" do
    review = {
      "id" => 300,
      "gameId" => 5,
      "rating" => 7.0,
      "reviewText" => "Good game, worth playing",
      "createdAt" => "2025-01-22T12:00:00Z"
    }

    result = GameReviews::Serializer.serialize(review)

    assert_equal 300, result[:id]
    assert_equal 5, result[:game_id]
    assert_equal 7.0, result[:rating]
    assert_equal "Good game, worth playing", result[:review_text]
    assert_equal "2025-01-22T12:00:00Z", result[:created_at]
  end
end
