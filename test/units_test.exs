# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.UnitsTest do
  use ValueFlows.Observe.ConnCase, async: true

  import ValueFlows.Observe.Test.Faking

  # import CommonsPub.Utils.Trendy
  import Bonfire.Common.Simulation
  # import CommonsPub.Utils.Simulate
  # import CommonsPub.Web.Test.Orderings
  # import CommonsPub.Web.Test.Automaton

  # import Grumble
  # import Zest

  # alias CommonsPub.Utils.Simulation

  import ValueFlows.Observe.Simulate
  alias ValueFlows.Observe.Observation
  alias ValueFlows.Observe.Units

  describe "one" do
    test "returns an item if it exists" do
      user = fake_user!(%{is_instance_admin: true})
      context = fake_user!()
      observation = fake_observation!(user, context)

      assert {:ok, fetched} = Units.one(id: observation.id)
      assert_observation(observation, fetched)
      assert {:ok, fetched} = Units.one(user: user)
      assert_observation(observation, fetched)
      assert {:ok, fetched} = Units.one(context_id: context.id)
      assert_observation(observation, fetched)
    end

    test "returns NotFound if item is missing" do
      assert {:error, :not_found} = Units.one(id: ulid())
    end

    test "returns NotFound if item is deleted" do
      observation = fake_user!() |> fake_observation!()
      assert {:ok, observation} = Units.soft_delete(observation)
      assert {:error, :not_found} = Units.one([:default, id: observation.id])
    end
  end

  describe "create without context" do
    test "creates a new observation" do
      user = fake_user!()
      assert {:ok, observation = %Observation{}} = Units.create(user, observation())
      assert observation.creator_id == user.id
    end
  end

  describe "create with context" do
    test "creates a new observation" do
      user = fake_user!()
      context = fake_user!()

      assert {:ok, observation = %Observation{}} = Units.create(user, context, observation())
      assert observation.creator_id == user.id
      assert observation.context_id == context.id
    end

    test "fails with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = Units.create(fake_user!(), %{})
    end
  end

  describe "update" do
    test "updates a a observation" do
      user = fake_user!()
      context = fake_user!()
      observation = fake_observation!(user, context, %{label: "Bottle Caps", symbol: "C"})
      assert {:ok, updated} = Units.update(observation, %{label: "Rad", symbol: "rad"})
      assert observation != updated
    end
  end

  describe "soft_delete" do
    test "deletes an existing observation" do
      observation = fake_user!() |> fake_observation!()
      refute observation.deleted_at
      assert {:ok, deleted} = Units.soft_delete(observation)
      assert deleted.deleted_at
    end
  end

  # describe "units" do

  #   test "works for a guest" do
  #     users = some_fake_users!(3)
  #     communities = some_fake_communities!(3, users) # 9
  #     units = some_fake_collections!(1, users, communities) # 27
  #     root_page_test %{
  #       query: units_query(),
  #       connection: json_conn(),
  #       return_key: :units,
  #       default_limit: 10,
  #       total_count: 27,
  #       data: order_follower_count(units),
  #       assert_fn: &assert_observation/2,
  #       cursor_fn: &[&1.id],
  #       after: :collections_after,
  #       before: :collections_before,
  #       limit: :collections_limit,
  #     }
  #   end

  # end
end
