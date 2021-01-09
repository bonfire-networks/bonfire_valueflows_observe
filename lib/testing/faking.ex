# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Test.Faking do
  @moduledoc false

  import ValueFlows.Observe.Simulate

  # import ExUnit.Assertions
  import Bonfire.GraphQL.Test.GraphQLAssertions
  import Bonfire.GraphQL.Test.GraphQLFields
  # import CommonsPub.Utils.Trendy

  import Grumble

  alias ValueFlows.Observe.{ObservablePhenomenon, Observation}
  # alias ValueFlows.Observe.Measures
  # alias ValueFlows.Observe.Units

  ## Observation

  ### Graphql fields

  def unit_subquery(options \\ []) do
    gen_subquery(:id, :observation, &unit_fields/1, options)
  end

  def unit_query(options \\ []) do
    options = Keyword.put_new(options, :id_type, :id)
    gen_query(:id, &unit_subquery/1, options)
  end

  def unit_fields(extra \\ []) do
    extra ++ ~w(id label symbol)a
  end

  @doc """
  Same as `unit_fields/1`, but with the parameter being nested inside of
  another type.
  """
  def unit_response_fields(extra \\ []) do
    [observation: unit_fields(extra)]
  end

  def units_query(options \\ []) do
    params =
      [
        after: list_type(:cursor),
        before: list_type(:cursor),
        limit: :int
      ] ++ Keyword.get(options, :params, [])

    gen_query(&units_subquery/1, [{:params, params} | options])
  end

  def units_subquery(options \\ []) do
    args = [
      after: var(:after),
      before: var(:before),
      limit: var(:limit)
    ]

    page_subquery(
      :units_pages,
      &unit_fields/1,
      [{:args, args} | options]
    )
  end

  def create_observation_mutation(options \\ []) do
    [observation: type!(:unit_create_params)]
    |> gen_mutation(&create_observation_submutation/1, options)
  end

  def create_observation_submutation(options \\ []) do
    [observation: var(:observation)]
    |> gen_submutation(:create_observation, &unit_response_fields/1, options)
  end

  def update_observation_mutation(options \\ []) do
    [observation: type!(:unit_update_params)]
    |> gen_mutation(&update_observation_submutation/1, options)
  end

  def update_observation_submutation(options \\ []) do
    [observation: var(:observation)]
    |> gen_submutation(:update_observation, &unit_response_fields/1, options)
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
      id: &assert_ulid/1,
      label: &assert_binary/1,
      symbol: &assert_binary/1
    )
  end

  def assert_observation(%Observation{} = observation, %{id: _} = unit2) do
    assert_observations_eq(observation, unit2)
  end

  def assert_observation(%Observation{} = observation, %{} = unit2) do
    assert_observations_eq(observation, assert_observation(unit2))
  end

  def assert_observations_eq(%Observation{} = observation, %{} = unit2) do
    assert_maps_eq(observation, unit2, :assert_observation, [:id, :label, :symbol])
    unit2
  end

  # def some_fake_observations!(opts \\ %{}, some_arg, users, communities) do
  #   flat_pam_product_some(users, communities, some_arg, &fake_observation!(&1, &2, opts))
  # end

  ## Measures

  def measure_fields(extra \\ []) do
    extra ++ ~w(id has_numerical_value)a
  end

  @doc """
  Same as `measure_fields/1`, but with the parameter being nested inside of
  another type.
  """
  def measure_response_fields(extra \\ []) do
    [observable_phenomenon: measure_fields(extra)]
  end

  def measure_subquery(options \\ []) do
    gen_subquery(:id, :observable_phenomenon, &measure_fields/1, options)
  end

  def measure_query(options \\ []) do
    options = Keyword.put_new(options, :id_type, :id)
    gen_query(:id, &measure_subquery/1, options)
  end

  def measures_pages_query(options \\ []) do
    params =
      [
        after: list_type(:cursor),
        before: list_type(:cursor),
        limit: :int
      ] ++ Keyword.get(options, :params, [])

    gen_query(&measures_pages_subquery/1, [{:params, params} | options])
  end

  def measures_pages_subquery(options \\ []) do
    args = [
      after: var(:after),
      before: var(:before),
      limit: var(:limit)
    ]

    page_subquery(
      :measures_pages,
      &measure_fields/1,
      [{:args, args} | options]
    )
  end


  def create_observable_phenomenon_mutation(options \\ []) do
    [observable_phenomenon: type!(:measure_create_params)]
    |> gen_mutation(&create_observable_phenomenon_submutation/1, options)
  end

  def create_observable_phenomenon_submutation(options \\ []) do
    [observable_phenomenon: var(:observable_phenomenon)]
    |> gen_submutation(:create_observable_phenomenon, &measure_response_fields/1, options)
  end

  def create_observable_phenomenon_with_observation_mutation(options \\ []) do
    [observable_phenomenon: type!(:measure_create_params), has_observation: type!(:id)]
    |> gen_mutation(&create_observable_phenomenon_with_observation_submutation/1, options)
  end

  def create_observable_phenomenon_with_observation_submutation(options \\ []) do
    [observable_phenomenon: var(:observable_phenomenon), has_observation: var(:has_observation)]
    |> gen_submutation(:create_observable_phenomenon, &measure_response_fields/1, options)
  end

  def update_observable_phenomenon_mutation(options \\ []) do
    [observable_phenomenon: type!(:measure_update_params)]
    |> gen_mutation(&update_observable_phenomenon_submutation/1, options)
  end

  def update_observable_phenomenon_submutation(options \\ []) do
    [observable_phenomenon: var(:observable_phenomenon)]
    |> gen_submutation(:update_observable_phenomenon, &measure_response_fields/1, options)
  end

  def assert_observable_phenomenon(%ObservablePhenomenon{} = observable_phenomenon) do
    assert_observable_phenomenon(Map.from_struct(observable_phenomenon))
  end

  def assert_observable_phenomenon(observable_phenomenon) do
    assert_object(observable_phenomenon, :assert_observable_phenomenon, has_numerical_value: &assert_float/1)
  end

  def assert_observable_phenomenon(%ObservablePhenomenon{} = observable_phenomenon, %{} = measure2) do
    assert_observable_phenomenons_eq(observable_phenomenon, assert_observable_phenomenon(measure2))
  end

  def assert_observable_phenomenons_eq(%ObservablePhenomenon{} = observable_phenomenon, %{} = measure2) do
    assert_maps_eq(observable_phenomenon, measure2, :assert_observable_phenomenon, [
      :has_numerical_value,
      :published_at,
      :disabled_at
    ])
  end
end
