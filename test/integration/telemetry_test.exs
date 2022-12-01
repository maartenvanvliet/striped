defmodule Stripe.TelemetryTest do
  use Stripe.Case, async: false

  import Mox

  setup do
    stub(TestClient, :init, fn -> :ok end)

    client =
      Stripe.new(
        api_key: "sk_test_123",
        http_client: TestClient,
        base_backoff: 0
      )

    %{client: client}
  end

  defmodule RaisingClient do
    def init() do
      :ok
    end

    def request(:get, _, _, _, _) do
      raise "error"
    end
  end

  setup :verify_on_exit!

  describe "telemetry" do
    test "sends correct events", %{client: client} do
      attach_telemetry()

      expect(TestClient, :request, 3, fn _method, _url, _headers, _body, _opts ->
        {:ok,
         %{
           status: 429,
           body: ~s|{ "error": {"type":"api_error", "code": "rate_limit"} }|,
           headers: []
         }}
      end)

      assert {:error, %Stripe.ApiErrors{code: "rate_limit", type: "api_error"}} =
               Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

      assert_receive {[:stripe, :request, :start], _,
                      %{
                        attempt: 1,
                        method: :get,
                        url:
                          "https://api.stripe.com/v1/subscriptions/sub123?expand%5B0%5D=customer"
                      }}

      assert_receive {[:stripe, :request, :stop], _,
                      %{error: %Stripe.ApiErrors{code: "rate_limit"}, status: 429}}
    end

    test "sends exception event", %{client: client} do
      client = %{client | http_client: RaisingClient}
      attach_telemetry()

      assert_raise RuntimeError, fn ->
        {:error, %Stripe.ApiErrors{code: "rate_limit", type: "api_error"}} =
          Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})
      end

      assert_receive {[:stripe, :request, :exception], _,
                      %{
                        reason: _reason,
                        stacktrace: _trace,
                        attempt: 1,
                        method: :get,
                        url:
                          "https://api.stripe.com/v1/subscriptions/sub123?expand%5B0%5D=customer"
                      }}
    end
  end

  defp attach_telemetry() do
    name = "stripe_test"
    test_pid = self()

    :ok =
      :telemetry.attach_many(
        name,
        [
          [:stripe, :request, :start],
          [:stripe, :request, :stop],
          [:stripe, :request, :exception]
        ],
        &Stripe.TelemetryTest.send_telemetry/4,
        %{test_pid: test_pid}
      )

    ExUnit.Callbacks.on_exit(fn ->
      :telemetry.detach(name)
    end)
  end

  def send_telemetry(path, args, metadata, %{test_pid: pid}) do
    send(pid, {path, args, metadata})
  end
end
