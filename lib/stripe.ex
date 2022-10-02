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

  def request(method, path, client, params) when method in [:get, :delete] do
    query = (params || %{}) |> UriQuery.params() |> URI.encode_query()
    url = URI.parse(client.base_url <> path) |> URI.append_query(query) |> URI.to_string()

    headers = build_headers(client)

    do_request(client, method, url, headers, "", [])
  end

  def request(:post = method, path, client, params) do
    url = client.base_url <> path

    headers =
      build_headers(client)
      |> maybe_concat(
        ["Idempotency-Key: #{generate_idempotency_key()}"],
        client.idempotency_key == nil
      )

    body = (params || %{}) |> UriQuery.params() |> URI.encode_query()
    opts = []

    do_request(client, method, url, headers, body, opts)
  end

  defp do_request(client, method, url, headers, body, opts) do
    with {:ok, resp} <- client.http_client.request(method, url, headers, body, opts) do
      case resp.status do
        status when status >= 200 and status <= 299 -> {:ok, decode_body(resp.body)}
        _status -> {:error, Jason.decode!(resp.body) |> build_error()}
      end
    end
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

  defp decode_body(body) when is_binary(body) do
    body |> Jason.decode!() |> convert_value()
  end

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
