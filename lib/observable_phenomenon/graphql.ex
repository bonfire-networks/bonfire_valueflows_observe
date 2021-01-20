# SPDX-License-Identifier: AGPL-3.0-only
if Code.ensure_loaded?(Bonfire.GraphQL) do
defmodule ValueFlows.Observe.ObservablePhenomenonsGraphQL do
  alias Bonfire.GraphQL

  require Logger

  # resolvers

  def create_observable_phenomenon(%{observable_phenomenon: %{choice_of: choice_of}} = params, info) do
    with  {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
          {:ok, observable_property} <- ValueFlows.Observe.ObservablePropertiesGraphQL.observable_property(%{id: choice_of}, info) do
      ValueFlows.Observe.ObservablePhenomenons.create(user, observable_property, params)
    end
  end

  def update_observable_phenomenon(%{observable_phenomenon: %{id: id}} = params, info) do
    with  {:ok, user} <- GraphQL.current_user_or_not_logged_in(info) do
      ValueFlows.Observe.ObservablePhenomenons.update(user, id, params)
    end
  end

  def delete_observable_phenomenon(%{id: id}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
          {:ok, observable_phenomenon} <- Bonfire.Classify.Categories.one(%{id: id}),
          # TODO: check permissions
          {:ok, _} <- Bonfire.Classify.Categories.soft_delete(observable_phenomenon) do
      {:ok, true}
    end
  end


  # with pagination
  def observable_phenomenons(page_opts, info) do
    pages =
      if Bonfire.Common.Utils.module_exists?(Bonfire.Classify.GraphQL.CategoryResolver) do
        with {:ok, pages} <- Bonfire.Classify.GraphQL.CategoryResolver.categories(page_opts, info) do
          items =
            Enum.map(
              pages.edges,
              &(&1
                |> ValueFlows.Observe.Classifications.from_classification())
            )

          %{ pages | edges: items}

        end
      else

        %{
          edges: [],
          page_info: nil,
          total_count: 0
        }
    end

    {:ok, pages}
  end

  # without pagination
  # def all_observable_phenomenons(%{}, info) do
  #   {:ok, Bonfire.Classify.Categories.many()}
  # end

  def get(%{id: id}, _info) do
    ValueFlows.Observe.ObservablePhenomenons.one(id: id)
  end


end
end
