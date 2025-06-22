defmodule TodoApp.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string, null: false
      add :completed, :boolean, default: false, null: false

      timestamps()
    end

    create index(:todos, [:inserted_at])
    create index(:todos, [:completed])
  end
end
