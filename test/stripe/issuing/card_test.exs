defmodule Stripe.Issuing.CardTest do
  use Stripe.Case

  test "exports functions" do
    assert [
             __struct__: 0,
             __struct__: 1,
             create: 1,
             create: 2,
             deliver_card: 2,
             deliver_card: 3,
             fail_card: 2,
             fail_card: 3,
             list: 1,
             list: 2,
             retrieve: 2,
             retrieve: 3,
             return_card: 2,
             return_card: 3,
             ship_card: 2,
             ship_card: 3,
             update: 2,
             update: 3
           ] = Stripe.Issuing.Card.__info__(:functions)
  end

  @tag :stripe_mock
  test ~f{&Stripe.Issuing.Card.retrieve/2} do
    client = Stripe.new(api_key: "sk_test_123", base_url: "http://localhost:12111")
    assert {:ok, res} = Stripe.Issuing.Card.retrieve(client, "sub123")
    assert %Stripe.Issuing.Card{} = res
  end
end
