defmodule TodoApp.Todos.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias TodoApp.Todos.{Todo, TodoCategory}

  schema "categories" do
    field :name, :string
    field :slug, :string

    many_to_many :todos, Todo, join_through: TodoCategory

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_format(:slug, ~r/^[a-z0-9_]+$/,
      message: "must contain only lowercase letters, numbers, and underscores"
    )
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end
end
