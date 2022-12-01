defmodule Stripe.RetriesTest do
  use Stripe.Case

  import Mox

  setup do
    stub(TestClient, :init, fn -> :ok end)

    client =
      Stripe.new(
        api_key: "sk_test_123",
        http_client: TestClient,
        base_backoff: 0,
        max_backoff: 100
      )

    %{client: client}
  end

  setup :verify_on_exit!

  describe "retries" do
    test "retries request with `stripe-should-retry` true", %{client: client} do
      expect(TestClient, :request, 3, fn _method, _url, _headers, _body, _opts ->
        send_numbered_request!()

        {:ok,
         %{
           status: 200,
           body: ~s|{ "object":"subscription" }|,
           headers: [{"stripe-should-retry", "true"}]
         }}
      end)

      assert {:ok, %Stripe.Subscription{}} =
               Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

      assert_receive {:request, 1}
      assert_receive {:request, 2}
      assert_receive {:request, 3}
    end

    test "does not retry request with `stripe-should-retry` false", %{client: client} do
      expect(TestClient, :request, 1, fn _method, _url, _headers, _body, _opts ->
        send_numbered_request!()

        {:ok,
         %{
           status: 200,
           body: ~s|{ "object":"subscription" }|,
           headers: [{"stripe-should-retry", "false"}]
         }}
      end)

      assert {:ok, %Stripe.Subscription{}} =
               Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

      assert_receive {:request, 1}
    end

    test "retries request with status 429", %{client: client} do
      expect(TestClient, :request, 3, fn _method, _url, _headers, _body, _opts ->
        send_numbered_request!()

        {:ok,
         %{
           status: 429,
           body: ~s|{ "error": {"type":"api_error", "code": "rate_limit"} }|,
           headers: []
         }}
      end)

      assert {:error, %Stripe.ApiErrors{code: "rate_limit", type: "api_error"}} =
               Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

      assert_receive {:request, 1}
      assert_receive {:request, 2}
      assert_receive {:request, 3}
    end

    test "retries request with lock_timeout code", %{client: client} do
      expect(TestClient, :request, 3, fn _method, _url, _headers, _body, _opts ->
        send_numbered_request!()

        {:ok,
         %{
           status: 429,
           body: ~s|{ "error": {"type":"api_error", "code": "lock_timeout"} }|,
           headers: []
         }}
      end)

      assert {:error, %Stripe.ApiErrors{code: "lock_timeout", type: "api_error"}} =
               Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

      assert_receive {:request, 1}
      assert_receive {:request, 2}
      assert_receive {:request, 3}
    end

    test "retries request with network failure", %{client: client} do
      expect(TestClient, :request, 3, fn _method, _url, _headers, _body, _opts ->
        send_numbered_request!()

        {
          :error,
          {:failed_connect,
           [{:to_address, {'localhost', 12345}}, {:inet, [:inet], :econnrefused}]}
        }
      end)

      assert {
               :error,
               {:failed_connect,
                [{:to_address, {'localhost', 12345}}, {:inet, [:inet], :econnrefused}]}
             } = Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

      assert_receive {:request, 1}
      assert_receive {:request, 2}
      assert_receive {:request, 3}
    end
  end

  test "retries request max_network_retries times" do
    client =
      Stripe.new(
        api_key: "sk_test_123",
        http_client: TestClient,
        max_network_retries: 10,
        base_backoff: 0,
        max_backoff: 10
      )

    expect(TestClient, :request, 10, fn _method, _url, _headers, _body, _opts ->
      send_numbered_request!()

      {:ok,
       %{
         status: 200,
         body: ~s|{ "object":"subscription" }|,
         headers: [{"stripe-should-retry", "true"}]
       }}
    end)

    assert {:ok, %Stripe.Subscription{}} =
             Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})
  end

  defp send_numbered_request! do
    n = Process.get(:n, 0) + 1
    Process.put(:n, n)
    send(self(), {:request, n})
  end
end
