defmodule Stripe do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Stripe.OpenApi,
    path:
      [:code.priv_dir(:striped), "openapi", "spec3.sdk.json"]
      |> Path.join(),
    base_url: "https://api.stripe.com"

  def request(method, path, client, params, opts \\ [])

  def request(method, path, client, params, opts) when method in [:get, :delete] do
    query = (params || %{}) |> UriQuery.params() |> URI.encode_query()
    url = URI.parse(client.base_url <> path) |> URI.append_query(query) |> URI.to_string()

    headers = build_headers(client)

    attempts = 1

    do_request(client, method, url, headers, "", attempts, opts) |> Tuple.delete_at(2)
  end

  def request(:post = method, path, client, params, opts) do
    url = client.base_url <> path

    headers =
      client
      |> build_headers()
      |> maybe_concat(
        ["Idempotency-Key: #{generate_idempotency_key()}"],
        client.idempotency_key == nil
      )

    body = (params || %{}) |> UriQuery.params() |> URI.encode_query()

    attempts = 1

    do_request(client, method, url, headers, body, attempts, opts) |> Tuple.delete_at(2)
  end

  defp do_request(client, method, url, headers, body, attempts, opts) do
    telemetry_event = [:stripe, :request]
    telemetry_metadata = %{attempt: attempts, method: method, url: url}

    :telemetry.span(telemetry_event, telemetry_metadata, fn ->
      result =
        case client.http_client.request(method, url, headers, body, opts) do
          {:ok, resp} ->
            decoded_body = Jason.decode!(resp.body)

            if should_retry?(resp, attempts, client.max_network_retries, decoded_body) do
              do_request(client, method, url, headers, body, attempts + 1, opts)
            else
              case resp do
                %{status: status, headers: headers} when status >= 200 and status <= 299 ->
                  {:ok, convert_value(decoded_body),
                   %{request_id: extract_request_id(headers), status: status}}

                _ ->
                  {:error, build_error(decoded_body),
                   %{request_id: extract_request_id(headers), status: resp.status}}
              end
            end

          {:error, error} ->
            if should_retry?(%{}, attempts, client.max_network_retries) do
              do_request(client, method, url, headers, body, attempts + 1, opts)
            else
              {:error, error, %{}}
            end
        end

      extra_telemetry_metadata =
        case result do
          {:ok, _, extra} -> Map.put(extra, :result, :ok)
          {:error, error, extra} -> Map.merge(extra, %{result: :error, error: error})
        end

      telemetry_metadata = Map.merge(telemetry_metadata, extra_telemetry_metadata)

      {result, telemetry_metadata}
    end)
  end

  defp extract_request_id(headers) do
    List.keyfind(headers, "request-id", 0, {nil, nil}) |> elem(1)
  end

  defp should_retry?(_response, attempts, max_network_retries, decoded_body \\ %{})

  defp should_retry?(_response, attempts, max_network_retries, _decoded_body)
       when attempts >= max_network_retries do
    false
  end

  defp should_retry?(%{status: 429}, _, _, _) do
    true
  end

  defp should_retry?(_response, _attempts, _max_network_retries, %{code: "lock_timeout"}) do
    true
  end

  defp should_retry?(%{headers: headers}, _attempts, _max_network_retries, _decoded_body) do
    case headers |> List.keyfind("stripe-should-retry", 0, nil) do
      nil -> true
      {_, bool} -> String.to_atom(bool)
    end
  end

  defp should_retry?(_, _, _, _) do
    true
  end

  defp build_headers(client) do
    [
      {"user-agent", client.user_agent},
      {"authorization", "Bearer #{client.api_key}"}
    ]
    |> maybe_concat(["stripe-version: #{client.version}"], client.version != nil)
  end

  defp generate_idempotency_key do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      System.unique_integer([:positive])::32
    >>

    Base.hex_encode32(binary, case: :lower, padding: false)
  end

  defp maybe_concat(headers, _header, false), do: headers
  defp maybe_concat(headers, header, true), do: Enum.concat(headers, header)

  defp convert_map(value) do
    Enum.reduce(value, %{}, fn {key, value}, acc ->
      Map.put(acc, String.to_atom(key), convert_value(value))
    end)
  end

  defp build_error(%{"error" => error}) do
    struct = Stripe.ApiErrors

    map = convert_map(error)
    struct!(struct, map)
  end

  defp convert_struct(struct, object) do
    struct_keys = Map.keys(struct.__struct__) |> List.delete(:__struct__)

    processed_map =
      struct_keys
      |> Enum.reduce(%{}, fn key, acc ->
        string_key = to_string(key)

        converted_value =
          case string_key do
            _ -> Map.get(object, string_key) |> convert_value()
          end

        Map.put(acc, key, converted_value)
      end)

    struct!(struct, processed_map)
  end

  defp convert_object(struct, object) do
    if known_struct?(struct) do
      convert_struct(struct, object)
    else
      convert_map(object)
    end
  end

  defp convert_value(%{"object" => type, "deleted" => _} = object) do
    type |> object_type_to_struct(deleted: true) |> convert_object(object)
  end

  defp convert_value(%{"object" => type} = object) do
    type |> object_type_to_struct() |> convert_object(object)
  end

  defp convert_value(map) when is_map(map) do
    convert_map(map)
  end

  defp convert_value(values) when is_list(values) do
    Enum.map(values, &convert_value/1)
  end

  defp convert_value(value) do
    value
  end

  defp known_struct?(struct) do
    function_exported?(struct, :__struct__, 0)
  end

  defp object_type_to_struct(object, opts \\ [])

  defp object_type_to_struct(object, deleted: true) do
    module = object |> String.split(".") |> Enum.map(&Macro.camelize/1)
    Module.concat(["Stripe", "Deleted#{module}"])
  end

  defp object_type_to_struct(object, _) do
    module = object |> String.split(".") |> Enum.map(&Macro.camelize/1)
    Module.concat(["Stripe" | module])
  end
end
