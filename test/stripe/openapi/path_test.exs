defmodule Stripe.OpenApi.PathTest do
  use Stripe.Case

  test "replaces url params" do
    path = "http://localhost:12111/v1/subscriptions/{subscription_exposed_id}"

    path_param_defs = [
      %OpenApiGen.Blueprint.Parameter{
        in: "path",
        name: "subscription_exposed_id",
        required: true,
        schema: %{"maxLength" => 5000, "type" => "string"}
      }
    ]

    path_params_values = ["sub123"]

    assert "http://localhost:12111/v1/subscriptions/sub123" =
             Stripe.OpenApi.Path.replace_path_params(path, path_param_defs, path_params_values)
  end
end
