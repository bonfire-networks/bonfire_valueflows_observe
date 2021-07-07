# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.PropertiesTest do
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
  alias ValueFlows.Observe.ObservableProperties

  describe "one" do
    test "fetches an existing observable_property" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      assert {:ok, fetched} = ObservableProperties.one(id: observable_property.id)
      assert_observable_property(observable_property, fetched)

    end
  end

  describe "create" do
    test "creates a new observable_property" do
      user = fake_user!()
      assert {:ok, observable_property} = ObservableProperties.create(user, observable_property())
      assert_observable_property(observable_property)
    end

    test "creates a new observable_property within the taxonomy" do
      ValueFlows.Observe.Seeds.up(nil) # requires seeds

      user = fake_user!()
      assert {:ok, observable_property} = ObservableProperties.create(user, observable_property())
      assert_observable_property(observable_property)
      #IO.inspect(observable_property)
      assert observable_property.parent_category_id == ValueFlows.Observe.ObservableProperties.id()
    end

    test "creates two ObservableProperties with the same attributes" do
      user = fake_user!()

      attrs = observable_property()

      assert {:ok, measure1} = ObservableProperties.create(user, attrs)
      assert_observable_property(measure1)

      assert {:ok, measure2} = ObservableProperties.create(user, attrs)
      assert_observable_property(measure2)

    end

    test "fails when missing attributes" do
      user = fake_user!()
      assert {:error, %Ecto.Changeset{}} = ObservableProperties.create(user, %{})
    end
  end

  describe "update" do
    test "updates an existing observable_property with new content" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      attrs = observable_property()
      assert {:ok, updated} = ObservableProperties.update(user, observable_property, attrs)
      assert_observable_property(updated)
      assert observable_property != updated
    end
  end
end
