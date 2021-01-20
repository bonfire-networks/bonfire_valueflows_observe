defmodule ValueFlows.Observe.Classifications do

  alias Bonfire.Classify.Categories

  import Bonfire.Common.Utils, only: [maybe_put: 3]
  alias Bonfire.Common.Utils
  alias Bonfire.Repo

  def one(filters) do
    Categories.one(filters) |> from_classification()
  end

  def create(user, attrs, facet, extra_info \\ %{}) do
    Categories.create(
        user,
        attrs
          |> to_classification(facet)
          |> maybe_put(:extra_info, extra_info)
          # |> IO.inspect
    )
    |> from_classification()
    # |> IO.inspect
  end

  def update(user, %{id: id}, attrs, facet) do
    update(user, id, attrs, facet)
  end

  def update(user, id, attrs, facet) when is_binary(id) do
    with {:ok, obj} <- Bonfire.Classify.Categories.one(id: id) do
      Categories.update(user, obj, to_classification(attrs, facet)) |> from_classification()
    end
  end

  def to_classification(attrs, facet \\ nil) do
    attrs
      |> maybe_put(:name, Map.get(attrs, :label))
      |> maybe_put(:summary, Map.get(attrs, :note))
      |> maybe_put(:facet, facet)
  end

  def from_classification({_ = ret, %{} = attrs}) do
    {ret, from_classification(attrs)}
  end

  def from_classification(%{} = attrs) do
    attrs = flatten(attrs)

    attrs
      |> maybe_put(:label, Map.get(attrs, :name))
      |> maybe_put(:note, Map.get(attrs, :summary))
      # |> IO.inspect
  end

  def from_classification(other), do: other

  def flatten(obj) do
    # IO.inspect(obj)
    obj = Repo.maybe_preload(obj, :profile)

    obj
    |> Map.merge(Map.get(obj, :extra_info, %{}))
    |> Map.merge(Map.get(obj, :profile, %{}))
    # |> Map.merge(Map.get(obj, :character))
  end

  def to_ecto_struct(module, map) do
    struct(module) |> Ecto.Changeset.cast(Utils.stringify_keys(map, false), module.__schema__(:fields)) |> Ecto.Changeset.apply_changes()
  end
end
