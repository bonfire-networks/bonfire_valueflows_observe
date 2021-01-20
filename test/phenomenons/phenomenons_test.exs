# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.PhenomenonsTest do
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
  alias ValueFlows.Observe.ObservablePhenomenons

  describe "one" do
    test "fetches an existing observable_phenomenon" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)
      observable_phenomenon = fake_observable_phenomenon!(user, observable_property)

      assert {:ok, fetched} = ObservablePhenomenons.one(id: observable_phenomenon.id)
      assert_observable_phenomenon(observable_phenomenon, fetched)
    end
  end

  describe "create" do
    test "creates a new observable_phenomenon" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)
      assert {:ok, observable_phenomenon} = ObservablePhenomenons.create(user, observable_property, observable_phenomenon())
      assert_observable_phenomenon(observable_phenomenon)
    end

    test "creates two ObservablePhenomenons with the same attributes" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      attrs = observable_phenomenon()

      assert {:ok, measure1} = ObservablePhenomenons.create(user, observable_property, attrs)
      assert_observable_phenomenon(measure1)

      assert {:ok, measure2} = ObservablePhenomenons.create(user, observable_property, attrs)
      assert_observable_phenomenon(measure2)

    end

    test "fails when missing attributes" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)
      assert {:error, %Ecto.Changeset{}} = ObservablePhenomenons.create(user, observable_property, %{})
    end
  end

  describe "update" do
    test "updates an existing observable_phenomenon with new content" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)
      observable_phenomenon = fake_observable_phenomenon!(user, observable_property)

      attrs = observable_phenomenon()
      assert {:ok, updated} = ObservablePhenomenons.update(user, observable_phenomenon, attrs)
      assert_observable_phenomenon(updated)
      assert observable_phenomenon != updated
    end
  end
end
