defmodule Stripe do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Stripe.OpenApi,
    path: [:code.priv_dir(:striped), "openapi", "spec3.sdk.json"]
    |> Path.join(),
    base_url: "https://api.stripe.com"

  def request(:get = method, path, client, params) do
    query = (params || %{}) |> UriQuery.params() |> URI.encode_query()
    url = URI.append_query(URI.parse(client.base_url <> path), query) |> URI.to_string() |> IO.inspect

    headers =
      [
        {"user-agent", "striped"},
        {"authorization", "Bearer #{client.api_key}"}
      ]
      |> maybe_concat(["stripe-version: #{client.version}"], client.version != nil)

    body = ""
    opts = []

    do_request(client, method, url, headers, body, opts)
  end

  def request(method, path, client, params) do
    url = client.base_url <> path

    headers =
      [
        {"user-agent", "striped"},
        {"authorization", "Bearer #{client.api_key}"}
      ]
      |> maybe_concat(["stripe-version: #{client.version}"], client.version != nil)
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

  defp convert_value(%{"object" => type, "deleted" => _} = object) do
    struct = object_type_to_struct(type, deleted: true)
    map = convert_map(object)
    struct!(struct, map)
  end

  defp convert_value(%{"object" => type} = object) do
    struct = object_type_to_struct(type)
    map = convert_map(object)
    struct!(struct, map)
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
