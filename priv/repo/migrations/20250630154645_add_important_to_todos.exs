defmodule TodoApp.Repo.Migrations.AddImportantToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :important, :boolean, default: false, null: false
    end
  end
end
