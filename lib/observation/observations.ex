# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observe.Observations do
  import Bonfire.Common.Utils, only: [maybe_put: 3, attr_get_id: 2, maybe: 2, maybe_append: 2, map_key_replace: 3]

  import Bonfire.Common.Config, only: [repo: 0]

  # alias Bonfire.GraphQL
  alias Bonfire.GraphQL.{Fields, Page}

  @user Bonfire.Common.Config.get!(:user_schema)

  alias ValueFlows.Observe.Observation
  alias ValueFlows.Observe.EconomicResource.EconomicResources
  alias ValueFlows.Observe.Observation.Queries
  alias ValueFlows.Observe.Observation.EventSideEffects

  alias ValueFlows.Observe.Process.Processes

  import Bonfire.Fail.Error

  require Logger

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
  def many(filters \\ []), do: {:ok, repo().all(Queries.query(Observation, filters))}

  def fields(group_fn, filters \\ [])
      when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of events according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])

  def page(cursor_fn, %{} = page_opts, base_filters, data_filters, count_filters) do
    base_q = Queries.query(Observation, base_filters)
    data_q = Queries.filter(base_q, data_filters)
    count_q = Queries.filter(base_q, count_filters)

    with {:ok, [data, counts]} <- repo().transact_many(all: data_q, count: count_q) do
      {:ok, Page.new(data, counts, cursor_fn, page_opts)}
    end
  end

  @doc """
  Retrieves an Pages of events according to various filters

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

  def pages(cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters) do
    Bonfire.GraphQL.Pagination.pages(
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

  def preload_all(%Observation{} = event) do
    {:ok, event} = one(id: event.id, preload: :all)
    event
  end


  ## mutations


  @doc """
  Create an Event (with preexisting resources)
  """
  def create(%{} = creator, event_attrs) do
    new_event_attrs =
      event_attrs
      # fallback if none indicated
      |> Map.put_new(:provider, creator)
      |> prepare_attrs()

    cs = Observation.create_changeset(creator, new_event_attrs)

    # IO.inspect(creator: creator)
    # IO.inspect(new_event_attrs: new_event_attrs)

    repo().transact_with(fn ->
      with :ok <- validate_user_involvement(creator, new_event_attrs),
           :ok <- validate_provider_is_primary_accountable(new_event_attrs),
           {:ok, event} <- repo().insert(cs |> Observation.create_changeset_validate()),
           {:ok, event} <- ValueFlows.Util.try_tag_thing(creator, event, new_event_attrs),
           event = preload_all(event),
           act_attrs = %{verb: "created", is_local: true},
           # FIXME
           {:ok, activity} <- ValueFlows.Util.activity_create(creator, event, act_attrs),
           :ok <- ValueFlows.Util.publish(creator, event, activity, :created) do
        indexing_object_format(event) |> ValueFlows.Util.index_for_search()
        {:ok, event}
      end
    end)
  end

  def create(%{} = creator, %{id: context_id}, event_attrs) do

    create(creator, event_attrs
      |> Map.put_new(:context_id, context_id))
  end

  # TODO: take the user who is performing the update
  # @spec update(%Observation{}, attrs :: map) :: {:ok, Observation.t()} | {:error, Changeset.t()}
  def update(user, %Observation{} = event, attrs) do
    repo().transact_with(fn ->
      event = preload_all(event)
      attrs = prepare_attrs(attrs)

      with :ok <- validate_user_involvement(user, event),
           {:ok, event} <- repo().update(Observation.update_changeset(event, attrs)),
           {:ok, event} <- ValueFlows.Util.try_tag_thing(nil, event, attrs),
           :ok <- ValueFlows.Util.publish(event, :updated) do
        {:ok, event}
      end
    end)
  end


  defp validate_user_involvement(
         %{id: creator_id},
         %{provider_id: provider_id} = _event
       )
       when provider_id == creator_id do
    # TODO add more complex rules once we have agent roles/relationships
    :ok
  end


  defp validate_user_involvement(
         creator,
         %{provider: provider} = _event
       )
       when provider == creator do
    :ok
  end

  defp validate_user_involvement(_creator, _event) do
   {:error, error(403, "You cannot do this if you are not provider.")}
  end

  defp validate_provider_is_primary_accountable(
         %{resource_inventoried_as_id: resource_id, provider_id: provider_id} = _event
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
         %{resource_inventoried_as: resource, provider_id: provider_id} = _event
       )
       when is_struct(resource) and not is_nil(provider_id) do
    if is_nil(resource.primary_accountable_id) or provider_id == resource.primary_accountable_id do
      :ok
    else
      {:error, error(403, "You cannot do this since the provider is not accountable for the resource.")}
    end
  end

  defp validate_provider_is_primary_accountable(_event) do
    :ok
  end


  defp prepare_attrs(attrs) do
    attrs
    |> maybe_put(
      :context_id,
      attrs |> Map.get(:in_scope_of, []) |> maybe(&List.first/1)
    )
    |> maybe_put(:provider_id, attr_get_id(attrs, :provider))
    |> maybe_put(:made_by_sensor_id, attr_get_id(attrs, :made_by_sensor_id))
    |> maybe_put(:has_feature_of_interest_id, attr_get_id(attrs, :has_feature_of_interest))
    |> maybe_put(:observed_property_id, attr_get_id(attrs, :observed_property))
    |> maybe_put(:has_result_id, attr_get_id(attrs, :has_result))
    |> maybe_put(:observed_during_id, attr_get_id(attrs, :observed_during))
    |> maybe_put(:at_location_id, attr_get_id(attrs, :at_location))
    |> parse_measure_attrs()
  end

  defp parse_measure_attrs(attrs) do
    Enum.reduce(attrs, %{}, fn {k, v}, acc ->
      if is_map(v) and Map.has_key?(v, :has_observation) do
        v = map_key_replace(v, :has_observation, :unit_id)
        # I have no idea why the numerical value isn't auto converted
        Map.put(acc, k, v)
      else
        Map.put(acc, k, v)
      end
    end)
  end

  def soft_delete(%Observation{} = event) do
    repo().transact_with(fn ->
      with {:ok, event} <- Bonfire.Repo.Delete.soft_delete(event),
           :ok <- ValueFlows.Util.publish(event, :deleted) do
        {:ok, event}
      end
    end)
  end

  def indexing_object_format(obj) do
    %{
      "index_type" => "Observation",
      "id" => obj.id,
      # "canonicalUrl" => obj.character.canonical_url,
      # "icon" => icon,
      "summary" => Map.get(obj, :note),
      "published_at" => obj.published_at,
      "creator" => ValueFlows.Util.indexing_format_creator(obj)
      # "index_instance" => URI.parse(obj.character.canonical_url).host, # home instance of object
    }
  end


end
