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

  @doc """
  Returns the list of todos with preloaded categories for efficient querying.
  """
  def list_todos do
    Todo
    |> preload(categories: :categories)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns todos filtered by category with optimized queries.
  """
  def list_todos_by_category(category_id) when is_integer(category_id) do
    Todo
    |> join(:inner, [t], tc in TodoCategory, on: tc.todo_id == t.id)
    |> where([t, tc], tc.category_id == ^category_id)
    |> preload(categories: :categories)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  def list_todos_by_category(_), do: list_todos()

  @doc """
  Gets a single todo with preloaded associations.
  """
  def get_todo!(id) do
    Todo
    |> preload(categories: :categories)
    |> Repo.get!(id)
  end

  @doc """
  Gets a single todo with notes preloaded for the notes page.
  """
  def get_todo_with_notes!(id) do
    Todo
    |> preload([:notes, categories: :categories])
    |> Repo.get!(id)
  end

  @doc """
  Creates a todo with intelligent hashtag parsing and category creation.
  """
  def create_todo(attrs \\ %{}) do
    # Extract hashtags from title
    {clean_title, hashtags} = extract_hashtags(attrs["title"] || "")

    # Update attrs with clean title
    clean_attrs = Map.put(attrs, "title", clean_title)

    # Start a transaction to ensure consistency
    Repo.transaction(fn ->
      # Create the todo
      case %Todo{}
           |> Todo.changeset(clean_attrs)
           |> Repo.insert() do
        {:ok, todo} ->
          # Process hashtags and create categories
          process_hashtags(todo, hashtags)

          # Return todo with preloaded categories
          get_todo!(todo.id)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a todo with hashtag processing.
  """
  def update_todo(%Todo{} = todo, attrs) do
    # Extract hashtags from new title
    {clean_title, hashtags} = extract_hashtags(attrs["title"] || todo.title)

    # Update attrs with clean title
    clean_attrs = Map.put(attrs, "title", clean_title)

    Repo.transaction(fn ->
      case todo
           |> Todo.changeset(clean_attrs)
           |> Repo.update() do
        {:ok, updated_todo} ->
          # Clear existing categories and add new ones
          clear_todo_categories(updated_todo)
          process_hashtags(updated_todo, hashtags)

          # Return updated todo with preloaded categories
          get_todo!(updated_todo.id)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Deletes a todo and cleans up orphaned categories.
  """
  def delete_todo(%Todo{} = todo) do
    Repo.transaction(fn ->
      # Get categories before deletion for cleanup
      category_ids = get_todo_category_ids(todo.id)

      # Delete the todo (cascades to todo_categories and notes)
      case Repo.delete(todo) do
        {:ok, deleted_todo} ->
          # Clean up orphaned categories
          cleanup_orphaned_categories(category_ids)
          deleted_todo

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # Private helper functions

  defp extract_hashtags(title) when is_binary(title) do
    # Match hashtags (# followed by word characters)
    hashtags =
      Regex.scan(~r/#\w+/, title)
      |> Enum.map(fn [hashtag] -> String.slice(hashtag, 1..-1) end)
      |> Enum.uniq()

    # Remove hashtags from title
    clean_title = Regex.replace(~r/#\w+\s*/, title, "") |> String.trim()

    {clean_title, hashtags}
  end

  defp process_hashtags(todo, hashtags) do
    Enum.each(hashtags, fn hashtag_name ->
      # Get or create category
      category = get_or_create_category(hashtag_name)

      # Create association if it doesn't exist
      %TodoCategory{}
      |> TodoCategory.changeset(%{todo_id: todo.id, category_id: category.id})
      |> Repo.insert(on_conflict: :nothing)
    end)
  end

  defp get_or_create_category(name) do
    slug = String.downcase(name) |> String.replace(~r/[^\w-]/, "-")

    case Repo.get_by(Category, slug: slug) do
      nil ->
        %Category{}
        |> Category.changeset(%{name: name, slug: slug})
        |> Repo.insert!()

      category ->
        category
    end
  end

  defp clear_todo_categories(todo) do
    from(tc in TodoCategory, where: tc.todo_id == ^todo.id)
    |> Repo.delete_all()
  end

  defp get_todo_category_ids(todo_id) do
    from(tc in TodoCategory, where: tc.todo_id == ^todo_id, select: tc.category_id)
    |> Repo.all()
  end

  defp cleanup_orphaned_categories(category_ids) do
    # Find categories that no longer have any todos
    orphaned_ids =
      from(c in Category,
        where: c.id in ^category_ids,
        left_join: tc in TodoCategory,
        on: tc.category_id == c.id,
        group_by: c.id,
        having: count(tc.id) == 0,
        select: c.id
      )
      |> Repo.all()

    # Delete orphaned categories
    if orphaned_ids != [] do
      from(c in Category, where: c.id in ^orphaned_ids)
      |> Repo.delete_all()
    end
  end

  # Category functions remain the same but with optimized queries

  @doc """
  Returns the list of categories ordered by usage.
  """
  def list_categories do
    Category
    |> join(:left, [c], tc in TodoCategory, on: tc.category_id == c.id)
    |> group_by([c], c.id)
    |> order_by([c], desc: count(), asc: c.name)
    |> Repo.all()
  end

  @doc """
  Gets a single category.
  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.
  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.
  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category and its associations.
  """
  def delete_category(%Category{} = category) do
    Repo.transaction(fn ->
      # Delete all todo_category associations
      from(tc in TodoCategory, where: tc.category_id == ^category.id)
      |> Repo.delete_all()

      # Delete the category
      Repo.delete(category)
    end)
  end

  # Note functions with optimized queries

  @doc """
  Returns the list of notes for a todo, ordered by creation date.
  """
  def list_notes_for_todo(todo_id) do
    Note
    |> where([n], n.todo_id == ^todo_id)
    |> order_by([n], desc: n.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single note.
  """
  def get_note!(id), do: Repo.get!(Note, id)

  @doc """
  Creates a note.
  """
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a note.
  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a note.
  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.
  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.
  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.
  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
