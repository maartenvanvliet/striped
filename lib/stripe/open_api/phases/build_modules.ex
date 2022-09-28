defmodule Stripe.OpenApi.Phases.BuildModules do
  @moduledoc false
  def run(blueprint, _options \\ []) do
    components =
      for {name, map} <- blueprint.source["components"]["schemas"],
          # map["x-stripeOperations"] != nil,
          map["x-resourceId"] != nil || name == "api_errors",
          into: %{} do
        resource =
          (map["x-resourceId"] || name) |> String.split(".") |> Enum.map(&Macro.camelize/1)

        {name,
         %OpenApiGen.Blueprint.Schema{
           name: name,
           description: map["description"],
           operations:
             (map["x-stripeOperations"] || [])
             |> Enum.uniq_by(& &1["method_name"])
             |> Enum.map(&%{&1 | "method_name" => Macro.underscore(&1["method_name"])}),
           module: Module.concat(["Stripe" | resource]),
           properties: map["properties"] || %{}
         }}
      end

    {:ok, %{blueprint | components: components}}
  end
end
