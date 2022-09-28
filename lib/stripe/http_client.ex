defmodule Stripe.HTTPClient do
  @callback init() :: :ok

  @callback request(
              method :: atom(),
              url :: binary(),
              headers :: [{binary(), binary()}],
              body :: binary(),
              opts :: keyword()
            ) ::
              {:ok,
               %{
                 status: 200..599,
                 headers: [{binary(), binary()}],
                 body: binary()
               }}
              | {:error, term()}
end
