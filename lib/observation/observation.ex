defmodule ValueFlows.Observe.Observation do
  use Needle.Pointable,
    otp_app: :bonfire_valueflows_observe,
    source: "vf_observe_observation",
    table_id: "0BSERVEDPHEN0MEN0N0RMEASVR"

  import Bonfire.Common.Repo.Utils, only: [change_public: 1, change_disabled: 1]

  alias Ecto.Changeset
  @user Application.compile_env!(:bonfire, :user_schema)

  alias ValueFlows.Knowledge.ResourceSpecification
  alias ValueFlows.Observe.Observation
  alias ValueFlows.EconomicResource
  alias ValueFlows.Process

  @type t :: %__MODULE__{}

  pointable_schema do
    field(:note, :string)

    field(:result_time, :utc_datetime_usec)

    # agent
    belongs_to(:provider, @user)

    # agent or `EconomicResource` or `ResourceSpecification`
    belongs_to(:made_by_sensor, Needle.Pointer)

    belongs_to(:made_by_agent, @user,
      foreign_key: :made_by_sensor_id,
      define_field: false
    )

    belongs_to(:made_by_resource, EconomicResource,
      foreign_key: :made_by_sensor_id,
      define_field: false
    )

    belongs_to(:made_by_resource_specification, ResourceSpecification,
      foreign_key: :made_by_sensor_id,
      define_field: false
    )

    # EconomicResource or Agent
    belongs_to(:has_feature_of_interest, Needle.Pointer)

    belongs_to(:has_observed_resource, EconomicResource,
      foreign_key: :has_feature_of_interest_id,
      define_field: false
    )

    belongs_to(:has_observed_agent, @user,
      foreign_key: :has_feature_of_interest_id,
      define_field: false
    )

    belongs_to(:observed_property, Bonfire.Classify.Category)

    belongs_to(:has_result, Needle.Pointer)

    belongs_to(:result_measure, Bonfire.Quantify.Measure,
      on_replace: :nilify,
      foreign_key: :has_result_id,
      define_field: false
    )

    belongs_to(:result_phenomenon, Bonfire.Classify.Category,
      on_replace: :nilify,
      foreign_key: :has_result_id,
      define_field: false
    )

    belongs_to(:observed_during, Process)

    belongs_to(:at_location, Bonfire.Geolocate.Geolocation)

    belongs_to(:context, Needle.Pointer)

    belongs_to(:creator, @user)

    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:is_disabled, :boolean, virtual: true, default: false)
    field(:disabled_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)

    timestamps(inserted_at: false)
  end

  @required ~w( has_feature_of_interest_id observed_property_id is_public)a
  @cast @required ++
          ~w(provider_id note is_disabled)a ++
          ~w(has_result_id result_time made_by_sensor_id observed_during_id)a ++
          ~w(at_location_id context_id)a

  def create_changeset(
        %{} = creator,
        attrs
      ) do
    %Observation{}
    |> Changeset.cast(attrs, @cast)
    # |> Changeset.validate_required(@required)
    |> Changeset.change(
      creator_id: creator.id,
      is_public: true
    )
    |> ValueFlows.Util.change_measures(attrs, [:result_measure])
    |> common_changeset()
  end

  def create_changeset_validate(cs) do
    Changeset.validate_required(cs, @required)
  end

  def update_changeset(%Observation{} = event, attrs) do
    event
    |> Changeset.cast(attrs, @cast)
    |> ValueFlows.Util.change_measures(attrs, [:result_measure])
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> change_public()
    |> change_disabled()
    |> Changeset.foreign_key_constraint(
      :resource_inventoried_as_id,
      name: :vf_event_resource_inventoried_as_id_fkey
    )
    |> Changeset.foreign_key_constraint(
      :to_resource_inventoried_as_id,
      name: :vf_event_to_resource_inventoried_as_id_fkey
    )
  end

  @behaviour Bonfire.Common.SchemaModule
  def context_module, do: ValueFlows.Observe.Observations
  def query_module, do: ValueFlows.Observe.Observation.Queries

  def follow_filters, do: [:default]
end
