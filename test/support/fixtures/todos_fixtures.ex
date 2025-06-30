defmodule TodoApp.TodosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoApp.Todos` context.
  """

  alias TodoApp.Todos

  @doc """
  Generate a todo.
  """
  def todo_fixture(:attrs \\ %{}) do
    {:ok, todo} =
      :attrs
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
  def category_fixture(:attrs \\ %{}) do
    name = :attrs[:name] || "some category"

    {:ok, category} =
      %{"name" => name}
      |> Todos.find_or_create_category()

    category
  end

  @doc """
  Generate a todo with categories.
  """
  def todo_with_categories_fixture(todo_:attrs \\ %{}, category_names \\ []) do
    todo = todo_fixture(todo_:attrs)

    categories =
      Enum.map(category_names, fn name ->
        {:ok, category} = Todos.find_or_create_category(%{"name" => name})
        category
      end)

    if categories != [] do
      Todos.associate_todo_with_categories(todo, categories)
    end

    todo
  end
end
