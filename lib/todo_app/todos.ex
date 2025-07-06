defmodule TodoApp.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo

  alias TodoApp.Todos.Todo
  alias TodoApp.Todos.Category
  alias TodoApp.Todos.TodoCategory
  alias TodoApp.Todos.Note
end
