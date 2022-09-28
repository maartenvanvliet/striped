defmodule Stripe.OpenApi.Phases.BuildDocumentation do
  @moduledoc false
  def run(blueprint, _options \\ []) do
    operations =
      Enum.map(blueprint.operations, fn {key, operation} ->
        {key, build_description(operation)}
      end)
      |> Map.new()

    {:ok, %{blueprint | operations: operations}}
  end

  defp build_description(operation) do
    %{operation | description: do_build_description(operation)}
  end

  defp do_build_description(operation) do
    description = operation.description

    """
    #{description}

    #### Details

     * Method: `#{operation.method}`
     * Path: `#{operation.path}`

    #{build_parameters_description("Query parameters", operation.query_parameters)}
    """
  end

  defp build_parameters_description(_, []) do
    ""
  end

  defp build_parameters_description(title, parameters) do
    parameters =
      parameters
      |> Enum.map_join("\n", &build_parameter_description/1)

    """

    #### #{title}
    #{parameters}
    """
  end

  defp indent(n) do
    String.duplicate(" ", (n + 1) * 2)
  end

  defp build_parameter_description(parameter) do
    "  * `:#{parameter.name}` #{required(parameter.required)} #{parameter_schema(parameter.schema, 0)}"
  end

  defp parameter_schema(%{type: type}, _) when type in ["boolean", "string", "integer"] do
    type
  end

  defp parameter_schema(%{type: "array", items: items} = _type, indent) do
    "array of:\n #{parameter_schema(items, indent + 1)}"
  end

  defp parameter_schema(%{type: "object", properties: properties, title: _title}, indent) do
    properties =
      Enum.map_join(properties, "\n", fn property ->
        value = parameter_schema(property, indent + 1)
        "#{indent(indent + 2)}* `#{property.name}`: #{value}"
      end)

    "object with (optional) properties: \n#{properties}"
  end

  defp parameter_schema(%{any_of: any_of}, indent) do
    any_of =
      Enum.map_join(any_of, "\n", fn type ->
        type = type |> parameter_schema(indent + 1)
        "#{indent(indent + 1)}* #{type}"
      end)

    "any of: \n #{any_of}"
  end

  defp required(true), do: "(Required)"
  defp required(_), do: ""
end
