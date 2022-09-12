defmodule Bonfire.Repo.Migrations.ImportQuantify do
  use Ecto.Migration

  def change do
    if Code.ensure_loaded?(ValueFlows.Observe.Migrations) do
      ValueFlows.Observe.Migrations.change()
      ValueFlows.Observe.Migrations.change_observable_phenomenon()
    end
  end
end
