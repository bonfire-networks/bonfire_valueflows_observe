# check that this extension is configured
# Bonfire.Common.Config.require_extension_config!(:bonfire_valueflows_observe)

defmodule ValueFlows.Observe.Simulate do
  import Bonfire.Common.Simulation
  import ValueFlows.Simulate
  import Bonfire.Quantify.Simulate
  import Bonfire.Classify.Simulate

  alias ValueFlows.Observe.Observations
  alias ValueFlows.Observe.ObservableProperties
  alias ValueFlows.Observe.ObservablePhenomenons

  ### Start fake data functions

  ## Observation

  def observation(base \\ %{}, has_feature_of_interest \\ nil, observed_property \\ nil, has_result \\ nil) do
    base
    # |> Map.put_new_lazy(:label, &unit_name/0)
    # |> Map.put_new_lazy(:symbol, &unit_symbol/0)
    |> Map.put_new(:has_feature_of_interest, has_feature_of_interest)
    |> Map.put_new(:observed_property, observed_property)
    |> Map.put_new(:has_result, has_result)
    |> Map.put_new_lazy(:is_public, &truth/0)
    |> Map.put_new_lazy(:is_disabled, &falsehood/0)
    |> Map.put_new_lazy(:is_featured, &falsehood/0)
    # |> Map.merge(character(base))
    # |> IO.inspect()
  end

  def observation_with_req_fields(user, overrides \\ %{}) do
     observation(overrides, fake_economic_resource!(user), fake_observable_property!(user), fake_measure!(user))
  end

  def observation_input(user, base \\ %{}) do
    base
    |> Map.put_new(:has_feature_of_interest, fake_economic_resource!(user).id)
    |> Map.put_new(:observed_property, fake_observable_property!(user).id)
    |> Map.put_new(:result_measure, measure_input(fake_unit!(user)))
  end

  def fake_observation!(user, context \\ nil, overrides \\ %{})

  def fake_observation!(user, context, overrides) when is_nil(context) do
    {:ok, observation} = Observations.create(user, observation_with_req_fields(user, overrides))
    observation
  end

  def fake_observation!(user, context, overrides) do
    {:ok, observation} = Observations.create(user, context, observation_with_req_fields(user, overrides))
    observation
  end


  ## ObservableProperties

  def observable_property(overrides \\ %{}) do
    overrides
    |> Map.put_new_lazy(:label, &name/0)
  end

  def observable_property_input(overrides \\ %{}) do
    overrides
    |> Map.put_new_lazy("label", &name/0)
  end

  def fake_observable_property!(user, overrides \\ %{}) do
    {:ok, observable_property} = ObservableProperties.create(user, observable_property(overrides))
    observable_property
  end


  ## ObservablePhenomenons

  def observable_phenomenon(overrides \\ %{}) do
    overrides
    |> Map.put_new_lazy(:label, &name/0)
    |> Map.put_new_lazy(:formula_quantifier, &float/0)
  end

  def observable_phenomenon_input(observable_property \\ nil, overrides \\ %{}) do
    overrides = overrides
      |> Map.put_new_lazy("label", &name/0)
      |> Map.put_new_lazy("formulaQuantifier", &float/0)

    if is_nil(observable_property) do
      overrides
    else
      Map.put_new(overrides, "choiceOf", observable_property.id)
    end
  end

  def fake_observable_phenomenon!(user, observable_property \\ nil, overrides \\ %{})

  def fake_observable_phenomenon!(user, nil, overrides) do
    fake_observable_phenomenon!(user, fake_observable_property!(user), overrides)
  end

  def fake_observable_phenomenon!(user, observable_property, overrides) do
    {:ok, observable_phenomenon} = ObservablePhenomenons.create(user, observable_property, observable_phenomenon(overrides))
    observable_phenomenon
  end
end
