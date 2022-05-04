defmodule ValueFlows.Observe.Seeds do
  import Ecto.Query
  import Bonfire.Common.Config, only: [repo: 0]
  import Where

  alias ValueFlows.Observe.Classifications
  alias ValueFlows.Observe.ObservableProperties
  alias ValueFlows.Observe.ObservablePhenomenons

  def up(_repo) do
    debug("Seeding valueflows_observe")

    Classifications.create(nil, %{id: ObservableProperties.id(), label: "Observable Properties", username: ObservableProperties.facet()}, "Facet")

    # Classifications.create(nil, %{id: ObservablePhenomenons.id()}, "Facet")

  end

  def down(_repo) do
    debug("Un-seeding valueflows_observe")

    # id = ObservableProperties.id()
    # from(x in Pointers.Pointer, where: x.id == ^id) |> repo().delete_all

    # Bonfire.Classify.Categories.soft_delete(ObservableProperties.facet())

    with {:ok, c} <- ObservableProperties.facet() |> Bonfire.Classify.Categories.get() do
      Bonfire.Common.Repo.Delete.hard_delete(c)
    end

    name = ObservableProperties.facet()
    from(x in Bonfire.Data.Identity.Character, where: x.username == ^name) |> repo().delete_all


  end

end
