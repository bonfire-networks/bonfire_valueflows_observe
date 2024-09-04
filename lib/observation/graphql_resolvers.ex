# SPDX-License-Identifier: AGPL-3.0-only
if Code.ensure_loaded?(Bonfire.API.GraphQL) do
  defmodule ValueFlows.Observe.Observations.ObservationsResolvers do
    # default to 100 km radius
    @radius_default_distance 100_000

    import Untangle

    import Bonfire.Common.Config, only: [repo: 0]

    alias Bonfire.API.GraphQL

    alias Bonfire.API.GraphQL.ResolveField
    alias Bonfire.API.GraphQL.ResolvePages
    alias Bonfire.API.GraphQL.ResolveRootPage
    alias Bonfire.API.GraphQL.FetchPage

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
      # IO.inspect(page_opts)
      ResolveRootPage.run(%ResolveRootPage{
        module: __MODULE__,
        fetcher: :fetch_observations,
        page_opts: page_opts,
        info: info,
        # popularity
        cursor_validators: [
          &(is_integer(&1) and &1 >= 0),
          &Needle.UID.cast/1
        ]
      })
    end

    def all_observations(_, _) do
      Observations.many([:default])
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
        cursor_fn: & &1.id,
        base_filters: [
          :default,
          user: GraphQL.current_user(info)
        ],
        data_filters: ValueFlows.Util.GraphQL.fetch_data_filters(info)
      })
    end

    def has_result_edge(%{result_measure: %{id: id} = result} = _thing, _, _)
        when not is_nil(id) do
      {:ok, result}
    end

    def has_result_edge(%{result_phenomenon: %{id: id} = result} = _thing, _, _)
        when not is_nil(id) do
      {:ok, ValueFlows.Observe.Classifications.from_classification(result)}
    end

    def has_result_edge(thing, _, _) do
      has_result_edge(
        repo().preload(thing, [:result_measure, :result_phenomenon]),
        nil,
        nil
      )
    end

    def has_feature_of_interest(
          %{has_observed_resource: %{id: id} = result} = _thing,
          _,
          _
        )
        when not is_nil(id) do
      {:ok, result}
    end

    def has_feature_of_interest(
          %{has_observed_agent: %{id: id} = result} = _thing,
          _,
          _
        )
        when not is_nil(id) do
      {:ok, result}
    end

    def has_feature_of_interest(_thing, _, _) do
      {:ok, nil}
    end

    def made_by_edge(
          %{made_by_resource_specification: %{id: id} = result} = _thing,
          _,
          _
        )
        when not is_nil(id) do
      {:ok, result}
    end

    def made_by_edge(%{made_by_resource: %{id: id} = result} = _thing, _, _)
        when not is_nil(id) do
      {:ok, result}
    end

    def made_by_edge(%{made_by_agent: %{id: id} = result} = _thing, _, _)
        when not is_nil(id) do
      {:ok, result}
    end

    def made_by_edge(%{made_by_sensor_id: id} = thing, _, _)
        when not is_nil(id) do
      made_by_edge(
        repo().preload(thing, [
          :made_by_resource_specification,
          :made_by_resource,
          :made_by_agent
        ]),
        nil,
        nil
      )
    end

    def made_by_edge(_thing, _, _), do: {:ok, nil}

    # Mutations

    def create_observation(%{observation: observation_attrs} = params, info) do
      repo().transact_with(fn ->
        with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
             #  {:ok, uploads} <- ValueFlows.Util.GraphQL.maybe_upload(user, observation_attrs, info),
             observation_attrs = Map.merge(observation_attrs, %{is_public: true}),
             #  |> Map.merge(uploads),
             {:ok, observation} <- Observations.create(user, observation_attrs) do
          {:ok, observation}
        end
      end)
    end

    def update_observation(%{observation: %{id: id} = changes}, info) do
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, observation} <- observation(%{id: id}, info),
           :ok <- ValueFlows.Util.can?(user, observation),
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
             :ok <- ValueFlows.Util.can?(user, :delete, observation),
             {:ok, _} <- Observations.soft_delete(observation) do
          {:ok, true}
        end
      end)
    end

    # defp validate_agent(pointer) do
    #   if Needle.Pointers.table!(pointer).schema in valid_contexts() do
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
