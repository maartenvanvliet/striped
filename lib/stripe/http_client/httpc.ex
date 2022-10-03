defmodule Stripe.HTTPClient.HTTPC do
  @moduledoc false
  @behaviour Stripe.HTTPClient

  @impl true
  def init() do
    {:ok, _} = Application.ensure_all_started(:inets)
    :ok
  end

  @impl true
  def request(:post = method, url, headers, body, opts) do
    headers = for {k, v} <- headers, do: {String.to_charlist(k), String.to_charlist(v)}
    request = {String.to_charlist(url), headers, ~C(application/x-www-form-urlencoded), body}

    do_request(method, request, opts)
  end

  def request(method, url, headers, _body, opts) do
    headers = for {k, v} <- headers, do: {String.to_charlist(k), String.to_charlist(v)}
    request = {String.to_charlist(url), headers}

    do_request(method, request, opts)
  end

  defp do_request(method, request, opts) do
    case :httpc.request(method, request, opts, body_format: :binary) do
      {:ok, {{_, status, _}, headers, body}} ->
        headers = for {k, v} <- headers, do: {List.to_string(k), List.to_string(v)}

        {:ok, %{status: status, headers: headers, body: body}}

      {:error, error} ->
        {:error, error}
    end
  end
end
