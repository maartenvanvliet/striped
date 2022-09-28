defmodule Stripe.Case do
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: true
      import Stripe.Case
    end
  end

  def sigil_f(string, []) do
    {_result, _binding} = Code.eval_string(string, [], __ENV__)
    string
  end
end
