defmodule Stripe.InvoiceTest do
  use Stripe.Case

  describe ~f{Stripe.Invoice} do
    test "exports functions" do
      assert [
               {:__struct__, 0},
               {:__struct__, 1},
               {:create, 1},
               {:create, 2},
               {:create, 3},
               {:delete, 2},
               {:delete, 3},
               {:finalize_invoice, 2},
               {:finalize_invoice, 3},
               {:finalize_invoice, 4},
               {:list, 1},
               {:list, 2},
               {:list, 3},
               {:mark_uncollectible, 2},
               {:mark_uncollectible, 3},
               {:mark_uncollectible, 4},
               {:pay, 2},
               {:pay, 3},
               {:pay, 4},
               {:retrieve, 2},
               {:retrieve, 3},
               {:retrieve, 4},
               {:search, 1},
               {:search, 2},
               {:search, 3},
               {:send_invoice, 2},
               {:send_invoice, 3},
               {:send_invoice, 4},
               {:upcoming, 1},
               {:upcoming, 2},
               {:upcoming, 3},
               {:upcoming_lines, 1},
               {:upcoming_lines, 2},
               {:upcoming_lines, 3},
               {:update, 2},
               {:update, 3},
               {:update, 4},
               {:void_invoice, 2},
               {:void_invoice, 3},
               {:void_invoice, 4}
             ] = Stripe.Invoice.__info__(:functions)
    end
  end

  @tag :stripe_mock
  test ~f{&Stripe.Invoice.retrieve/2} do
    client = Stripe.new(api_key: "sk_test_123", base_url: "http://localhost:12111")
    assert {:ok, _} = Stripe.Invoice.retrieve(client, "in")
  end
end
