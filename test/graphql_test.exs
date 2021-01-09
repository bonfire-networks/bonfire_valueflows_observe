# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.GraphQLTest do
  use ValueFlows.Observe.ConnCase, async: true

  import Bonfire.Common.Simulation
  # import CommonsPub.Utils.Simulate
  import ValueFlows.Observe.Test.Faking
  # import CommonsPub.Utils.Trendy

  import ValueFlows.Observe.Simulate
  # alias ValueFlows.Observe.Measures
  alias ValueFlows.Observe.Units

  describe "observation" do
    test "fetches an existing observation by ID" do
      user = fake_user!()
      observation = fake_observation!(user)

      q = unit_query()
      conn = user_conn(user)
      assert_observation(grumble_post_key(q, conn, :observation, %{id: observation.id}))
    end

    test "fails for deleted units" do
      user = fake_user!()
      observation = fake_observation!(user)
      assert {:ok, observation} = Units.soft_delete(observation)

      q = unit_query()
      conn = user_conn(user)
      assert [%{"status" => 404}] = grumble_post_errors(q, conn, %{id: observation.id})
    end

    test "fails if ID is missing" do
      user = fake_user!()
      q = unit_query()
      conn = user_conn(user)
      vars = %{id: Pointers.ULID.generate()}
      assert [%{"status" => 404}] = grumble_post_errors(q, conn, vars)
    end
  end

  describe "unitsPages" do
    test "fetches a page of units" do
      user = fake_user!()
      units = some(5, fn -> fake_observation!(user) end)
      after_observation = List.first(units)

      q = units_query()
      conn = user_conn(user)
      vars = %{after: after_observation.id, limit: 2}
      assert %{"edges" => fetched} = grumble_post_key(q, conn, :units_pages, vars)
      assert Enum.count(fetched) == 2
      assert List.first(fetched)["id"] == after_observation.id
    end
  end

  describe "create_observation" do
    test "creates a new observation given valid attributes" do
      user = fake_user!()

      q = create_observation_mutation()
      conn = user_conn(user)
      vars = %{observation: unit_input()}
      assert_observation(grumble_post_key(q, conn, :create_observation, vars)["observation"])
    end

    test "creates a new observation with a scope" do
      user = fake_user!()
      context = fake_user!()

      IO.inspect(Pointers.Tables.data(), limit: :infinity)

      q = create_observation_mutation(fields: [in_scope_of: [:__typename]])
      conn = user_conn(user)
      vars = %{observation: Map.put(unit_input(), :in_scope_of, context.id)}
      assert_observation(grumble_post_key(q, conn, :create_observation, vars)["observation"])
    end
  end

  describe "update_observation" do
    test "updates an existing observation" do
      user = fake_user!()
      observation = fake_observation!(user)

      q = update_observation_mutation()
      conn = user_conn(user)
      vars = %{observation: Map.put(unit_input(), "id", observation.id)}
      assert_observation(grumble_post_key(q, conn, :update_observation, vars)["observation"])
    end
  end

  describe "delete_observation" do
    test "deletes an existing observation" do
      user = fake_user!()
      observation = fake_observation!(user)

      q = delete_observation_mutation()
      conn = user_conn(user)
      assert grumble_post_key(q, conn, :delete_observation, %{id: observation.id})
    end

    test "fails to delete a observation if it has dependent measures" do
      user = fake_user!()
      observation = fake_observation!(user)
      _observable_phenomenons = some(5, fn -> fake_observable_phenomenon!(user, observation) end)

      q = delete_observation_mutation()
      conn = user_conn(user)
      assert [%{"status" => 403}] = grumble_post_errors(q, conn, %{id: observation.id})
    end
  end

  describe "observable_phenomenon" do
    test "fetches an existing observable_phenomenon by ID" do
      user = fake_user!()
      observation = fake_observation!(user)
      observable_phenomenon = fake_observable_phenomenon!(user, observation)

      q = measure_query()
      conn = user_conn(user)
      assert_observable_phenomenon(grumble_post_key(q, conn, :observable_phenomenon, %{id: observable_phenomenon.id}))
    end
  end

  describe "measuresPages" do
    test "fetches a page of measures" do
      user = fake_user!()
      observation = fake_observation!(user)
      measures = some(5, fn -> fake_observable_phenomenon!(user, observation) end)
      after_observable_phenomenon = List.first(measures)

      q = measures_pages_query()
      conn = user_conn(user)
      vars = %{after: after_observable_phenomenon.id, limit: 2}
      assert %{"edges" => fetched} = grumble_post_key(q, conn, :measures_pages, vars)
      assert Enum.count(fetched) == 2
      assert List.first(fetched)["id"] == after_observable_phenomenon.id
    end
  end

end
