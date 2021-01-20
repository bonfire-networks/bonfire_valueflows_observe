# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Test.Faking do
  @moduledoc false

  import ValueFlows.Observe.Simulate

  # import ExUnit.Assertions
  import Bonfire.GraphQL.Test.GraphQLAssertions
  import Bonfire.GraphQL.Test.GraphQLFields
  # import CommonsPub.Utils.Trendy

  import Grumble

  alias ValueFlows.Observe.Observation
  alias ValueFlows.Observe.Observations

  ## Observation

  ### Graphql fields

  def observation_subquery(options \\ []) do
    gen_subquery(:id, :observation, &observation_fields/1, options)
  end

  def observation_query(options \\ []) do
    options = Keyword.put_new(options, :id_type, :id)
    gen_query(:id, &observation_subquery/1, options)
  end

  def observation_fields(extra \\ []) do
    extra ++ ~w(id note)a
  end


  def observations_query(options \\ []) do
    params =
      [
        after: list_type(:cursor),
        before: list_type(:cursor),
        limit: :int
      ] ++ Keyword.get(options, :params, [])

    gen_query(&observations_subquery/1, [{:params, params} | options])
  end

  def observations_subquery(options \\ []) do
    args = [
      after: var(:after),
      before: var(:before),
      limit: var(:limit)
    ]

    page_subquery(
      :observations_pages,
      &observation_fields/1,
      [{:args, args} | options]
    )
  end

  def create_observation_mutation(options \\ []) do
    [observation: type!(:observation_create_params)]
    |> gen_mutation(&create_observation_submutation/1, options)
  end

  def create_observation_submutation(options \\ []) do
    [observation: var(:observation)]
    |> gen_submutation(:create_observation, &observation_fields/1, options)
  end

  def update_observation_mutation(options \\ []) do
    [observation: type!(:observation_update_params)]
    |> gen_mutation(&update_observation_submutation/1, options)
  end

  def update_observation_submutation(options \\ []) do
    [observation: var(:observation)]
    |> gen_submutation(:update_observation, &observation_fields/1, options)
  end

  def delete_observation_mutation(options \\ []) do
    [id: type!(:id)]
    |> gen_mutation(&delete_observation_submutation/1, options)
  end

  def delete_observation_submutation(_options \\ []) do
    field(:delete_observation, args: [id: var(:id)])
  end

  ### Observation assertion

  def assert_observation(observation) do
    assert_object(observation, :assert_observation,
      [id: &assert_ulid/1],
      [note: &assert_binary/1]
      # has_result_id: &assert_ulid/1
    )
  end

  def assert_observation(%Observation{} = observation, %{id: _} = obs2) do
    assert_observations_eq(observation, obs2)
  end

  def assert_observation(%Observation{} = observation, %{} = obs2) do
    assert_observations_eq(observation, assert_observation(obs2))
  end

  def assert_observations_eq(%Observation{} = observation, %{} = obs2) do
    assert_maps_eq(observation, obs2, :assert_observation, [:id, :note])
    obs2
  end


  ## ObservableProperties

  def observable_property_fields(extra \\ []) do
    extra ++ ~w(id label note)a
  end

  @doc """
  Same as `observable_property_fields/1`, but with the parameter being nested inside of
  another type.
  """
  def observable_property_response_fields(extra \\ []) do
    # [observable_property: observable_property_fields(extra)]
    observable_property_fields(extra)
  end

  def observable_property_subquery(options \\ []) do
    gen_subquery(:id, :observable_property, &observable_property_fields/1, options)
  end

  def observable_property_query(options \\ []) do
    options = Keyword.put_new(options, :id_type, :id)
    gen_query(:id, &observable_property_subquery/1, options)
  end

  def observable_properties_pages_query(options \\ []) do
    params =
      [
        after: list_type(:cursor),
        before: list_type(:cursor),
        limit: :int
      ] ++ Keyword.get(options, :params, [])

    gen_query(&observable_properties_pages_subquery/1, [{:params, params} | options])
  end

  def observable_properties_pages_subquery(options \\ []) do
    args = [
      after: var(:after),
      before: var(:before),
      limit: var(:limit)
    ]

    page_subquery(
      :observable_properties_pages,
      &observable_property_fields/1,
      [{:args, args} | options]
    )
  end


  def create_observable_property_mutation(options \\ []) do
    [observable_property: type!(:observable_property_create_params)]
    |> gen_mutation(&create_observable_property_submutation/1, options)
  end

  def create_observable_property_submutation(options \\ []) do
    [observable_property: var(:observable_property)]
    |> gen_submutation(:create_observable_property, &observable_property_response_fields/1, options)
  end

  def update_observable_property_mutation(options \\ []) do
    [observable_property: type!(:observable_property_update_params)]
    |> gen_mutation(&update_observable_property_submutation/1, options)
  end

  def update_observable_property_submutation(options \\ []) do
    [observable_property: var(:observable_property)]
    |> gen_submutation(:update_observable_property, &observable_property_response_fields/1, options)
  end

  def delete_observable_property_mutation(options \\ []) do
    [id: type!(:id)]
    |> gen_mutation(&delete_observable_property_submutation/1, options)
  end

  def delete_observable_property_submutation(_options \\ []) do
    field(:delete_observable_property, args: [id: var(:id)])
  end


  def assert_observable_property(%{__struct__: _type} = observable_property) do
    assert_observable_property(Map.from_struct(observable_property))
  end

  def assert_observable_property(observable_property) do
    assert_object(observable_property, :assert_observable_property, label: &assert_binary/1)
  end

  def assert_observable_property(%{} = observable_property, %{} = observable_property2) do
    assert_observable_properties_eq(observable_property, assert_observable_property(observable_property2))
  end

  def assert_observable_properties_eq(%{} = observable_property, %{} = observable_property2) do
    assert_maps_eq(observable_property, observable_property2, :assert_observable_property, [
      :label,
      :published_at,
      :disabled_at
    ])
  end


  ## ObservablePhenomenons

  def observable_phenomenon_fields(extra \\ []) do
    extra ++ ~w(id formula_quantifier)a
  end

  @doc """
  Same as `observable_phenomenon_fields/1`, but with the parameter being nested inside of
  another type.
  """
  def observable_phenomenon_response_fields(extra \\ []) do
    # [observable_phenomenon: observable_phenomenon_fields(extra)]
    observable_phenomenon_fields(extra)
  end

  def observable_phenomenon_subquery(options \\ []) do
    gen_subquery(:id, :observable_phenomenon, &observable_phenomenon_fields/1, options)
  end

  def observable_phenomenon_query(options \\ []) do
    options = Keyword.put_new(options, :id_type, :id)
    gen_query(:id, &observable_phenomenon_subquery/1, options)
  end

  def observable_phenomenon_pages_query(options \\ []) do
    params =
      [
        after: list_type(:cursor),
        before: list_type(:cursor),
        limit: :int
      ] ++ Keyword.get(options, :params, [])

    gen_query(&observable_phenomenon_pages_subquery/1, [{:params, params} | options])
  end

  def observable_phenomenon_pages_subquery(options \\ []) do
    args = [
      after: var(:after),
      before: var(:before),
      limit: var(:limit)
    ]

    page_subquery(
      :observable_phenomenon_pages,
      &observable_phenomenon_fields/1,
      [{:args, args} | options]
    )
  end


  def create_observable_phenomenon_mutation(options \\ []) do
    [observable_phenomenon: type!(:observable_phenomenon_create_params)]
    |> gen_mutation(&create_observable_phenomenon_submutation/1, options)
  end

  def create_observable_phenomenon_submutation(options \\ []) do
    [observable_phenomenon: var(:observable_phenomenon)]
    |> gen_submutation(:create_observable_phenomenon, &observable_phenomenon_response_fields/1, options)
  end

  def create_observable_phenomenon_with_property_mutation(options \\ []) do
    [observable_phenomenon: type!(:observable_phenomenon_create_params), choice_of: type!(:id)]
    |> gen_mutation(&create_observable_phenomenon_with_property_submutation/1, options)
  end

  def create_observable_phenomenon_with_property_submutation(options \\ []) do
    [observable_phenomenon: var(:observable_phenomenon), choice_of: var(:choice_of)]
    |> gen_submutation(:create_observable_phenomenon, &observable_phenomenon_response_fields/1, options)
  end

  def update_observable_phenomenon_mutation(options \\ []) do
    [observable_phenomenon: type!(:observable_phenomenon_update_params)]
    |> gen_mutation(&update_observable_phenomenon_submutation/1, options)
  end

  def update_observable_phenomenon_submutation(options \\ []) do
    [observable_phenomenon: var(:observable_phenomenon)]
    |> gen_submutation(:update_observable_phenomenon, &observable_phenomenon_response_fields/1, options)
  end

  def delete_observable_phenomenon_mutation(options \\ []) do
    [id: type!(:id)]
    |> gen_mutation(&delete_observable_phenomenon_submutation/1, options)
  end

  def delete_observable_phenomenon_submutation(_options \\ []) do
    field(:delete_observable_phenomenon, args: [id: var(:id)])
  end

  def assert_observable_phenomenon(%{__struct__: _type} = observable_phenomenon) do
    assert_observable_phenomenon(Map.from_struct(observable_phenomenon))
  end

  def assert_observable_phenomenon(observable_phenomenon) do
    assert_object(observable_phenomenon, :assert_observable_phenomenon, formula_quantifier: &assert_float/1)
  end

  def assert_observable_phenomenon(%{} = observable_phenomenon, %{} = observable_phenomenon2) do
    assert_observable_phenomenons_eq(observable_phenomenon, assert_observable_phenomenon(observable_phenomenon2))
  end

  def assert_observable_phenomenons_eq(%{} = observable_phenomenon, %{} = observable_phenomenon2) do
    assert_maps_eq(observable_phenomenon, observable_phenomenon2, :assert_observable_phenomenon, [
      :label,
      :formula_quantifier,
      :published_at,
      :disabled_at
    ])
  end

end
