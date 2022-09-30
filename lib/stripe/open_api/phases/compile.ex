defmodule Stripe.OpenApi.Phases.Compile do
  @moduledoc false
  def run(blueprint, _options) do
    modules = Enum.map(blueprint.components, fn {_k, component} -> component.module end)

    for {_name, component} <- blueprint.components do
      funcs =
        for operation <- component.operations,
            operation_definition =
              lookup_operation(
                {operation["path"], String.to_atom(operation["operation"])},
                blueprint.operations
              ),
            operation_definition != nil do
          arguments =
            operation_definition.path_parameters
            |> Enum.map(&String.to_atom(&1.name))

          params? =
            operation_definition.query_parameters != [] ||
              operation_definition.body_parameters != []

          argument_names =
            arguments
            |> Enum.map(fn
              name ->
                Macro.var(name, __MODULE__)
            end)

          argument_values =
            arguments
            |> Enum.reject(&(&1 == :params))
            |> Enum.map(fn name ->
              Macro.var(name, __MODULE__)
            end)

          argument_specs =
            arguments
            |> Enum.map(fn
              :params ->
                quote do
                  params :: map()
                end

              name ->
                quote do
                  unquote(Macro.var(name, __MODULE__)) :: binary()
                end
            end)

          function_name = String.to_atom(operation["method_name"])

          success_response_spec = return_spec(operation_definition.success_response)

          quote do
            if unquote(operation_definition.deprecated) do
              @deprecated "Stripe has deprecated this operation"
            end

            @operation unquote(Macro.escape(operation_definition))
            @doc unquote(operation_definition.description)

            if unquote(params?) do
              @spec unquote(function_name)(
                      client :: term(),
                      unquote_splicing(argument_specs),
                      params :: map()
                    ) ::
                      {:ok, unquote(success_response_spec)} | {:error, Stripe.ApiErrors.t()} | {:error, term()}
              def unquote(function_name)(
                    client,
                    unquote_splicing(argument_names),
                    params \\ %{}
                  ) do
                path =
                  Stripe.OpenApi.Path.replace_path_params(
                    @operation.path,
                    @operation.path_parameters,
                    unquote(argument_values)
                  )

                Stripe.request(@operation.method, path, client, params || %{})
              end
            else
              @spec unquote(function_name)(client :: term(), unquote_splicing(argument_specs)) ::
                      {:ok, unquote(success_response_spec)} | {:error, Stripe.ApiErrors.t()} | {:error, term()}
              def unquote(function_name)(
                    client,
                    unquote_splicing(argument_names)
                  ) do
                path =
                  Stripe.OpenApi.Path.replace_path_params(
                    @operation.path,
                    @operation.path_parameters,
                    unquote(argument_values)
                  )

                Stripe.request(@operation.method, path, client, %{})
              end
            end
          end
        end

      fields = component.properties |> Map.keys() |> Enum.map(&String.to_atom/1)

      specs =
        Enum.map(component.properties, fn {key, value} ->
          {String.to_atom(key), build_spec(value, modules)}
        end)

      typedoc_fields =
        component.properties |> Enum.map_join("\n", fn {key, value} -> typedoc(key, value) end)

      typedoc = """
      The `#{component.name}` type.

      #{typedoc_fields}
      """

      description =
        if funcs == [] do
          component.description
        else
          component.description
        end

      body =
        quote do
          @moduledoc unquote(description)
          if unquote(fields) != nil do
            @derive {Inspect, optional: unquote(fields)}
            defstruct unquote(fields)

            @typedoc unquote(typedoc)
            @type t :: %__MODULE__{
                    unquote_splicing(specs)
                  }
          end

          (unquote_splicing(funcs))
        end

      Module.create(component.module, body, Macro.Env.location(__ENV__))
    end

    {:ok, blueprint}
  end

  defp return_spec(%OpenApiGen.Blueprint.Reference{name: name}) do
    module = module_from_ref(name)

    quote do
      unquote(module).t()
    end
  end

  defp return_spec(%OpenApiGen.Blueprint.ListOf{type_of: type}) do
    quote do
      Stripe.List.t(unquote(return_spec(type)))
    end
  end

  defp return_spec(%OpenApiGen.Blueprint.SearchResult{type_of: type}) do
    quote do
      Stripe.SearchResult.t(unquote(return_spec(type)))
    end
  end

  defp return_spec(%{any_of: [type]} = _type) do
    return_spec(type)
  end

  defp return_spec(%OpenApiGen.Blueprint.AnyOf{any_of: [any_of | tail]} = type) do
    type = Map.put(type, :any_of, tail)
    {:|, [], [return_spec(any_of), return_spec(type)]}
  end

  defp return_spec(_) do
    []
  end

  defp build_spec(%{"nullable" => true} = type, modules) do
    type = Map.delete(type, "nullable")
    {:|, [], [build_spec(type, modules), nil]}
  end

  defp build_spec(%{"anyOf" => [type]} = _type, modules) do
    build_spec(type, modules)
  end

  defp build_spec(%{"anyOf" => [any_of | tail]} = type, modules) do
    type = Map.put(type, "anyOf", tail)
    {:|, [], [build_spec(any_of, modules), build_spec(type, modules)]}
  end

  defp build_spec(%{"type" => "string"}, _) do
    quote do
      binary
    end
  end

  defp build_spec(%{"type" => "boolean"}, _) do
    quote do
      boolean
    end
  end

  defp build_spec(%{"type" => "integer"}, _) do
    quote do
      integer
    end
  end

  defp build_spec(%{"$ref" => ref}, modules) do
    module = module_from_ref(ref)

    if module in modules do
      quote do
        unquote(module).t()
      end
    else
      quote do
        term
      end
    end
  end

  defp build_spec(_, _) do
    quote do
      term
    end
  end

  defp module_from_ref(ref) do
    module =
      ref |> String.split("/") |> List.last() |> String.split(".") |> Enum.map(&Macro.camelize/1)

    Module.concat(["Stripe" | module])
  end

  defp typedoc(field, props) do
    "  * `#{field}` #{props["description"]}"
  end

  defp lookup_operation(path, operations) do
    Map.get(operations, path)
  end
end
