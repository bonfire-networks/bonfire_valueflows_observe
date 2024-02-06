defmodule Bonfire.Repo.Migrations.ImportObserve do
  @moduledoc false
  use Ecto.Migration

  def change do
    ValueFlows.Observe.Migrations.change()
    ValueFlows.Observe.Migrations.change_observable_phenomenon()
  end
end
