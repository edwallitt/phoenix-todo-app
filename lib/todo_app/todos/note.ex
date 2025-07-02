defmodule TodoApp.Todos.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :content, :string
    belongs_to :todo, TodoApp.Todos.Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:content, :todo_id])
    |> validate_required([:content, :todo_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> foreign_key_constraint(:todo_id)
  end

  @doc """
  Renders the note content as HTML from Markdown.
  """
  def render_html(note) do
    case Earmark.as_html(note.content) do
      {:ok, html, _} -> html
      {:error, _html, _messages} -> note.content
    end
  end
end
