defmodule TodoApp.Repo.Migrations.CreateTodoCategories do
  use Ecto.Migration

  def change do
    create table(:todo_categories) do
      add :todo_id, references(:todos, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:todo_categories, [:todo_id])
    create index(:todo_categories, [:category_id])
    create unique_index(:todo_categories, [:todo_id, :category_id])
  end
end
