defmodule TodoApp.Todos do
  @moduledoc """
  The Todos context for managing todo items and categories.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo
  alias TodoApp.Todos.{Todo, Category, TodoCategory}

  @doc """
  Returns the list of todos ordered by insertion date (newest first).
  Optionally filters by category.
  """
  def list_todos(category_filter \\ nil) do
    query =
      from t in Todo,
        preload: [:categories],
        order_by: [desc: t.inserted_at]

    query =
      if category_filter do
        from t in query,
          join: tc in TodoCategory,
          on: tc.todo_id == t.id,
          join: c in Category,
          on: c.id == tc.category_id,
          where: c.slug == ^category_filter
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a single todo.
  """
  def get_todo!(id), do: Repo.get!(Todo, id) |> Repo.preload(:categories)

  @doc """
  Creates a todo with hashtag parsing for categories.
  """
  def create_todo(attrs \\ %{}) do
    title = Map.get(attrs, "title", "")

    # Parse hashtags and clean title
    {clean_title, category_names} = parse_hashtags_from_title(title)

    # Create the todo with clean title
    clean_attrs = Map.put(attrs, "title", clean_title)

    case %Todo{}
         |> Todo.create_changeset(clean_attrs)
         |> Repo.insert() do
      {:ok, todo} ->
        # Associate with categories
        todo_with_categories = associate_todo_with_categories(todo, category_names)
        {:ok, todo_with_categories}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a todo.
  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a todo with hashtag parsing for categories.
  """
  def update_todo_with_hashtags(%Todo{} = todo, attrs) do
    title = Map.get(attrs, "title", "")

    # Parse hashtags and check for #imp flag
    {clean_title, category_names, is_important} = parse_hashtags_and_importance_from_title(title)

    # Update the todo with clean title and important flag
    clean_attrs = attrs |> Map.put("title", clean_title) |> Map.put("important", is_important)


    case todo
         |> Todo.changeset(clean_attrs)
         |> Repo.update() do
      {:ok, updated_todo} ->
        # Clear existing category associations
        from(tc in TodoCategory, where: tc.todo_id == ^updated_todo.id)
        |> Repo.delete_all()

        # Associate with new categories
        todo_with_categories = associate_todo_with_categories(updated_todo, category_names)
        {:ok, todo_with_categories}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a todo.
  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.
  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Returns all categories ordered by name.
  """
  def list_categories do
    Repo.all(from c in Category, order_by: c.name)
  end

  @doc """
  Gets a single category.
  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Deletes a category and all associated todo-category relationships.
  """
  def delete_category(%Category{} = category) do
    # Delete all todo-category associations first
    from(tc in TodoCategory, where: tc.category_id == ^category.id)
    |> Repo.delete_all()

    # Then delete the category
    Repo.delete(category)
  end

  @doc """
  Returns the count of todos associated with a category.
  """
  def get_category_todo_count(category_id) do
    from(tc in TodoCategory, where: tc.category_id == ^category_id, select: count())
    |> Repo.one()
  end

  @doc """
  Parses hashtags from a title string and returns {clean_title, [category_names]}.
  """
  @doc """\
  Parses hashtags and #imp flag from a title string and returns {clean_title, [category_names], is_important}.\
  """\
  def parse_hashtags_and_importance_from_title(title) do\
    # Find all hashtags in the title\
    hashtag_regex = ~r/#(\w+)/\
    matches = Regex.scan(hashtag_regex, title, capture: :all_but_first)\
    all_tags = List.flatten(matches)\
    \
    # Check if #imp is present and separate it from categories\
    is_important = "imp" in all_tags\
    category_names = Enum.reject(all_tags, &(&1 == "imp"))\
    \
    # Remove hashtags from title and clean up extra spaces\
    clean_title =\
      title\
      |> String.replace(hashtag_regex, "")\
      |> String.trim()\
      |> String.replace(~r/\s+/, " ")\
    \
    {clean_title, category_names, is_important}\
  end
  def parse_hashtags_from_title(title) do
    # Find all hashtags in the title
    hashtag_regex = ~r/#(\w+)/
    matches = Regex.scan(hashtag_regex, title, capture: :all_but_first)
    category_names = List.flatten(matches)

    # Remove hashtags from title and clean up extra spaces
    clean_title =
      title
      |> String.replace(hashtag_regex, "")
      |> String.trim()
      |> String.replace(~r/\s+/, " ")

    {clean_title, category_names}
  end

  @doc """
  Finds or creates categories and associates them with a todo.
  """
  def associate_todo_with_categories(todo, categories_or_names) do
    categories =
      Enum.map(categories_or_names, fn category_or_name ->
        case category_or_name do
          %Category{} = category -> category
          name when is_binary(name) -> find_or_create_category(name)
        end
      end)

    # Create associations
    Enum.each(categories, fn category ->
      %TodoCategory{}
      |> TodoCategory.changeset(%{todo_id: todo.id, category_id: category.id})
      |> Repo.insert(on_conflict: :nothing)
    end)

    # Return todo with preloaded categories
    Repo.preload(todo, :categories, force: true)
  end

  @doc """
  Finds an existing category or creates a new one.
  """
  def find_or_create_category(name) do
    slug = slugify(name)

    case Repo.get_by(Category, slug: slug) do
      nil ->
        {:ok, category} =
          %Category{}
          |> Category.changeset(%{name: name, slug: slug})
          |> Repo.insert()

        category

      category ->
        category
    end
  end

  @doc """
  Converts a string to a URL-friendly slug.
  """
  def slugify(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.replace(~r/\s+/, "_")
  end
end
