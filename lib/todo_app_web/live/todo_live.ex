defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Todos
  alias TodoApp.Todos.{Todo, Note}
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(TodoApp.PubSub, "todos")

    todos = Todos.list_todos()
    categories = Todos.list_categories()

    {:ok,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)
     |> assign(:form, Todos.change_todo(%Todo{}) |> to_form())
     |> assign(:editing_todo_id, nil)
     |> assign(:category_filter, nil)
     |> assign(:selected_todo_id, nil)
     |> assign(:notes, [])
     |> assign(:note_form, Todos.change_note(%Note{}) |> to_form())}
  end

  def handle_event("validate", %{"todo" => todo_params}, socket) do
    changeset = Todos.change_todo(%Todo{}, todo_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("add_todo", %{"todo" => todo_params}, socket) do
    case Todos.create_todo(todo_params) do
      {:ok, _todo} ->
        # Refresh todos and categories since new categories might be created
        todos = apply_category_filter(socket.assigns.category_filter)
        categories = Todos.list_categories()

        {:noreply,
         socket
         |> assign(:todos, todos)
         |> assign(:categories, categories)
         |> assign(:form, Todos.change_todo(%Todo{}) |> to_form())}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _updated_todo} = Todos.update_todo(todo, %{completed: !todo.completed})

    todos = apply_category_filter(socket.assigns.category_filter)
    {:noreply, assign(socket, :todos, todos)}
  end

  def handle_event("toggle_important", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _updated_todo} = Todos.update_todo(todo, %{important: !todo.important})

    # Re-fetch todos to get proper sorting (important first)
    todos = apply_category_filter(socket.assigns.category_filter)
    {:noreply, assign(socket, :todos, todos)}
  end

  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(todo)

    todos = apply_category_filter(socket.assigns.category_filter)
    categories = Todos.list_categories()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)}
  end

  def handle_event("start_edit", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    title_with_hashtags = Todos.reconstruct_title_with_hashtags(todo)

    edit_changeset =
      Todos.change_todo(todo, %{"title" => title_with_hashtags})

    {:noreply,
     socket
     |> assign(:editing_todo_id, String.to_integer(id))
     |> assign(:form, to_form(edit_changeset))}
  end

  def handle_event("save_edit", %{"todo" => todo_params}, socket) do
    todo = Todos.get_todo!(socket.assigns.editing_todo_id)

    case Todos.update_todo_with_hashtags(todo, todo_params) do
      {:ok, _updated_todo} ->
        todos = apply_category_filter(socket.assigns.category_filter)
        categories = Todos.list_categories()

        {:noreply,
         socket
         |> assign(:todos, todos)
         |> assign(:categories, categories)
         |> assign(:editing_todo_id, nil)
         |> assign(:form, Todos.change_todo(%Todo{}) |> to_form())}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_todo_id, nil)
     |> assign(:form, Todos.change_todo(%Todo{}) |> to_form())}
  end

  def handle_event("filter_by_category", %{"category" => "all"}, socket) do
    todos = Todos.list_todos()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:category_filter, nil)}
  end

  def handle_event("filter_by_category", %{"category" => category}, socket) do
    todos = Todos.list_todos(category)

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:category_filter, category)}
  end

  def handle_event("show_notes", %{"id" => id}, socket) do
    todo_id = String.to_integer(id)
    notes = Todos.list_notes_for_todo(todo_id)

    {:noreply,
     socket
     |> assign(:selected_todo_id, todo_id)
     |> assign(:notes, notes)
     |> assign(:note_form, Todos.change_note(%Note{}) |> to_form())}
  end

  def handle_event("hide_notes", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_todo_id, nil)
     |> assign(:notes, [])
     |> assign(:note_form, Todos.change_note(%Note{}) |> to_form())}
  end

  def handle_event("validate_note", %{"note" => note_params}, socket) do
    changeset = Todos.change_note(%Note{}, note_params)
    {:noreply, assign(socket, note_form: to_form(changeset, action: :validate))}
  end

  def handle_event("add_note", %{"note" => note_params}, socket) do
    note_params_with_todo = Map.put(note_params, "todo_id", socket.assigns.selected_todo_id)

    case Todos.create_note(note_params_with_todo) do
      {:ok, _note} ->
        notes = Todos.list_notes_for_todo(socket.assigns.selected_todo_id)

        {:noreply,
         socket
         |> assign(:notes, notes)
         |> assign(:note_form, Todos.change_note(%Note{}) |> to_form())}

      {:error, changeset} ->
        {:noreply, assign(socket, note_form: to_form(changeset))}
    end
  end

  def handle_event("delete_note", %{"id" => id}, socket) do
    note = Todos.get_note!(id)
    {:ok, _} = Todos.delete_note(note)

    notes = Todos.list_notes_for_todo(socket.assigns.selected_todo_id)
    {:noreply, assign(socket, :notes, notes)}
  end

  # Handle PubSub broadcasts
  def handle_info({:note_created, _note}, socket) do
    if socket.assigns.selected_todo_id do
      notes = Todos.list_notes_for_todo(socket.assigns.selected_todo_id)
      {:noreply, assign(socket, :notes, notes)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:note_deleted, _note}, socket) do
    if socket.assigns.selected_todo_id do
      notes = Todos.list_notes_for_todo(socket.assigns.selected_todo_id)
      {:noreply, assign(socket, :notes, notes)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({event, _data}, socket)
      when event in [:todo_created, :todo_updated, :todo_deleted] do
    todos = apply_category_filter(socket.assigns.category_filter)
    categories = Todos.list_categories()

    {:noreply,
     socket
     |> assign(:todos, todos)
     |> assign(:categories, categories)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp apply_category_filter(nil), do: Todos.list_todos()
  defp apply_category_filter(category), do: Todos.list_todos(category)

  def show_notes_js(todo_id) do
    JS.show(to: "#notes-#{todo_id}")
    |> JS.hide(to: ".notes-section:not(#notes-#{todo_id})")
  end

  def hide_notes_js(todo_id) do
    JS.hide(to: "#notes-#{todo_id}")
  end
end
