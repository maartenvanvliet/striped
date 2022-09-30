defmodule OpenApiGen.Blueprint do
  @moduledoc false
  defstruct [:components, :source, :operations, :modules]

  def lookup_component(ref, blueprint) do
    blueprint.components
    |> Enum.find(fn {_, component} -> component.ref == ref end)
    |> elem(1)
  end

  # def
end
