defmodule Stripe.List do
  @moduledoc """
  All top-level API resources have support for bulk fetches via "list" API methods. For instance, you can list charges, list customers, and list invoices. These list API methods share a common structure, taking at least these three parameters: `limit`, `starting_after`, and `ending_before`.

  Stripe's list API methods utilize cursor-based pagination via the `starting_after` and `ending_before` parameters. Both parameters take an existing object ID value (see below) and return objects in reverse chronological order. The `ending_before` parameter returns objects listed before the named object. The `starting_after` parameter returns objects listed after the named object. These parameters are mutually exclusive -- only one of `starting_after` or `ending_before` may be used.
  """

  @type value :: term

  @type t(value) :: %__MODULE__{
          object: binary,
          data: [value],
          has_more: boolean,
          url: binary
        }

  defstruct [:object, :data, :has_more, :url]
end
