# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Properties.GraphQLTest do
  use ValueFlows.Observe.ConnCase, async: true

  import Bonfire.Common.Simulation
  import ValueFlows.Observe.Simulate
  import ValueFlows.Observe.Test.Faking
  # import CommonsPub.Utils.Trendy

  alias ValueFlows.Observe.Observations


  describe "observable_property" do

    test "fetches an existing observable_property by ID" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      q = observable_property_query()
      conn = user_conn(user)
      assert_observable_property(grumble_post_key(q, conn, :observable_property, %{id: observable_property.id}))
    end

    test "creates an observable property" do
      user = fake_user!()

      q = create_observable_property_mutation()
      conn = user_conn(user)
      vars = %{observable_property: observable_property_input()}
      r = grumble_post_key(q, conn, :create_observable_property, vars, "test", false) #|> IO.inspect()
      assert_observable_property(r)
    end

    test "updates an existing observable_property" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      q = update_observable_property_mutation()
      conn = user_conn(user)
      vars = %{observable_property: Map.put(observable_property_input(), "id", observable_property.id)}
      r = grumble_post_key(q, conn, :update_observable_property, vars, "test", false) #|> IO.inspect()
      assert_observable_property(r)
    end

    test "deletes an existing observable_property" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      q = delete_observable_property_mutation()
      conn = user_conn(user)
      assert grumble_post_key(q, conn, :delete_observable_property, %{id: observable_property.id})
    end

    test "fetches a page of observable_properties" do
      user = fake_user!()
      observable_properties = some(5, fn -> fake_observable_property!(user) end)
      after_observable_property = List.first(observable_properties)

      q = observable_properties_pages_query()
      conn = user_conn(user)
      # vars = %{after: after_observable_property.id, limit: 2}
      vars = %{limit: 2}
      assert %{"edges" => fetched} = grumble_post_key(q, conn, :observable_properties_pages, vars)
      assert Enum.count(fetched) == 2
      # assert List.first(fetched)["id"] == after_observable_property.id
    end

  end


end
