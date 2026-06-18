require "test_helper"

class EventServiceTest < ActiveSupport::TestCase
  setup do
    @base_url = ENV.fetch('EVENT_SERVICE_URL', 'http://localhost:3005')
    @user_id = "42"
  end

  test "create_event posts payload and returns parsed body on 201" do
    payload = { "id" => 7, "creatorId" => 42, "title" => "Catan", "participantIds" => [1, 2], "createdAt" => "2026-06-18T00:00:00Z" }

    stub = stub_request(:post, "#{@base_url}/api/v1/events")
      .with(
        headers: { 'X-User-ID' => @user_id },
        body: { userIds: [1, 2], title: "Catan" }.to_json
      )
      .to_return(status: 201, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })

    result = EventService.create_event(@user_id, user_ids: [1, 2], title: "Catan")
    assert_equal payload, result
    assert_requested stub
  end

  test "create_event raises ClientError on 4xx" do
    stub_request(:post, "#{@base_url}/api/v1/events")
      .to_return(status: 422, body: { error: "userIds must be a non-empty array" }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    error = assert_raises(EventService::ClientError) do
      EventService.create_event(@user_id, user_ids: [], title: nil)
    end
    assert_match(/userIds/, error.message)
  end

  test "create_event raises StandardError on 5xx" do
    stub_request(:post, "#{@base_url}/api/v1/events").to_return(status: 500, body: "boom")

    assert_raises(StandardError) do
      EventService.create_event(@user_id, user_ids: [1], title: nil)
    end
  end

  test "get_event returns parsed JSON on 200" do
    payload = { "id" => 9, "creatorId" => 42, "title" => nil, "participantIds" => [1, 2, 3], "createdAt" => "2026-06-18T00:00:00Z" }
    stub_request(:get, "#{@base_url}/api/v1/events/9")
      .with(headers: { 'X-User-ID' => @user_id })
      .to_return(status: 200, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })

    assert_equal payload, EventService.get_event(@user_id, event_id: 9)
  end

  test "get_event raises NotFoundError on 404" do
    stub_request(:get, "#{@base_url}/api/v1/events/123")
      .to_return(status: 404, body: { error: "Event not found" }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    assert_raises(EventService::NotFoundError) do
      EventService.get_event(@user_id, event_id: 123)
    end
  end
end
