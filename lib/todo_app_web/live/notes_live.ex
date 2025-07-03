defmodule TodoAppWeb.NotesLive do
  use TodoAppWeb, :live_view

  alias TodoApp.Todos
  alias TodoApp.Todos.Note

  def mount(%{"id" => todo_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "notes:#{todo_id}")
    end

    todo = Todos.get_todo_with_notes!(todo_id)
    notes = Todos.list_notes_for_todo(todo_id)

    {:ok,
     socket
     |> assign(:todo, todo)
     |> assign(:notes, notes)
     |> assign(:form, to_form(%{"content" => ""}, as: :note))}
  end

  def handle_event("add_note", %{"note" => note_params}, socket) do
    case Todos.create_note(socket.assigns.todo, note_params) do
      {:ok, note} ->
        {:noreply,
         socket
         |> assign(:form, to_form(%{"content" => ""}, as: :note))
         |> put_flash(:info, "Note added successfully")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: :note))
         |> put_flash(:error, "Error adding note")}
    end
  end

  def handle_event("delete_note", %{"id" => note_id}, socket) do
    note = Todos.get_note!(note_id)

    case Todos.delete_note(note) do
      {:ok, _note} ->
        {:noreply, put_flash(socket, :info, "Note deleted successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error deleting note")}
    end
  end

  def handle_event("validate", %{"note" => note_params}, socket) do
    form = to_form(Note.changeset(%Note{}, note_params), as: :note)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_info({:note_created, note}, socket) do
    if note.todo_id == socket.assigns.todo.id do
      notes = Todos.list_notes_for_todo(socket.assigns.todo.id)
      {:noreply, assign(socket, :notes, notes)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:note_deleted, note}, socket) do
    if note.todo_id == socket.assigns.todo.id do
      notes = Todos.list_notes_for_todo(socket.assigns.todo.id)
      {:noreply, assign(socket, :notes, notes)}
    else
      {:noreply, socket}
    end
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.from_naive!(Application.get_env(:todo_app, :timezone, "Etc/UTC"))
    |> Calendar.strftime("%B %d, %Y at %I:%M %p")
  end
end
