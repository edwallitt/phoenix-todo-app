defmodule TodoApp.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  alias TodoApp.Todos.{Category, TodoCategory}

  schema "todos" do
    field :title, :string
    field :completed, :boolean, default: false
    field :important, :boolean, default: false

    many_to_many :categories, Category, join_through: TodoCategory

    timestamps()
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :completed])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 255)
  end

  @doc """
  Changeset for creating a new todo with only title
  """
  def create_changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :completed])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 255)
  end
end
