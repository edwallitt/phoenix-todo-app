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
  Returns the list of todos.

  ## Examples

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos do
    from(t in Todo, order_by: [desc: t.important, desc: t.inserted_at])
    |> Repo.all()
    |> Repo.preload([:categories, :notes])
  end

  @doc """
  Returns the list of todos for a specific category.

  ## Examples

      iex> list_todos_by_category("work")
      [%Todo{}, ...]

  """
  def list_todos_by_category(category_name) do
    from(t in Todo,
      join: tc in TodoCategory,
      on: tc.todo_id == t.id,
      join: c in Category,
      on: c.id == tc.category_id,
      where: c.name == ^category_name,
      preload: [:categories, :notes]
    )
    |> order_by(desc: :important, desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id) do
    Repo.get!(Todo, id)
    |> Repo.preload([:categories, :notes])
  end

  @doc """
  Gets a single todo with notes preloaded.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo_with_notes!(123)
      %Todo{}

  """
  def get_todo_with_notes!(id) do
    Repo.get!(Todo, id)
    |> Repo.preload([:notes, :categories])
  end

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{field: value})
      {:ok, %Todo{}}

      iex> create_todo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    changeset = Todo.changeset(%Todo{}, attrs)

    case Repo.insert(changeset) do
      {:ok, todo} ->
        # Extract hashtags and create categories
        categories = extract_hashtags(attrs["title"] || "")
        todo = Repo.preload(todo, [:categories, :notes])

        # Create categories and associations
        Enum.each(categories, fn category_name ->
          category = get_or_create_category(category_name)
          create_todo_category(%{todo_id: todo.id, category_id: category.id})
        end)

        # Reload todo with associations
        todo = get_todo!(todo.id)

        # Broadcast the event
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_created, todo})

        {:ok, todo}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    changeset = Todo.changeset(todo, attrs)

    case Repo.update(changeset) do
      {:ok, updated_todo} ->
        # If title changed, update categories
        if Map.has_key?(attrs, :title) || Map.has_key?(attrs, "title") do
          new_title = attrs[:title] || attrs["title"]
          update_todo_categories(updated_todo, new_title)
        end

        # Reload with associations
        updated_todo = get_todo!(updated_todo.id)

        # Broadcast the event
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_updated, updated_todo})

        {:ok, updated_todo}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    case Repo.delete(todo) do
      {:ok, deleted_todo} ->
        # Broadcast the event
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_deleted, deleted_todo})
        {:ok, deleted_todo}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changesetdo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  # Categories

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Gets the count of todos for a specific category.

  ## Examples

      iex> get_category_todo_count(1)
      5

  """
  def get_category_todo_count(category_id) do
    from(tc in TodoCategory,
      where: tc.category_id == ^category_id,
      select: count(tc.todo_id)
    )
    |> Repo.one()
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  # Notes

  @doc """
  Returns the list of notes for a todo.

  ## Examples

      iex> list_notes_for_todo(123)
      [%Note{}, ...]

  """
  def list_notes_for_todo(todo_id) do
    from(n in Note,
      where: n.todo_id == ^todo_id,
      order_by: [desc: n.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(id), do: Repo.get!(Note, id)

  @doc """
  Creates a note for a todo.

  ## Examples

      iex> create_note(todo, %{field: value})
      {:ok, %Note{}}

      iex> create_note(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(%Todo{} = todo, attrs \\ %{}) do
    attrs = Map.put(attrs, "todo_id", todo.id)

    changeset = Note.changeset(%Note{}, attrs)

    case Repo.insert(changeset) do
      {:ok, note} ->
        # Broadcast the event
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:note_created, note})
        {:ok, note}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    case Repo.delete(note) do
      {:ok, deleted_note} ->
        # Broadcast the event
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:note_deleted, deleted_note})
        {:ok, deleted_note}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{}}

  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  # TodoCategory associations

  @doc """
  Creates a todo_category association.
  """
  def create_todo_category(attrs \\ %{}) do
    %TodoCategory{}
    |> TodoCategory.changeset(attrs)
    |> Repo.insert()
  end

  # Private helper functions

  defp extract_hashtags(title) when is_binary(title) do
    ~r/#(\w+)/
    |> Regex.scan(title, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.downcase/1)
    |> Enum.uniq()
  end

  defp extract_hashtags(_), do: []

  @doc """
  Gets or creates a category by name.
  """
  def get_or_create_category(name) do
    case Repo.get_by(Category, name: name) do
      nil ->
        {:ok, category} = create_category(%{name: name, slug: String.downcase(name)})
        category

      category ->
        category
    end
  end

  defp update_todo_categories(todo, new_title) do
    # Remove existing associations
    from(tc in TodoCategory, where: tc.todo_id == ^todo.id)
    |> Repo.delete_all()

    # Create new associations based on hashtags in new title
    categories = extract_hashtags(new_title)

    Enum.each(categories, fn category_name ->
      category = get_or_create_category(category_name)
      create_todo_category(%{todo_id: todo.id, category_id: category.id})
    end)
  end
end
