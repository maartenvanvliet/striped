defmodule Stripe.TaxIdTest do
  use Stripe.Case

  test "exports functions" do
    assert [
             {:__struct__, 0},
             {:__struct__, 1},
             {:cancel, 2},
             {:cancel, 3},
             {:create, 1},
             {:create, 2},
             {:delete_discount, 2},
             {:list, 1},
             {:list, 2},
             {:retrieve, 2},
             {:retrieve, 3},
             {:search, 1},
             {:search, 2},
             {:update, 2},
             {:update, 3}
           ] = Stripe.Subscription.__info__(:functions)
  end

  @tag :stripe_mock
  test ~f{&Stripe.Subscription.retrieve/2} do
    client = Stripe.new(api_key: "sk_test_123", base_url: "http://localhost:12111")
    assert {:ok, %Stripe.List{} = l} = Stripe.TaxId.list(client, "cus123", %{expand: ["customer"]})
  end
end
