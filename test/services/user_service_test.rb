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
end