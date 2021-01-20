# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Observations.GraphQLTest do
  use ValueFlows.Observe.ConnCase, async: true

  import Bonfire.Common.Simulation
  import ValueFlows.Observe.Simulate
  import ValueFlows.Observe.Test.Faking
  # import CommonsPub.Utils.Trendy

  alias ValueFlows.Observe.Observations

  describe "observation" do
    test "fetches an existing observation by ID" do
      user = fake_user!()
      observation = fake_observation!(user)

      q = observation_query()
      conn = user_conn(user)
      assert_observation(grumble_post_key(q, conn, :observation, %{id: observation.id}))
    end

    test "fails for deleted observations" do
      user = fake_user!()
      observation = fake_observation!(user)
      assert {:ok, observation} = Observations.soft_delete(observation)

      q = observation_query()
      conn = user_conn(user)
      assert [%{"status" => 404}] = grumble_post_errors(q, conn, %{id: observation.id})
    end

    test "fails if ID is missing" do
      user = fake_user!()
      q = observation_query()
      conn = user_conn(user)
      vars = %{id: Pointers.ULID.generate()}
      assert [%{"status" => 404}] = grumble_post_errors(q, conn, vars)
    end
  end

  describe "observationsPages" do
    test "fetches a page of observations" do
      user = fake_user!()
      observations = some(5, fn -> fake_observation!(user) end)
      after_observation = List.first(observations)

      q = observations_query()
      conn = user_conn(user)
      vars = %{after: after_observation.id, limit: 2}
      assert %{"edges" => fetched} = grumble_post_key(q, conn, :observations_pages, vars)
      assert Enum.count(fetched) == 2
      assert List.first(fetched)["id"] == after_observation.id
    end
  end

  describe "create_observation" do
    test "creates a new observation given valid attributes" do
      user = fake_user!()

      q = create_observation_mutation()
      conn = user_conn(user)
      vars = %{observation: observation_input()}
      r = grumble_post_key(q, conn, :create_observation, vars) #|> IO.inspect()
      assert_observation(r)
    end

    test "creates a new observation with a scope" do
      user = fake_user!()
      context = fake_user!()

      q = create_observation_mutation(fields: [in_scope_of: [:__typename]])
      conn = user_conn(user)
      vars = %{observation: Map.put(observation_input(), :in_scope_of, context.id)}
      r = grumble_post_key(q, conn, :create_observation, vars) #|> IO.inspect()
      assert_observation(r)
    end
  end

  describe "update_observation" do
    test "updates an existing observation" do
      user = fake_user!()
      observation = fake_observation!(user)

      q = update_observation_mutation()
      conn = user_conn(user)
      vars = %{observation: Map.put(observation_input(), "id", observation.id)}
      r = grumble_post_key(q, conn, :update_observation, vars) #|> IO.inspect()
      assert_observation(r)
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

  end


end
