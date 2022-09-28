defmodule Stripe.OpenApi.Phases.BuildOperations do
  @moduledoc false
  def run(blueprint, options \\ []) do
    operations =
      for {path, map} <- blueprint.source["paths"],
          !options[:only_paths] or path in options[:only_paths],
          !options[:path_prefixes] or String.starts_with?(path, options[:path_prefixes]),
          {method, map} <- map,
          into: %{} do
        name =
          map["operationId"]
          |> String.replace(["/", "-"], "_")
          |> Macro.underscore()
          |> String.to_atom()

        method = String.to_atom(method)

        parameters = parameters(map["parameters"])

        {path_params, query_params} =
          parameters
          |> Enum.split_with(&(&1.in == "path"))

        body_params =
          map["requestBody"]["content"]["application/x-www-form-urlencoded"]["schema"][
            "properties"
          ] || %{}

        body_params =
          body_params
          |> Enum.map(fn {key, value} ->
            %OpenApiGen.Blueprint.Parameter{
              in: "body",
              name: key,
              required: false,
              schema: build_schema(value)
            }
          end)

        operation = %OpenApiGen.Blueprint.Operation{
          id: map["operationId"],
          description: map["description"],
          deprecated: map["deprecated"] || false,
          method: method,
          name: name,
          parameters: parameters,
          path_parameters: path_params,
          query_parameters: query_params,
          body_parameters: body_params,
          path: path,
          success_response:
            response_type(map["responses"]["200"]["content"]["application/json"]["schema"])
        }

        {{operation.path, operation.method}, operation}
      end

    blueprint = Map.put(blueprint, :operations, operations)
    {:ok, blueprint}
  end

  defp response_type(%{"$ref" => ref}), do: %OpenApiGen.Blueprint.Reference{name: ref}

  defp response_type(%{"anyOf" => any_of}),
    do: %OpenApiGen.Blueprint.AnyOf{any_of: Enum.map(any_of, &response_type/1)}

  defp response_type(%{
         "properties" => %{
           "object" => %{
             "enum" => [
               "search_result"
             ]
           },
           "data" => %{"items" => items}
         }
       }) do
    %OpenApiGen.Blueprint.SearchResult{type_of: response_type(items)}
  end

  defp response_type(%{
         "properties" => %{
           "data" => %{"items" => items}
         }
       }),
       do: %OpenApiGen.Blueprint.ListOf{type_of: response_type(items)}

  defp response_type(val), do: val

  defp parameters(nil) do
    []
  end

  defp parameters(params) do
    Enum.map(
      params,
      &%OpenApiGen.Blueprint.Parameter{
        in: &1["in"],
        name: &1["name"],
        required: &1["required"],
        schema: build_schema(&1["schema"])
      }
    )
  end

  defp build_schema(schema, name \\ nil)

  defp build_schema(%{"type" => type} = schema, name)
       when type in ["string", "integer", "boolean", "number"] do
    %OpenApiGen.Blueprint.Parameter.Schema{
      type: schema["type"],
      name: name
    }
  end

  defp build_schema(%{"type" => "array"} = schema, name) do
    %OpenApiGen.Blueprint.Parameter.Schema{
      type: schema["type"],
      items: build_schema(schema["items"]),
      name: name
    }
  end

  defp build_schema(%{"type" => "object"} = schema, name) do
    %OpenApiGen.Blueprint.Parameter.Schema{
      type: schema["type"],
      name: name,
      properties:
        (schema["properties"] || []) |> Enum.map(&build_schema(elem(&1, 1), elem(&1, 0)))
    }
  end

  defp build_schema(%{"anyOf" => any_of} = _schema, name) do
    %OpenApiGen.Blueprint.Parameter.Schema{
      type: :any_of,
      any_of: any_of |> Enum.map(&build_schema(&1)),
      name: name
    }
  end
end
