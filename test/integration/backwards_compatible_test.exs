defmodule Stripe.BackwardsCompatibleTest do
  use Stripe.Case

  # https://stripe.com/docs/upgrades#what-changes-does-stripe-consider-to-be-backwards-compatible
  defmodule TestClientExtraAttr do
    def init() do
      :ok
    end

    def request(:get, _, _, _, _) do
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

  test "handles extra attributes" do
    client =
      Stripe.new(
        api_key: "sk_test_123",
        http_client: TestClientExtraAttr
      )

    assert {:ok, %Stripe.Subscription{}} =
             Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})
  end

  defmodule TestClientNewObject do
    def init() do
      :ok
    end

    def request(:get, _, _, _, _) do
      {:ok,
       %{
         status: 200,
         body: """
         {
           "object":"unknown_object",
           "unknown_attr": null
         }
         """,
         headers: []
       }}
    end
  end

  test "handles new objects" do
    client =
      Stripe.new(
        api_key: "sk_test_123",
        http_client: TestClientNewObject
      )

    assert {:ok, %{object: "unknown_object", unknown_attr: nil}} =
             Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})
  end
end
