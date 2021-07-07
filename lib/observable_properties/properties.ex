defmodule ValueFlows.Observe.ObservableProperties do

  alias ValueFlows.Observe.Classifications

  def facet, do: "ObservableProperty"
  def id, do: "71XTVRE0BSERVAB1EPR0PERTY1"

  defdelegate one(filters), to: Classifications

  def create(user, attrs) do
    Classifications.create(user, Map.put_new(attrs, :parent_category, id()), facet())
  end

  def update(user, obj, attrs) do
    Classifications.update(user, obj, attrs, facet())
  end
end
