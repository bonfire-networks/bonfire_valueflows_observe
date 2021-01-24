# SPDX-License-Identifier: AGPL-3.0-only
if Code.ensure_loaded?(Bonfire.GraphQL) do
defmodule ValueFlows.Observe.ObservablePropertiesGraphQL do
  alias Bonfire.GraphQL

  require Logger

  # resolvers

  def create_observable_property(%{observable_property: params}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info) do
      ValueFlows.Observe.ObservableProperties.create(user, params)
    end
  end

  def update_observable_property(%{observable_property: %{id: id} = params}, info) do
    # IO.inspect(update: params)
    with  {:ok, user} <- GraphQL.current_user_or_not_logged_in(info) do
      ValueFlows.Observe.ObservableProperties.update(user, id, params)
    end
  end

  def delete_observable_property(%{id: id}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
          {:ok, observable_property} <- Bonfire.Classify.Categories.one(id: id),
          # TODO: check permissions
          {:ok, _} <- Bonfire.Classify.Categories.soft_delete(observable_property) do
      {:ok, true}
    end
  end


  # with pagination
  def observable_properties(page_opts, info) do
    # TODO: query ONLY catagories with facet==ObservableProperty
    pages =
      if Bonfire.Common.Utils.module_exists?(Bonfire.Classify.GraphQL.CategoryResolver) do
        with {:ok, pages} <- Bonfire.Classify.GraphQL.CategoryResolver.categories(page_opts, info, {:facet, ValueFlows.Observe.ObservableProperties.facet()}) do
          # IO.inspect(observable_properties: pages)
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
  # def all_observable_properties(%{}, info) do
  #   {:ok, Bonfire.Classify.Categories.many()}
  # end

  def observable_property(%{id: id}, _info) do
    ValueFlows.Observe.ObservableProperties.one(id: id)
  end

  def phenomenons_edge(thing, page_info, info) do
    with {:ok, children} <- Bonfire.Classify.GraphQL.CategoryResolver.category_children(thing, page_info, info) do
      {:ok, Enum.map(
              children.edges,
              &(&1
                |> ValueFlows.Observe.Classifications.from_classification())
            )
      }
    end
  end


end
end
