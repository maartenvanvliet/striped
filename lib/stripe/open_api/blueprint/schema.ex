defmodule OpenApiGen.Blueprint.Schema do
  @moduledoc false
  defstruct [:name, :description, :module, operations: [], properties: []]
end
