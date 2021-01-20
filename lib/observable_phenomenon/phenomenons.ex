defmodule ValueFlows.Observe.ObservablePhenomenons do

  alias ValueFlows.Observe.Classifications

  @facet "ObservablePhenomenon"

  defdelegate one(filters), to: Classifications


  def create(user, %{} = observable_property, attrs) do
    Classifications.create(
      user,
      attrs,
      @facet,
      %{
        choice_of: observable_property.id,
        formula_quantifier: Map.get(attrs, :formula_quantifier),
      }
    )
  end

  def update(user, obj, attrs) do
    Classifications.update(user, obj, attrs, @facet)
  end
end
