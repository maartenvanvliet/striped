defmodule Stripe.SearchResult do
  @moduledoc """
  Some top-level API resource have support for retrieval via "search" API methods. For example, you can search charges, search customers, and search subscriptions.

  Stripe's search API methods utilize cursor-based pagination via the `page` request parameter and `next_page` response parameter. For example, if you make a search request and receive "next_page": "pagination_key" in the response, your subsequent call can include page=pagination_key to fetch the next page of results.
  """

  @type value :: term

  @type t(value) :: %__MODULE__{
          object: binary,
          data: [value],
          has_more: boolean,
          total_count: integer | nil,
          next_page: binary | nil,
          url: binary
        }

  defstruct [:object, :data, :has_more, :total_count, :next_page, :url]
end
