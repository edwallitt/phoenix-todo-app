defmodule TodoApp.Repo.Migrations.CreateAllTablesForPostgres do
  use Ecto.Migration

  def change do
    # Create todos table first
    create table(:todos) do
      add :title, :string, null: false
      add :completed, :boolean, default: false, null: false
      add :important, :boolean, default: false, null: false

      timestamps()
    end

    create index(:todos, [:inserted_at])
    create index(:todos, [:completed])

    # Create categories table
    create table(:categories) do
      add :name, :string, null: false
      add :slug, :string, null: false

      timestamps()
    end

    create unique_index(:categories, [:name])
    create unique_index(:categories, [:slug])

    # Create todo_categories join table
    create table(:todo_categories) do
      add :todo_id, references(:todos, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:todo_categories, [:todo_id])
    create index(:todo_categories, [:category_id])
    create unique_index(:todo_categories, [:todo_id, :category_id])

    # Create notes table (requires todos table to exist)
    create table(:notes) do
      add :content, :text, null: false
      add :todo_id, references(:todos, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notes, [:todo_id])
  end
end
