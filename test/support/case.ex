defmodule Stripe.Case do
  defmacro __using__(opts \\ [async: true]) do
    quote do
      use ExUnit.Case, unquote(opts)
      import Stripe.Case
    end
  end

  def sigil_f(string, []) do
    {_result, _binding} = Code.eval_string(string, [], __ENV__)
    string
  end
end
