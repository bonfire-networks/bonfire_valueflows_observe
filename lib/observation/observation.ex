defmodule ValueFlows.Observe.Observation do
  use Pointers.Pointable,
    otp_app: :commons_pub,
    source: "vf_observe_observation",
    table_id: "ACTVA10BSERVEDF10WS0FVA1VE"

  import Bonfire.Repo.Changeset, only: [change_public: 1, change_disabled: 1]

  alias Ecto.Changeset
  @user Bonfire.Common.Config.get!(:user_schema)

  alias ValueFlows.Knowledge.ResourceSpecification
  alias ValueFlows.Observe.Observation
  alias ValueFlows.Observe.EconomicResource
  alias ValueFlows.Observe.Process

  alias Bonfire.Quantify.ObservablePhenomenon

  @type t :: %__MODULE__{}

  pointable_schema do
    field(:note, :string)

    field(:result_time, :utc_datetime_usec)

    belongs_to(:observed_during, Process)

    # EconomicResource or Agent
    belongs_to(:has_feature_of_interest, Pointers.Pointer)

    belongs_to(:result_phenomenon, Pointers.Pointer) # TBD
    belongs_to(:result_measure, Measure, on_replace: :nilify)

    belongs_to(:provider, Pointers.Pointer)

    belongs_to(:resource_inventoried_as, EconomicResource)
    belongs_to(:to_resource_inventoried_as, EconomicResource)

    field(:resource_classified_as, {:array, :string}, virtual: true)

    belongs_to(:resource_conforms_to, ResourceSpecification)


    belongs_to(:at_location, Bonfire.Geolocate.Geolocation)

    belongs_to(:context, Pointers.Pointer)

    belongs_to(:creator, @user)

    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:is_disabled, :boolean, virtual: true, default: false)
    field(:disabled_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)

    many_to_many(:tags, Bonfire.Common.Config.maybe_schema_or_pointer(CommonsPub.Tag.Taggable),
      join_through: "bonfire_tagged",
      unique: true,
      join_keys: [pointer_id: :id, tag_id: :id],
      on_replace: :delete
    )

    timestamps(inserted_at: false)
  end

  @required ~w(action_id provider_id receiver_id is_public)a
  @cast @required ++
          ~w(note resource_classified_as agreed_in has_beginning has_end result_time is_disabled)a ++
          ~w(input_of_id output_of_id resource_conforms_to_id resource_inventoried_as_id to_resource_inventoried_as_id)a ++
          ~w(triggered_by_id at_location_id context_id)a

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
    |> change_observable_phenomenons(attrs)
    |> common_changeset()
  end

  def create_changeset_validate(cs) do
    cs
    |> Changeset.validate_required(@required)
  end

  def update_changeset(%Observation{} = event, attrs) do
    event
    |> Changeset.cast(attrs, @cast)
    |> change_observable_phenomenons(attrs)
    |> common_changeset()
  end

  def change_observable_phenomenons(changeset, %{} = attrs) do
    measures = Map.take(attrs, measure_fields())

    Enum.reduce(measures, changeset, fn {field_name, observable_phenomenon}, c ->
      Changeset.put_assoc(c, field_name, observable_phenomenon)
    end)
  end

  def measure_fields do
    [:observed_measure, :effort_quantity]
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

  def context_module, do: ValueFlows.Observe.Observation.Observations

  def queries_module, do: ValueFlows.Observe.Observation.Queries

  def follow_filters, do: [:default]
end
