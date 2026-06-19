require "test_helper"

class Api::V1::Views::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_id = "42"
    @event_base = ENV.fetch('EVENT_SERVICE_URL', 'http://localhost:3005')
  end

  test "create_event returns 401 without X-User-ID" do
    post api_v1_views_events_path, params: { userIds: [1] }, as: :json
    assert_response :unauthorized
  end

  test "create_event returns 400 when userIds missing" do
    post api_v1_views_events_path,
      params: { title: "x" }, as: :json,
      headers: { "X-User-ID" => @user_id }
    assert_response :bad_request
  end

  test "create_event delegates to event-service and serializes response" do
    upstream = { "id" => 11, "creatorId" => 42, "title" => "Catan", "participantIds" => [1, 2], "createdAt" => "2026-06-18T00:00:00Z" }
    stub_request(:post, "#{@event_base}/api/v1/events")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 201, body: upstream.to_json, headers: { 'Content-Type' => 'application/json' })

    post api_v1_views_events_path,
      params: { userIds: [1, 2], title: "Catan" }, as: :json,
      headers: { "X-User-ID" => @user_id }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 11, body["id"]
    assert_equal 42, body["creator_id"]
    assert_equal [1, 2], body["participant_ids"]
    assert_equal "Catan", body["title"]
  end

  test "get_event returns 401 without X-User-ID" do
    get "/api/v1/views/events/1"
    assert_response :unauthorized
  end

  test "get_event returns serialized event" do
    upstream = { "id" => 11, "creatorId" => 42, "title" => nil, "participantIds" => [1, 2], "createdAt" => "2026-06-18T00:00:00Z" }
    stub_request(:get, "#{@event_base}/api/v1/events/11")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 200, body: upstream.to_json, headers: { 'Content-Type' => 'application/json' })

    get "/api/v1/views/events/11", headers: { "X-User-ID" => @user_id }
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 11, body["id"]
    assert_equal [1, 2], body["participant_ids"]
  end

  test "get_event returns 404 when event-service returns 404" do
    stub_request(:get, "#{@event_base}/api/v1/events/9999")
      .to_return(status: 404, body: { error: "Event not found" }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    get "/api/v1/views/events/9999", headers: { "X-User-ID" => @user_id }
    assert_response :not_found
  end

  test "user_events returns 401 without X-User-ID" do
    get "/api/v1/views/events"
    assert_response :unauthorized
  end

  test "user_events returns serialized list" do
    upstream = {
      "events" => [
        { "id" => 1, "creatorId" => 42, "title" => "Catan", "participantIds" => [42, 7], "createdAt" => "2026-06-18T00:00:00Z" },
        { "id" => 2, "creatorId" => 7,  "title" => nil,     "participantIds" => [7, 42], "createdAt" => "2026-06-17T00:00:00Z" }
      ]
    }
    stub_request(:get, "#{@event_base}/api/v1/events")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 200, body: upstream.to_json, headers: { 'Content-Type' => 'application/json' })

    get "/api/v1/views/events", headers: { "X-User-ID" => @user_id }
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 2, body["events"].length
    assert_equal [1, 2], body["events"].map { |e| e["id"] }
    assert_equal 42, body["events"][0]["creator_id"]
    assert_equal [42, 7], body["events"][0]["participant_ids"]
  end
end
