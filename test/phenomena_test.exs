# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.MeasuresTest do
  use ValueFlows.Observe.ConnCase, async: true

  # import CommonsPub.Utils.Trendy
  import Bonfire.Common.Simulation
  # import CommonsPub.Utils.Simulate
  # import CommonsPub.Web.Test.Orderings
  # import CommonsPub.Web.Test.Automaton
  # import Bonfire.GraphQL.Test.GraphQLAssertions
  # import Bonfire.Common.Enums
  # import Grumble
  # import Zest

  import ValueFlows.Observe.Test.Faking
  import ValueFlows.Observe.Simulate
  # alias ValueFlows.Observe.ObservablePhenomenon
  alias ValueFlows.Observe.Measures

  describe "one" do
    test "fetches an existing observable_phenomenon" do
      user = fake_user!()
      observation = fake_observation!(user)
      observable_phenomenon = fake_observable_phenomenon!(user, observation)

      assert {:ok, fetched} = Measures.one(id: observable_phenomenon.id)
      assert_observable_phenomenon(observable_phenomenon, fetched)
      assert {:ok, fetched} = Measures.one(user: user)
      assert_observable_phenomenon(observable_phenomenon, fetched)
    end
  end

  describe "create" do
    test "creates a new observable_phenomenon" do
      user = fake_user!()
      observation = fake_observation!(user)
      assert {:ok, observable_phenomenon} = Measures.create(user, observation, observable_phenomenon())
      assert_observable_phenomenon(observable_phenomenon)
    end

    test "creates two measures with the same attributes" do
      user = fake_user!()
      observation = fake_observation!(user)
      attrs = observable_phenomenon()
      assert {:ok, measure1} = Measures.create(user, observation, attrs)
      assert_observable_phenomenon(measure1)
      assert {:ok, measure2} = Measures.create(user, observation, attrs)
      assert_observable_phenomenon(measure2)
      assert measure1.unit_id == measure2.unit_id
      assert measure1.has_numerical_value == measure2.has_numerical_value
      assert measure1.id != measure2.id # TODO: should we re-use the same measurement instead of storing duplicates? (but would have to be careful to insert a new measurement rather than update)
    end

    test "fails when missing attributes" do
      user = fake_user!()
      observation = fake_observation!(user)
      assert {:error, %Ecto.Changeset{}} = Measures.create(user, observation, %{})
    end
  end

  describe "update" do
    test "updates an existing observable_phenomenon with new content" do
      user = fake_user!()
      observation = fake_observation!(user)
      observable_phenomenon = fake_observable_phenomenon!(user, observation)

      attrs = observable_phenomenon()
      assert {:ok, updated} = Measures.update(observable_phenomenon, attrs)
      assert_observable_phenomenon(updated)
      assert observable_phenomenon != updated
    end
  end
end
