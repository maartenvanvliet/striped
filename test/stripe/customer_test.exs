defmodule Stripe.CustomerTest do
  use Stripe.Case

  test "exports functions" do
    assert [
             {:__struct__, 0},
             {:__struct__, 1},
             {:balance_transactions, 2},
             {:balance_transactions, 3},
             {:create, 1},
             {:create, 2},
             {:create_funding_instructions, 2},
             {:create_funding_instructions, 3},
             {:delete, 2},
             {:delete_discount, 2},
             {:fund_cash_balance, 2},
             {:fund_cash_balance, 3},
             {:list, 1},
             {:list, 2},
             {:list_payment_methods, 2},
             {:list_payment_methods, 3},
             {:retrieve, 2},
             {:retrieve, 3},
             {:retrieve_payment_method, 3},
             {:retrieve_payment_method, 4},
             {:search, 1},
             {:search, 2},
             {:update, 2},
             {:update, 3}
           ] = Stripe.Customer.__info__(:functions)
  end

  @tag :stripe_mock
  test ~f{&Stripe.Customer.retrieve/2} do
    client = Stripe.new(api_key: "sk_test_123", base_url: "http://localhost:12111")

    assert {:ok, %Stripe.Customer{} = customer} = Stripe.Customer.retrieve(client, "sub123")
    assert %{id: "sub123"} = customer
  end

  describe ~f{&Stripe.Customer.create/2} do
    @describetag :stripe_mock
    test "succeeds" do
      client =
        Stripe.new(
          api_key: "sk_test_123",
          base_url: "http://localhost:12111"
        )

      assert {:ok, %Stripe.Customer{}} =
               Stripe.Customer.create(client, %{
                 description: "Test description"
               })
    end
  end

  describe ~f{&Stripe.Customer.delete/2} do
    @describetag :stripe_mock
    test "succeeds" do
      client =
        Stripe.new(
          api_key: "sk_test_123",
          base_url: "http://localhost:12111"
        )

      assert {:ok, %Stripe.DeletedCustomer{}} = Stripe.Customer.delete(client, "cus_234")
    end
  end

end
