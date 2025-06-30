defmodule TodoApp.TodosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoApp.Todos` context.
  """

  alias TodoApp.Todos

  @doc """
  Generate a todo.
  """
  def todo_fixture(attrs \\ %{}) do
    # Convert all keys to strings
    string_attrs =
      for {key, value} <- attrs, into: %{} do
        {to_string(key), value}
      end

    {:ok, todo} =
      string_attrs
      |> Enum.into(%{
        "title" => "some title",
        "completed" => false
      })
      |> Todos.create_todo()

    todo
  end

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    name = Map.get(attrs, :name, Map.get(attrs, "name", "some category")) || "some category"

    category =
      name
      |> Todos.find_or_create_category()

    category
  end

  @doc """
  Generate a todo with categories.
  """
  def todo_with_categories_fixture(todo_attrs \\ %{}, category_names \\ []) do
    todo = todo_fixture(todo_attrs)

    categories =
      Enum.map(category_names, fn name ->
        category = Todos.find_or_create_category(name)
        category
      end)

    if categories != [] do
      Todos.associate_todo_with_categories(todo, categories)
    end

    todo
  end
end
