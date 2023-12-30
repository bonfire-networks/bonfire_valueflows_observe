defmodule ValueFlows.Observe.Migrations do
  @moduledoc false
  use Ecto.Migration
  # alias Needle.ULID
  import Needle.Migration

  alias ValueFlows.Knowledge.ResourceSpecification
  alias ValueFlows.Observe.Observation
  alias ValueFlows.EconomicResource
  alias ValueFlows.Process

  # defp event_table(), do: Observation.__schema__(:source)

  def up do
    create_pointable_table(ValueFlows.Observe.Observation) do
      add(:note, :text)
      # add(:image_id, weak_pointer(ValueFlows.Util.image_schema()), null: true)

      add(:result_time, :timestamptz)

      add(:provider_id, weak_pointer(), null: true)

      add(:made_by_sensor_id, weak_pointer(), null: true)

      add(:has_feature_of_interest_id, weak_pointer(), null: false)

      add(:observed_property_id, weak_pointer(), null: false)

      add(:has_result_id, weak_pointer(), null: false)

      add(:observed_during_id, weak_pointer(Process), null: true)

      add(:at_location_id, weak_pointer(Bonfire.Geolocate.Geolocation), null: true)

      # optional context as in_scope_of
      add(:context_id, weak_pointer(), null: true)

      add(:creator_id, weak_pointer(ValueFlows.Util.user_schema()), null: true)

      add(:published_at, :timestamptz)
      add(:deleted_at, :timestamptz)
      add(:disabled_at, :timestamptz)

      timestamps(inserted_at: false, type: :utc_datetime_usec)
    end
  end

  def down do
    drop_pointable_table(ValueFlows.Observe.Observation)
  end
end
