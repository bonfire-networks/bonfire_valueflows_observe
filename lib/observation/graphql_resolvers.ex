# SPDX-License-Identifier: AGPL-3.0-only
if Code.ensure_loaded?(Bonfire.GraphQL) do
defmodule ValueFlows.Observe.Observations.ObservationsResolvers do

  # default to 100 km radius
  @radius_default_distance 100_000

  require Logger

  import Bonfire.Common.Config, only: [repo: 0]

  alias Bonfire.GraphQL
  alias Bonfire.GraphQL.{
    ResolveField,
    ResolvePages,
    ResolveRootPage,
    FetchPage
  }

  alias ValueFlows.Observe.Observation
  alias ValueFlows.Observe.Observations
  alias ValueFlows.Observe.Observation.Queries


  ## resolvers

  def observation(%{id: id}, info) do
    ResolveField.run(%ResolveField{
      module: __MODULE__,
      fetcher: :fetch_observation,
      context: id,
      info: info
    })
  end

  def observations(page_opts, info) do
    ResolveRootPage.run(%ResolveRootPage{
      module: __MODULE__,
      fetcher: :fetch_observations,
      page_opts: page_opts,
      info: info,
      # popularity
      cursor_validators: [&(is_integer(&1) and &1 >= 0), &Pointers.ULID.cast/1]
    })
  end

  def all_observations(_, _) do
    Observations.many([:default])
  end

  def observations_filtered(page_opts, _ \\ nil) do
    observations_filter(page_opts, [])
  end

  # TODO: support several filters combined, plus pagination on filtered queries

  defp observations_filter(%{agent: id} = page_opts, filters_acc) do
    observations_filter_next(:agent, [agent_id: id], page_opts, filters_acc)
  end

  defp observations_filter(%{provider: id} = page_opts, filters_acc) do
    observations_filter_next(:provider, [provider_id: id], page_opts, filters_acc)
  end

  defp observations_filter(%{in_scope_of: context_id} = page_opts, filters_acc) do
    observations_filter_next(:in_scope_of, [context_id: context_id], page_opts, filters_acc)
  end

  defp observations_filter(%{tag_ids: tag_ids} = page_opts, filters_acc) do
    observations_filter_next(:tag_ids, [tag_ids: tag_ids], page_opts, filters_acc)
  end

  defp observations_filter(%{at_location: at_location_id} = page_opts, filters_acc) do
    observations_filter_next(:at_location, [at_location_id: at_location_id], page_opts, filters_acc)
  end

  defp observations_filter(
         %{
           geolocation: %{
             near_point: %{lat: lat, long: long},
             distance: %{meters: distance_meters}
           }
         } = page_opts,
         filters_acc
       ) do
    observations_filter_next(
      :geolocation,
      {
        :near_point,
        %Geo.Point{coordinates: {lat, long}, srid: 4326},
        :distance_meters,
        distance_meters
      },
      page_opts,
      filters_acc
    )
  end

  defp observations_filter(
         %{
           geolocation: %{near_address: address} = geolocation
         } = page_opts,
         filters_acc
       ) do
    with {:ok, coords} <- Geocoder.call(address) do
      observations_filter(
        Map.merge(
          page_opts,
          %{
            geolocation:
              Map.merge(geolocation, %{
                near_point: %{lat: coords.lat, long: coords.lon},
                distance: Map.get(geolocation, :distance, %{meters: @radius_default_distance})
              })
          }
        ),
        filters_acc
      )
    else
      _ ->
        observations_filter_next(
          :geolocation,
          [],
          page_opts,
          filters_acc
        )
    end
  end

  defp observations_filter(
         %{
           geolocation: geolocation
         } = page_opts,
         filters_acc
       ) do
    observations_filter(
      Map.merge(
        page_opts,
        %{
          geolocation:
            Map.merge(geolocation, %{
              # default to 100 km radius
              distance: %{meters: @radius_default_distance}
            })
        }
      ),
      filters_acc
    )
  end

  defp observations_filter(
         _,
         filters_acc
       ) do
    # finally, if there's no more known params to acumulate, query with the filters
    Observations.many(filters_acc)
  end

  defp observations_filter_next(param_remove, filter_add, page_opts, filters_acc)
       when is_list(param_remove) and is_list(filter_add) do
    observations_filter(Map.drop(page_opts, param_remove), filters_acc ++ filter_add)
  end

  defp observations_filter_next(param_remove, filter_add, page_opts, filters_acc)
       when not is_list(filter_add) do
    observations_filter_next(param_remove, [filter_add], page_opts, filters_acc)
  end

  defp observations_filter_next(param_remove, filter_add, page_opts, filters_acc)
       when not is_list(param_remove) do
    observations_filter_next([param_remove], filter_add, page_opts, filters_acc)
  end


  ## fetchers

  def fetch_observation(info, id) do
    Observations.one([
      :default,
      user: GraphQL.current_user(info),
      id: id
      # preload: :tags
    ])
  end

  def agent_observations(%{id: agent}, %{} = _page_opts, _info) do
    observations_filtered(%{agent: agent})
  end

  def agent_observations(_, _page_opts, _info) do
    {:ok, nil}
  end

  def agent_observations_edge(%{agent: agent}, %{} = page_opts, info) do
    ResolvePages.run(%ResolvePages{
      module: __MODULE__,
      fetcher: :fetch_agent_observations_edge,
      context: agent,
      page_opts: page_opts,
      info: info
    })
  end

  def fetch_agent_observations_edge(page_opts, info, ids) do
    list_observations(
      page_opts,
      [
        :default,
        agent_id: ids,
        user: GraphQL.current_user(info)
      ],
      nil,
      nil
    )
  end

  def list_observations(page_opts, base_filters, _data_filters, _cursor_type) do
    FetchPage.run(%FetchPage{
      queries: Queries,
      query: Observation,
      page_opts: page_opts,
      base_filters: base_filters
    })
  end

  def fetch_observations(page_opts, info) do
    FetchPage.run(%FetchPage{
      queries: ValueFlows.Observe.Observation.Queries,
      query: ValueFlows.Observe.Observation,
      page_opts: page_opts,
      cursor_fn:  & &1.id,
      base_filters: [
        :default,
        user: GraphQL.current_user(info)
      ]
    })
  end

  def has_result_edge(%{result_measure: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result}
  end
  def has_result_edge(%{result_phenomenon: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result |> ValueFlows.Observe.Classifications.from_classification()}
  end
  def has_result_edge(thing, _, _) do
    has_result_edge(repo.preload(thing, [:result_measure, :result_phenomenon]), nil, nil)
  end

  def has_feature_of_interest(%{has_observed_resource: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result}
  end
  def has_feature_of_interest(%{has_observed_agent: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result}
  end
  def has_feature_of_interest(_thing, _, _) do
    {:ok, nil}
  end

  def made_by_edge(%{made_by_resource_specification: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result}
  end
  def made_by_edge(%{made_by_resource: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result}
  end
  def made_by_edge(%{made_by_agent: %{id: id} = result} = _thing, _, _) when not is_nil(id) do
    {:ok, result}
  end
  def made_by_edge(%{made_by_sensor_id: id} = thing, _, _) when not is_nil(id) do
    made_by_edge(repo().preload(thing, [:made_by_resource_specification, :made_by_resource, :made_by_agent]), nil, nil)
  end
  def made_by_edge(_thing, _, _), do: {:ok, nil}




  # Mutations

  def create_observation(%{observation: observation_attrs} = params, info) do
    repo().transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
          #  {:ok, uploads} <- ValueFlows.Util.GraphQL.maybe_upload(user, observation_attrs, info),
           observation_attrs = observation_attrs
           |> Map.merge(%{is_public: true}),
          #  |> Map.merge(uploads),
           {:ok, observation} <- Observations.create(user, observation_attrs) do
        {:ok, observation}
      end
    end)
  end

  def update_observation(%{observation: %{id: id} = changes}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
         {:ok, observation} <- observation(%{id: id}, info),
         :ok <- ensure_update_permission(user, observation),
        #  {:ok, uploads} <- ValueFlows.Util.GraphQL.maybe_upload(user, changes, info),
        #  changes = Map.merge(changes, uploads),
         {:ok, observation} <- Observations.update(user, observation, changes) do
      {:ok, observation}
    end
  end

  def delete_observation(%{id: id}, info) do
    repo().transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, observation} <- observation(%{id: id}, info),
           :ok <- ensure_update_permission(user, observation),
           {:ok, _} <- Observations.soft_delete(observation) do
        {:ok, true}
      end
    end)
  end

  def ensure_update_permission(user, observation) do
    if ValueFlows.Util.is_admin(user) or observation.creator_id == user.id do
      :ok
    else
      GraphQL.not_permitted("update")
    end
  end

  # defp validate_agent(pointer) do
  #   if Pointers.table!(pointer).schema in valid_contexts() do
  #     :ok
  #   else
  #     GraphQL.not_permitted()
  #   end
  # end

  # defp valid_contexts() do
  #   [User, Community, Organisation]
  #   # Keyword.fetch!(Bonfire.Common.Config.get(Threads), :valid_contexts)
  # end

  def resolve_observable_object_type(_, _) do
    # TODO
    :economic_resource
  end

  def resolve_observable_result_type(%Bonfire.Quantify.Measure{}, _) do
    # TODO
    :measure
  end
  def resolve_observable_result_type(_item, _) do
    # IO.inspect(item)
    # TODO
    :observable_phenomenon
  end


  def resolve_observer_type(_, _) do
    # TODO
    :person
  end

  # def name_as_label(obj, _, _) do
  #   IO.inspect(obj)
  #   {:ok, "name"}
  # end
  def name_as_label(%{profile: %{name: name}} = _obj, _, _) do
    {:ok, name}
  end
  def name_as_label(%{name: name} = _obj, _, _) do
    {:ok, name}
  end

end
end
