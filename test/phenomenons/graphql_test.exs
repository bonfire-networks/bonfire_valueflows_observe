# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Phenomenons.GraphQLTest do
  use ValueFlows.Observe.ConnCase, async: true

  import Bonfire.Common.Simulation
  import ValueFlows.Observe.Simulate
  import ValueFlows.Observe.Test.Faking
  # import CommonsPub.Utils.Trendy

  alias ValueFlows.Observe.Observations


  describe "observable_phenomenon" do

    test "fetches an existing observable_phenomenon by ID" do
      user = fake_user!()
      observable_phenomenon = fake_observable_phenomenon!(user)

      q = observable_phenomenon_query()
      conn = user_conn(user)
      assert_observable_phenomenon(grumble_post_key(q, conn, :observable_phenomenon, %{id: observable_phenomenon.id}))
    end

    test "creates a new observable_phenomenon" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)

      q = create_observable_phenomenon_mutation()
      conn = user_conn(user)
      vars = %{observable_phenomenon: observable_phenomenon_input(observable_property)}
      r = grumble_post_key(q, conn, :create_observable_phenomenon, vars) #|> IO.inspect()
      assert_observable_phenomenon(r)
    end

    test "updates an existing observable_phenomenon" do
      user = fake_user!()
      observable_property = fake_observable_property!(user)
      observable_phenomenon = fake_observable_phenomenon!(user, observable_property)

      q = update_observable_phenomenon_mutation()
      conn = user_conn(user)
      vars = %{observable_phenomenon: Map.put(observable_phenomenon_input(observable_property, %{"note"=> "updated"}), "id", observable_phenomenon.id)}
      r = grumble_post_key(q, conn, :update_observable_phenomenon, vars) #|> IO.inspect()
      assert_observable_phenomenon(r)
    end

    test "deletes an existing observable_phenomenon" do
      user = fake_user!()
      observable_phenomenon = fake_observable_phenomenon!(user)

      q = delete_observable_phenomenon_mutation()
      conn = user_conn(user)
      assert grumble_post_key(q, conn, :delete_observable_phenomenon, %{id: observable_phenomenon.id})
    end

    test "fetches a page of observable_phenomenons" do
      user = fake_user!()
      observable_phenomenons = some(5, fn -> fake_observable_phenomenon!(user) end)
      after_observable_phenomenon = List.first(observable_phenomenons)

      q = observable_phenomenon_pages_query()
      conn = user_conn(user)
      # vars = %{after: after_observable_phenomenon.id, limit: 2}
      vars = %{limit: 2}
      assert %{"edges" => fetched} = grumble_post_key(q, conn, :observable_phenomenon_pages, vars)
      assert Enum.count(fetched) == 2
      # assert List.first(fetched)["id"] == after_observable_phenomenon.id
    end

  end



end
