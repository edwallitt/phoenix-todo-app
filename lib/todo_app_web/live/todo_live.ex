defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view

  alias TodoApp.Todos
  alias TodoApp.Todos.Todo

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "todos")
    end

    todos = Todos.list_todos()
    categories = Todos.list_categories()
    changeset = Todos.change_todo(%Todo{})

    {:ok,
     socket
     |> assign(:todos, todos)
     |> assign(:todos_empty?, todos == [])
     |> assign(:categories, categories)
     |> assign(:current_filter, nil)
     |> assign(:editing_todo_id, nil)
     |> assign(:edit_form, nil)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("add_todo", %{"todo" => todo_params}, socket) do
    case Todos.create_todo(todo_params) do
      {:ok, todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_created, todo})
        changeset = Todos.change_todo(%Todo{})

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> put_flash(:info, "Todo added successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    # Reconstruct the title with hashtags and #imp for editing
    title_with_hashtags = Todos.reconstruct_title_with_hashtags(todo)

    changeset = Todos.change_todo(todo, %{title: title_with_hashtags})

    {:noreply,
     socket
     |> assign(:editing_todo_id, todo.id)
     |> assign(:edit_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_edit", %{"todo" => todo_params}, socket) do
    todo = Todos.get_todo!(socket.assigns.editing_todo_id)

    case Todos.update_todo_with_hashtags(todo, todo_params) do
      {:ok, updated_todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_updated, updated_todo})

        {:noreply,
         socket
         |> assign(:editing_todo_id, nil)
         |> assign(:edit_form, nil)
         |> assign(:form, to_form(Todos.change_todo(%Todo{})))
         |> put_flash(:info, "Todo updated successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_todo_id, nil)
     |> assign(:edit_form, nil)}
  end

  def handle_event("validate_edit", %{"todo" => todo_params}, socket) do
    todo = Todos.get_todo!(socket.assigns.editing_todo_id)

    changeset =
      todo
      |> Todos.change_todo(todo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :edit_form, to_form(changeset))}
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{completed: !todo.completed}) do
      {:ok, updated_todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_updated, updated_todo})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update todo")}
    end
  end

  @impl true
  def handle_event("toggle_important", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{important: !todo.important}) do
      {:ok, updated_todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_updated, updated_todo})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update todo")}
    end
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.delete_todo(todo) do
      {:ok, _deleted_todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:todo_deleted, todo})
        {:noreply, put_flash(socket, :info, "Todo deleted successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete todo")}
    end
  end

  @impl true
  def handle_event("filter_by_category", %{"category" => category_slug}, socket) do
    filter = if category_slug == "all", do: nil, else: category_slug
    todos = Todos.list_todos(filter)

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:todos_empty?, todos == [])
     |> assign(:current_filter, filter)}
  end

  @impl true
  @impl true\
  def handle_event("start_edit", %{"id" => id}, socket) do\
    todo = Todos.get_todo!(id)\
\
    # Reconstruct the title with hashtags and #imp for editing\
    title_with_hashtags = Todos.reconstruct_title_with_hashtags(todo)\
\
    changeset = Todos.change_todo(todo, %{title: title_with_hashtags})\
\
    {:noreply,\
     socket\
     |> assign(:editing_todo_id, todo.id)\
     |> assign(:edit_form, to_form(changeset))}\
  end\

  def handle_event("validate", %{"todo" => todo_params}, socket) do
    changeset =
      %Todo{}
      |> Todos.change_todo(todo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_info({:todo_created, _todo}, socket) do
    # Refresh todos list to include the new todo with categories
    todos = Todos.list_todos(socket.assigns.current_filter)
    categories = Todos.list_categories()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)
     |> assign(:todos_empty?, todos == [])}
  end

  @impl true
  def handle_info({:todo_updated, _updated_todo}, socket) do
    # Re-fetch todos to ensure proper sorting by importance
    todos = Todos.list_todos(socket.assigns.current_filter)
    categories = Todos.list_categories()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)}
  end

  def handle_info({:todo_deleted, deleted_todo}, socket) do
    todos = Enum.reject(socket.assigns.todos, &(&1.id == deleted_todo.id))

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:todos_empty?, todos == [])}
  end
end
