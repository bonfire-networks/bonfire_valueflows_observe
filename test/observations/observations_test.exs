# # SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.ObservationsTest do
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
  alias ValueFlows.Observe.Observations

  describe "one" do
    test "returns an item if it exists" do
      user = fake_user!(%{is_instance_admin: true})
      context = fake_user!()

      observation = fake_observation!(user, context)

      assert {:ok, fetched} = Observations.one(id: observation.id)
      assert_observation(observation, fetched)

      assert {:ok, fetched} = Observations.one(provider: user.id)
      assert_observation(observation, fetched)

      assert {:ok, fetched} = Observations.one(context: context.id)
      assert_observation(observation, fetched)
    end

    test "returns NotFound if item is missing" do
      assert {:error, :not_found} = Observations.one(id: uid())
    end

    test "returns NotFound if item is deleted" do
      observation = fake_observation!(fake_user!())
      assert {:ok, observation} = Observations.soft_delete(observation)

      assert {:error, :not_found} = Observations.one([:default, id: observation.id])
    end
  end

  describe "create" do
    test "new observation with a measure" do
      user = fake_user!()

      assert {:ok, observation = %Observation{}} =
               Observations.create(user, observation_with_req_fields(user))

      assert observation.creator_id == user.id
    end

    test "new observation with an observable phenomena" do
      user = fake_user!()
      phenon = fake_observable_phenomenon!(user)

      assert {:ok, observation = %Observation{}} =
               Observations.create(
                 user,
                 observation(
                   %{},
                   ValueFlows.Simulate.fake_economic_resource!(user),
                   fake_observable_property!(user),
                   phenon
                 )
               )

      assert observation.creator_id == user.id
      assert observation.has_result_id == phenon.id
    end
  end

  describe "create with context" do
    test "creates a new observation" do
      user = fake_user!()
      context = fake_user!()

      assert {:ok, observation = %Observation{}} =
               Observations.create(
                 user,
                 context,
                 observation_with_req_fields(user)
               )

      assert observation.creator_id == user.id
      assert observation.context_id == context.id
    end

    test "fails with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = Observations.create(fake_user!(), %{})
    end
  end

  describe "update" do
    test "updates a a observation" do
      user = fake_user!()
      context = fake_user!()
      observation = fake_observation!(user, context, %{note: "Bottle Caps"})

      assert {:ok, updated} = Observations.update(user, observation, %{note: "Rad"})

      assert observation != updated
    end
  end

  describe "soft_delete" do
    test "deletes an existing observation" do
      observation = fake_observation!(fake_user!())
      refute observation.deleted_at
      assert {:ok, deleted} = Observations.soft_delete(observation)
      assert deleted.deleted_at
    end
  end

  # describe "Observations" do

  #   test "works for a guest" do
  #     users = some_fake_users!(3)
  #     communities = some_fake_communities!(3, users) # 9
  #     Observations = some_fake_collections!(1, users, communities) # 27
  #     root_page_test %{
  #       query: observations_query(),
  #       connection: json_conn(),
  #       return_key: :Observations,
  #       default_limit: 10,
  #       total_count: 27,
  #       data: order_follower_count(Observations),
  #       assert_fn: &assert_observation/2,
  #       cursor_fn: &[&1.id],
  #       after: :collections_after,
  #       before: :collections_before,
  #       limit: :collections_limit,
  #     }
  #   end

  # end
end
