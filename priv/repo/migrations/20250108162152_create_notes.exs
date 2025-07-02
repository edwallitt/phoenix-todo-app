defmodule TodoApp.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :content, :text, null: false
      add :todo_id, references(:todos, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notes, [:todo_id])
  end
end
