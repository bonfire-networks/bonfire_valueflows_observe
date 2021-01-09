# check that this extension is configured
Bonfire.Common.Config.require_extension_config!(:bonfire_valueflows_observe)

defmodule ValueFlows.Observe.Simulate do
  import Bonfire.Common.Simulation

  alias ValueFlows.Observe.Units
  alias ValueFlows.Observe.Measures

  ### Start fake data functions

  ## Observation

  def observation(base \\ %{}) do
    base
    |> Map.put_new_lazy(:label, &unit_name/0)
    |> Map.put_new_lazy(:symbol, &unit_symbol/0)
    |> Map.put_new_lazy(:is_public, &truth/0)
    |> Map.put_new_lazy(:is_disabled, &falsehood/0)
    |> Map.put_new_lazy(:is_featured, &falsehood/0)
    # |> Map.merge(character(base))
  end

  def unit_input(base \\ %{}) do
    base
    |> Map.put_new_lazy("label", &unit_name/0)
    |> Map.put_new_lazy("symbol", &unit_symbol/0)
  end

  def fake_observation!(user, context \\ nil, overrides \\ %{})

  def fake_observation!(user, context, overrides) when is_nil(context) do
    {:ok, observation} = Units.create(user, observation(overrides))
    observation
  end

  def fake_observation!(user, context, overrides) do
    {:ok, observation} = Units.create(user, context, observation(overrides))
    observation
  end

  ## Measures

  def observable_phenomenon(overrides \\ %{}) do
    overrides
    |> Map.put_new_lazy(:has_numerical_value, &float/0)
    |> Map.put_new_lazy(:is_public, &truth/0)
  end

  def measure_input(observation \\ nil, overrides \\ %{}) do
    overrides = Map.put_new_lazy(overrides, "hasNumericalValue", &:rand.uniform/0)

    if is_nil(observation) do
      overrides
    else
      Map.put_new(overrides, "hasUnit", observation.id)
    end
  end

  def fake_observable_phenomenon!(user, observation, overrides \\ %{}) do
    {:ok, observable_phenomenon} = Measures.create(user, observation, observable_phenomenon(overrides))
    observable_phenomenon
  end
end
