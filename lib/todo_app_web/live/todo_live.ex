defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view

  alias TodoApp.Todos
  alias TodoApp.Todos.Todo

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "todos")
    end

    todos = Todos.list_todos()
    categories = Todos.list_categories()

    {:ok,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)
     |> assign(:selected_category, nil)
     |> assign(:editing_todo, nil)
     |> assign(:form, to_form(%{"title" => ""}, as: :todo))}
  end

  def handle_event("add_todo", %{"todo" => todo_params}, socket) do
    case Todos.create_todo(todo_params) do
      {:ok, _todo} ->
        todos = list_todos_for_current_filter(socket)
        categories = Todos.list_categories()

        {:noreply,
         socket
         |> assign(:todos, todos)
         |> assign(:categories, categories)
         |> assign(:form, to_form(%{"title" => ""}, as: :todo))
         |> put_flash(:info, "Todo added successfully")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: :todo))
         |> put_flash(:error, "Error adding todo")}
    end
  end

  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{completed: !todo.completed}) do
      {:ok, _todo} ->
        todos = list_todos_for_current_filter(socket)
        {:noreply, assign(socket, :todos, todos)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error updating todo")}
    end
  end

  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.delete_todo(todo) do
      {:ok, _todo} ->
        todos = list_todos_for_current_filter(socket)
        categories = Todos.list_categories()

        {:noreply,
         socket
         |> assign(:todos, todos)
         |> assign(:categories, categories)
         |> put_flash(:info, "Todo deleted successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error deleting todo")}
    end
  end

  def handle_event("start_edit", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:noreply, assign(socket, :editing_todo, todo)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing_todo, nil)}
  end

  def handle_event("save_edit", %{"id" => id, "todo" => %{"title" => title}}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{title: title}) do
      {:ok, _todo} ->
        todos = list_todos_for_current_filter(socket)
        categories = Todos.list_categories()

        {:noreply,
         socket
         |> assign(:todos, todos)
         |> assign(:categories, categories)
         |> assign(:editing_todo, nil)
         |> put_flash(:info, "Todo updated successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error updating todo")}
    end
  end

  def handle_event("toggle_importance", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{important: !todo.important}) do
      {:ok, _todo} ->
        todos = list_todos_for_current_filter(socket)
        {:noreply, assign(socket, :todos, todos)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error updating importance")}
    end
  end

  def handle_event("filter_by_category", %{"category" => category}, socket) do
    todos =
      if category == "all" do
        Todos.list_todos()
      else
        Todos.list_todos_by_category(category)
      end

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:selected_category, if(category == "all", do: nil, else: category))}
  end

  def handle_event("validate", %{"todo" => todo_params}, socket) do
    def handle_event("validate_edit", %{"id" => _id, "todo" => todo_params}, socket) do
      form = to_form(Todo.changeset(%Todo{}, todo_params), as: :todo)
      {:noreply, assign(socket, :form, form)}
    end

    form = to_form(Todo.changeset(%Todo{}, todo_params), as: :todo)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_info({:todo_created, _todo}, socket) do
    todos = list_todos_for_current_filter(socket)
    categories = Todos.list_categories()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)}
  end

  def handle_info({:todo_updated, _todo}, socket) do
    todos = list_todos_for_current_filter(socket)
    {:noreply, assign(socket, :todos, todos)}
  end

  def handle_info({:todo_deleted, _todo}, socket) do
    todos = list_todos_for_current_filter(socket)
    categories = Todos.list_categories()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)}
  end

  def handle_info({:note_created, _note}, socket) do
    todos = list_todos_for_current_filter(socket)
    {:noreply, assign(socket, :todos, todos)}
  end

  def handle_info({:note_deleted, _note}, socket) do
    todos = list_todos_for_current_filter(socket)
    {:noreply, assign(socket, :todos, todos)}
  end

  defp list_todos_for_current_filter(socket) do
    case socket.assigns.selected_category do
      nil ->
        Todos.list_todos()

      category ->
        Todos.list_todos_by_category(category)
    end
  end
end
