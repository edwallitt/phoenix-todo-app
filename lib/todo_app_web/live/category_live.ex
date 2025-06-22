defmodule TodoAppWeb.CategoryLive do
  use TodoAppWeb, :live_view

  alias TodoApp.Todos

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "categories")
    end

    categories = Todos.list_categories()

    {:ok,
     socket
     |> assign(:categories, categories)
     |> assign(:categories_empty?, categories == [])}
  end

  @impl true
  def handle_event("delete_category", %{"id" => id}, socket) do
    category = Todos.get_category!(id)

    case Todos.delete_category(category) do
      {:ok, _deleted_category} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "categories", {:category_deleted, category})
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "todos", {:category_deleted, category})

        {:noreply, put_flash(socket, :info, "Category '#{category.name}' deleted successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete category")}
    end
  end

  @impl true
  def handle_info({:category_deleted, deleted_category}, socket) do
    categories = Enum.reject(socket.assigns.categories, &(&1.id == deleted_category.id))

    {:noreply,
     socket
     |> assign(:categories, categories)
     |> assign(:categories_empty?, categories == [])}
  end

  @impl true
  def handle_info({:category_created, new_category}, socket) do
    categories = [new_category | socket.assigns.categories]

    {:noreply,
     socket
     |> assign(:categories, categories)
     |> assign(:categories_empty?, categories == [])}
  end
end
