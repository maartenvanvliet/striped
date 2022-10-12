defmodule Stripe.SubscriptionsTest do
  use Stripe.Case

  test "exports functions" do
    assert [
             {:__struct__, 0},
             {:__struct__, 1},
             {:cancel, 2},
             {:cancel, 3},
             {:cancel, 4},
             {:create, 1},
             {:create, 2},
             {:create, 3},
             {:delete_discount, 2},
             {:delete_discount, 3},
             {:list, 1},
             {:list, 2},
             {:list, 3},
             {:retrieve, 2},
             {:retrieve, 3},
             {:retrieve, 4},
             {:search, 1},
             {:search, 2},
             {:search, 3},
             {:update, 2},
             {:update, 3},
             {:update, 4}
           ] = Stripe.Subscription.__info__(:functions)
  end

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
          base_url: "http://localhost:12111"
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
