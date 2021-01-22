defmodule ValueFlows.Observe.ObservablePhenomenons do

  alias ValueFlows.Observe.Classifications

  def facet, do: "ObservablePhenomenon"
  # def id, do: "F1XTVRE0BSERVAB1EPHEN0MEN0"

  defdelegate one(filters), to: Classifications


  def create(user, observable_property_id, attrs) when is_binary(observable_property_id) do
    Classifications.create(
      user,
      Map.put_new(attrs, :parent_category, observable_property_id),
      facet(),
      %{
        # choice_of: observable_property_id, # using parent_category instead
        formula_quantifier: Map.get(attrs, :formula_quantifier),
      }
    )
  end

  def create(user, %{id: observable_property_id}, attrs), do: create(user, observable_property_id, attrs)

  def update(user, obj, attrs) do
    Classifications.update(user, obj, attrs, facet())
  end
end
