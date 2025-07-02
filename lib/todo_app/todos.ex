defmodule TodoApp.Todos do
  @moduledoc """
  The Todos context for managing todo items and categories.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo
  alias TodoApp.Todos.{Todo, Category, TodoCategory}

  """

  # PubSub for real-time updates
  defp broadcast({:ok, result}, event) do
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {event, result})
    {:ok, result}
  end

  defp broadcast({:error, _reason} = error, _event), do: error
  alias TodoApp.Todos.Note

