defmodule Stripe.ClientTest do
  use Stripe.Case

  defmodule TestClient do
    def init() do
      :ok
    end

    def request(:get, _, _, _, opts) do
      send(self(), opts)

      {:ok,
       %{
         status: 200,
         body: """
         {
           "object":"subscription",
           "unknown_attr": null
         }
         """,
         headers: []
       }}
    end
  end

  test "opts are passed through" do
    client =
      Stripe.new(
        api_key: "sk_test_123",
        http_client: TestClient
      )

    assert {:ok, %Stripe.Subscription{}} =
             Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]},
               http_opts: [timeout: 3000]
             )

    assert_receive timeout: 3000
  end
end
