defmodule ValueFlows.Observe.ObservableProperties do

  alias ValueFlows.Observe.Classifications

  @facet "ObservableProperty"

  defdelegate one(filters), to: Classifications

  def create(user, attrs) do
    Classifications.create(user, attrs, @facet)
  end

  def update(user, obj, attrs) do
    Classifications.update(user, obj, attrs, @facet)
  end
end
