defmodule Stripe.SubscriptionsTest do
  use Stripe.Case

  @tag :stripe_mock
  test ~f{&Stripe.Subscription.retrieve/2} do
    client = Stripe.new(api_key: "sk_test_123", base_url: "http://localhost:12111")

    assert {:ok, %Stripe.Subscription{} = subscription} =
             Stripe.Subscription.retrieve(client, "sub123", %{expand: [:customer]})

    assert %Stripe.Customer{} = subscription.customer
  end

  describe ~f{&Stripe.Subscription.create/2} do
    @describetag :stripe_mock

    test "succeeds" do
      client =
        Stripe.new(
          api_key: "sk_test_123",
          base_url: "http://localhost:12111"
        )

      assert {:ok, %Stripe.Subscription{}} =
               Stripe.Subscription.create(client, %{
                 customer: "cus_4QFJOjw2pOmAGJ",
                 items: [
                   %{price: "price_1LnEPr2eZvKYlo2C8bVNzTbb"}
                 ]
               })
    end

    test "fails" do
      client =
        Stripe.new(
          api_key: "sk_test_123",
          base_url: "http://localhost:12111",
          base_backoff: 0
        )

      assert {:error, %Stripe.ApiErrors{}} = Stripe.Subscription.create(client, %{})
    end
  end

  describe ~f{&Stripe.Subscription.list/2} do
    @describetag :stripe_mock
    test "succeeds" do
      client =
        Stripe.new(
          api_key: "sk_test_123",
          base_url: "http://localhost:12111"
        )

      assert {:ok, %Stripe.List{}} = Stripe.Subscription.list(client, %{status: "active"})
    end
  end
end
