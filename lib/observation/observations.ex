# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Observations do
  use Bonfire.Common.Utils,
    only: [
      maybe: 2
    ]

  import Bonfire.Common.Config, only: [repo: 0]
  # alias Bonfire.API.GraphQL
  alias Bonfire.API.GraphQL.Fields
  alias Bonfire.API.GraphQL.Page

  @user Application.compile_env!(:bonfire, :user_schema)

  alias ValueFlows.Observe.Observation
  alias ValueFlows.Observe.EconomicResource.EconomicResources
  alias ValueFlows.Observe.Observation.Queries

  alias ValueFlows.Observe.Process.Processes

  import Bonfire.Fail

  import Untangle

  def cursor(), do: &[&1.id]
  def test_cursor(), do: &[&1["id"]]

  @doc """
  Retrieves a single one by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for this (inc. tests)
  """
  def one(filters), do: repo().single(Queries.query(Observation, filters))

  @doc """
  Retrieves a list of them by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for this (inc. tests)
  """
  def many(filters \\ []),
    do: {:ok, repo().many(Queries.query(Observation, filters))}

  def fields(group_fn, filters \\ [])
      when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of observations according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(
        cursor_fn,
        page_opts,
        base_filters \\ [],
        data_filters \\ [],
        count_filters \\ []
      )

  def page(
        cursor_fn,
        %{} = page_opts,
        base_filters,
        data_filters,
        count_filters
      ) do
    base_q = Queries.query(Observation, base_filters)
    data_q = Queries.filter(base_q, data_filters)
    count_q = Queries.filter(base_q, count_filters)

    with {:ok, [data, counts]} <-
           repo().transact_many(all: data_q, count: count_q) do
      {:ok, Page.new(data, counts, cursor_fn, page_opts)}
    end
  end

  @doc """
  Retrieves an Pages of observations according to various filters

  Used by:
  * GraphQL resolver bulk resolution
  """
  def pages(
        cursor_fn,
        group_fn,
        page_opts,
        base_filters \\ [],
        data_filters \\ [],
        count_filters \\ []
      )

  def pages(
        cursor_fn,
        group_fn,
        page_opts,
        base_filters,
        data_filters,
        count_filters
      ) do
    Bonfire.API.GraphQL.Pagination.pages(
      Queries,
      Observation,
      cursor_fn,
      group_fn,
      page_opts,
      base_filters,
      data_filters,
      count_filters
    )
  end

  def preload_all(%Observation{} = observation) do
    {:ok, observation} = one(id: observation.id, preload: :all)
    observation
  end

  ## mutations

  @doc """
  Create an observation
  """
  def create(%{} = creator, attrs) do
    new_observation_attrs =
      attrs
      # fallback if none indicated
      |> Map.put_new(:provider, creator)
      |> prepare_attrs(creator)

    cs = Observation.create_changeset(creator, new_observation_attrs)

    # IO.inspect(creator: creator)
    # IO.inspect(new_observation_attrs: new_observation_attrs)

    repo().transact_with(fn ->
      with :ok <- validate_user_involvement(creator, new_observation_attrs),
           :ok <-
             validate_provider_is_primary_accountable(new_observation_attrs),
           {:ok, observation} <-
             repo().insert(Observation.create_changeset_validate(cs)),
           observation = preload_all(observation),
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <-
             ValueFlows.Util.publish(creator, :observe, observation, attrs: attrs) do
        indexing_object_format(observation)
        |> ValueFlows.Util.index_for_search()

        {:ok, observation}
      end
    end)
  end

  def create(%{} = creator, %{id: context_id}, observation_attrs) do
    create(
      creator,
      Map.put_new(observation_attrs, :context_id, context_id)
    )
  end

  # TODO: take the user who is performing the update
  # @spec update(%Observation{}, attrs :: map) :: {:ok, Observation.t()} | {:error, Changeset.t()}
  def update(user, %Observation{} = observation, attrs) do
    repo().transact_with(fn ->
      observation = preload_all(observation)
      attrs = prepare_attrs(attrs, observation.creator)

      with :ok <- validate_user_involvement(user, observation),
           {:ok, observation} <-
             repo().update(Observation.update_changeset(observation, attrs)),
           {:ok, _} <- ValueFlows.Util.publish(observation, :updated) do
        {:ok, observation}
      end
    end)
  end

  defp validate_user_involvement(
         %{id: creator_id},
         %{provider_id: provider_id} = _observation
       )
       when provider_id == creator_id do
    # TODO add more complex rules once we have agent roles/relationships
    :ok
  end

  defp validate_user_involvement(
         creator,
         %{provider: provider} = _observation
       )
       when provider == creator do
    :ok
  end

  defp validate_user_involvement(_creator, _observation) do
    {:error, fail(403, "You cannot do this if you are not provider.")}
  end

  defp validate_provider_is_primary_accountable(
         %{resource_inventoried_as_id: resource_id, provider_id: provider_id} = _observation
       )
       when not is_nil(resource_id) and not is_nil(provider_id) do
    with {:ok, resource} <- EconomicResources.one([:default, id: resource_id]) do
      validate_provider_is_primary_accountable(%{
        resource_inventoried_as: resource,
        provider_id: provider_id
      })
    end
  end

  defp validate_provider_is_primary_accountable(
         %{resource_inventoried_as: resource, provider_id: provider_id} = _observation
       )
       when is_struct(resource) and not is_nil(provider_id) do
    if is_nil(resource.primary_accountable_id) or
         provider_id == resource.primary_accountable_id do
      :ok
    else
      {:error,
       fail(
         403,
         "You cannot do this since the provider is not accountable for the resource."
       )}
    end
  end

  defp validate_provider_is_primary_accountable(_observation) do
    :ok
  end

  defp prepare_attrs(attrs, creator \\ nil) do
    attrs
    |> Enums.maybe_put(
      :context_id,
      attrs |> Map.get(:in_scope_of, []) |> maybe(&List.first/1)
    )
    |> Map.put_new(:result_time, DateTime.utc_now())
    |> Enums.maybe_put(:provider_id, Util.attr_get_agent(attrs, :provider, creator))
    |> Enums.maybe_put(:made_by_sensor_id, Enums.attr_get_id(attrs, :made_by_sensor_id))
    |> Enums.maybe_put(
      :has_feature_of_interest_id,
      Enums.attr_get_id(attrs, :has_feature_of_interest)
    )
    |> Enums.maybe_put(:observed_property_id, Enums.attr_get_id(attrs, :observed_property))
    |> Enums.maybe_put(
      :has_result_id,
      Enums.attr_get_id(attrs, :has_result) || Enums.attr_get_id(attrs, :result_phenomenon)
    )
    |> Enums.maybe_put(:observed_during_id, Enums.attr_get_id(attrs, :observed_during))
    |> Enums.maybe_put(:at_location_id, Enums.attr_get_id(attrs, :at_location))
    |> parse_measure_attrs()
  end

  defp parse_measure_attrs(attrs) do
    Enum.reduce(attrs, %{}, fn {k, v}, acc ->
      if is_map(v) and Map.has_key?(v, :has_unit) do
        v = Enums.map_key_replace(v, :has_unit, :unit_id)
        # no idea why the numerical value isn't auto converted
        Map.put(acc, k, v)
      else
        Map.put(acc, k, v)
      end
    end)
  end

  def soft_delete(%Observation{} = observation) do
    repo().transact_with(fn ->
      with {:ok, observation} <-
             Bonfire.Common.Repo.Delete.soft_delete(observation),
           {:ok, _} <- ValueFlows.Util.publish(observation, :deleted) do
        {:ok, observation}
      end
    end)
  end

  def indexing_object_format(obj) do
    %{
      "index_type" => "ValueFlows.Observe.Observation",
      "id" => obj.id,
      # "url" => obj.character.canonical_url,
      # "icon" => icon,
      "summary" => Map.get(obj, :note),
      "published_at" => obj.published_at,
      "creator" => ValueFlows.Util.indexing_format_creator(obj)

      # "index_instance" => URI.parse(obj.character.canonical_url).host, # home instance of object
    }
  end
end
