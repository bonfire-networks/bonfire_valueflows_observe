# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Observation.Queries do
  alias ValueFlows.Observe.Observation
  # alias ValueFlows.Observe.Observations
  @user Application.compile_env!(:bonfire, :user_schema)
  import Bonfire.Common.Repo.Utils, only: [match_admin: 0]
  import Ecto.Query
  import Geo.PostGIS

  def query(Observation) do
    from(c in Observation, as: :observation)
  end

  def query(:count) do
    from(c in Observation, as: :observation)
  end

  def query(filters), do: query(Observation, filters)

  def query(q, filters), do: filter(query(q), filters)

  def queries(query, _page_opts, base_filters, data_filters, count_filters) do
    base_q = query(query, base_filters)
    data_q = filter(base_q, data_filters)
    count_q = filter(base_q, count_filters)
    {data_q, count_q}
  end

  def join_to(q, spec, join_qualifier \\ :left)

  def join_to(q, specs, jq) when is_list(specs) do
    Enum.reduce(specs, q, &join_to(&2, &1, jq))
  end

  def join_to(q, :context, jq) do
    join(q, jq, [observation: c], c2 in assoc(c, :context), as: :context)
  end

  def join_to(q, :tags, jq) do
    join(q, jq, [observation: c], t in assoc(c, :tags), as: :tags)
  end

  def join_to(q, :has_feature_of_interest, jq) do
    q
    # |> join(jq, [observation: c], t in assoc(c, :has_feature_of_interest), as: :has_feature_of_interest)
    |> preload(:has_observed_resource)
    |> preload(:has_observed_agent)
  end

  def join_to(q, :observed_property, jq) do
    q
    # |> join(jq, [observation: c], t in assoc(c, :observed_property), as: :observed_property)
    |> preload([observed_property: [:profile]])
  end

  def join_to(q, :has_result, jq) do
    q
    # |> join(jq, [observation: c], t in assoc(c, :has_result), as: :has_result)
    # |> join(jq, [observation: c], m in assoc(c, :result_measure), as: :result_measure)
    # |> join(jq, [observation: c, result_measure: m], u in assoc(m, :unit), as: :unit)
    |> preload([result_measure: [:unit]])
  end

  # def join_to(q, :provider, jq) do
  #   join q, jq, [follow: f], c in assoc(f, :provider), as: :pointer
  # end


  # def join_to(q, :follower_count, jq) do
  #   join q, jq, [observation: c],
  #     f in FollowerCount, on: c.id == f.context_id,
  #     as: :follower_count
  # end

  ### filter/2

  ## by many

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by preset

  def filter(q, :default) do
    filter(q, [:deleted, :has_feature_of_interest, :observed_property, :has_result])
  end

  def filter(q, :has_feature_of_interest) do
    q
    |> join_to(:has_feature_of_interest)
  end

  def filter(q, :observed_property) do
    q
    |> join_to(:observed_property)
  end

  def filter(q, :has_result) do
    q
    |> join_to(:has_result)
  end

  ## by join

  def filter(q, {:join, {join, qual}}), do: join_to(q, join, qual)
  def filter(q, {:join, join}), do: join_to(q, join)

  ## by user

  def filter(q, {:user, match_admin()}), do: q

  def filter(q, {:user, nil}) do
    filter(q, ~w(disabled private)a)
  end


  def filter(q, {:user, %{id: user_id}}) do
    q
    |> where([observation: c], not is_nil(c.published_at) or c.creator_id == ^user_id)
    |> filter(~w(disabled)a)
  end
  ## by status

  def filter(q, :deleted) do
    where(q, [observation: c], is_nil(c.deleted_at))
  end

  def filter(q, :disabled) do
    where(q, [observation: c], is_nil(c.disabled_at))
  end

  def filter(q, :private) do
    where(q, [observation: c], not is_nil(c.published_at))
  end

  ## by field values

  def filter(q, {:cursor, [count, id]})
      when is_integer(count) and is_binary(id) do
    where(
      q,
      [observation: c, follower_count: fc],
      (fc.count == ^count and c.id >= ^id) or fc.count > ^count
    )
  end

  def filter(q, {:cursor, [count, id]})
      when is_integer(count) and is_binary(id) do
    where(
      q,
      [observation: c, follower_count: fc],
      (fc.count == ^count and c.id <= ^id) or fc.count < ^count
    )
  end

  def filter(q, {:id, id}) when is_binary(id) do
    where(q, [observation: c], c.id == ^id)
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where(q, [observation: c], c.id in ^ids)
  end

  def filter(q, {:context, id}) when is_binary(id) do
    where(q, [observation: c], c.context_id == ^id)
  end

  def filter(q, {:context, ids}) when is_list(ids) do
    where(q, [observation: c], c.context_id in ^ids)
  end

  def filter(q, {:agent, id}) when is_binary(id) do
    where(q, [observation: c], c.provider_id == ^id or c.creator_id == ^id or c.made_by_sensor_id == ^id)
  end

  def filter(q, {:agent, ids}) when is_list(ids) do
    where(q, [observation: c], c.provider_id in ^ids or c.creator_id in ^ids or c.made_by_sensor_id in ^ids)
  end

  def filter(q, {:provider, id}) when is_binary(id) do
    where(q, [observation: c], c.provider_id == ^id)
  end

  def filter(q, {:provider, ids}) when is_list(ids) do
    where(q, [observation: c], c.provider_id in ^ids)
  end


  def filter(q, {:at_location, at_location_id}) do
    q
    |> join_to(:geolocation)
    |> preload(:at_location)
    |> where([observation: c], c.at_location_id == ^at_location_id)
  end

  def filter(q, {:near_point, geom_point, :distance_meters, meters}) do
    q
    |> join_to(:geolocation)
    |> preload(:at_location)
    |> where([observation: c, geolocation: g], st_dwithin_in_meters(g.geom, ^geom_point, ^meters))
  end

  def filter(q, {:location_within, geom_point}) do
    q
    |> join_to(:geolocation)
    |> preload(:at_location)
    |> where([observation: c, geolocation: g], st_within(g.geom, ^geom_point))
  end

  def filter(q, {:tag_ids, ids}) when is_list(ids) do
    q
    |> preload(:tags)
    |> join_to(:tags)
    |> group_by([observation: c], c.id)
    |> having(
      [observation: c, tags: t],
      fragment("? <@ array_agg(?)", type(^ids, {:array, Pointers.ULID}), t.id)
    )
  end

  def filter(q, {:tag_ids, id}) when is_binary(id) do
    filter(q, {:tag_ids, [id]})
  end

  def filter(q, {:tag_id, id}) when is_binary(id) do
    filter(q, {:tag_ids, [id]})
  end

  def filter(q, {:has_feature_of_interest, ids}) when is_list(ids) do
    where(q, [observation: c], c.has_feature_of_interest_id in ^ids)
  end

  def filter(q, {:has_feature_of_interest, id}) when is_binary(id) do
    where(q, [observation: c], c.has_feature_of_interest_id == ^id)
  end

  def filter(q, {:made_by_sensor_id, ids}) when is_list(ids) do
    where(q, [observation: c], c.to_resource_inventoried_as_id in ^ids)
  end

  def filter(q, {:made_by_sensor_id, id}) when is_binary(id) do
    where(q, [observation: c], c.to_resource_inventoried_as_id == ^id)
  end

  def filter(q, {:observed_property, id}) when is_binary(id) do
    where(q, [observation: c], c.observed_property_id == ^id)
  end

  def filter(q, {:observed_property, id}) when is_binary(id) do
    where(q, [observation: c], c.observed_property_id == ^id)
  end

  def filter(q, {:observed_during, id}) when is_binary(id) do
    where(q, [observation: c], c.observed_during_id == ^id)
  end

  def filter(q, {:observed_during, id}) when is_binary(id) do
    where(q, [observation: c], c.observed_during_id == ^id)
  end

  ## by ordering

  def filter(q, {:order, :id}) do
    filter(q, order: [desc: :id])
  end

  def filter(q, {:order, [desc: :id]}) do
    order_by(q, [observation: c],
      desc: c.id
    )
  end

  # grouping and counting

  def filter(q, {:group_count, key}) when is_atom(key) do
    filter(q, group: key, count: key)
  end

  def filter(q, {:group, key}) when is_atom(key) do
    group_by(q, [observation: c], field(c, ^key))
  end

  def filter(q, {:count, key}) when is_atom(key) do
    select(q, [observation: c], {field(c, ^key), count(c.id)})
  end

  def filter(q, {:preload, :all}) do
    preload(q, [
      :context,
      :creator,
      # :has_feature_of_interest,
      # :observed_property,
      # :has_result,
      :at_location,
      :observed_during,
      :provider,
      :has_observed_resource,
      :has_observed_agent,
      [observed_property: [:profile]],
      [result_measure: [:unit]]
    ])
  end

  # pagination

  def filter(q, {:limit, limit}) do
    limit(q, ^limit)
  end

  def filter(q, {:paginate_id, %{after: a, limit: limit}}) do
    limit = limit + 2

    q
    |> where([observation: c], c.id >= ^a)
    |> limit(^limit)
  end

  def filter(q, {:paginate_id, %{before: b, limit: limit}}) do
    q
    |> where([observation: c], c.id <= ^b)
    |> filter(limit: limit + 2)
  end

  def filter(q, {:paginate_id, %{limit: limit}}) do
    filter(q, limit: limit + 1)
  end

  # def filter(q, {:page, [desc: [followers: page_opts]]}) do
  #   q
  #   |> filter(join: :follower_count, order: [desc: :followers])
  #   |> page(page_opts, [desc: :followers])
  #   |> select(
  #     [observation: c,  follower_count: fc],
  #     %{c | follower_count: coalesce(fc.count, 0)}
  #   )
  # end

  # defp page(q, %{after: cursor, limit: limit}, [desc: :followers]) do
  #   filter q, cursor: [followers: {:lte, cursor}], limit: limit + 2
  # end

  # defp page(q, %{before: cursor, limit: limit}, [desc: :followers]) do
  #   filter q, cursor: [followers: {:gte, cursor}], limit: limit + 2
  # end

  # defp page(q, %{limit: limit}, _), do: filter(q, limit: limit + 1)
end
