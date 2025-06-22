defmodule TodoApp.Todos.TodoCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias TodoApp.Todos.{Todo, Category}

  schema "todo_categories" do
    belongs_to :todo, Todo
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(todo_category, attrs) do
    todo_category
    |> cast(attrs, [:todo_id, :category_id])
    |> validate_required([:todo_id, :category_id])
    |> unique_constraint([:todo_id, :category_id])
  end
end
