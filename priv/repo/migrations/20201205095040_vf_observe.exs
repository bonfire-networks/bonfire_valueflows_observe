defmodule Bonfire.Repo.Migrations.ImportObserve do
  @moduledoc false
  use Ecto.Migration

  def up do
    ValueFlows.Observe.Migrations.up()
  end

  def down do
    ValueFlows.Observe.Migrations.down()
  end
end
