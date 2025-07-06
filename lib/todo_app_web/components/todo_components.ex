defmodule TodoAppWeb.TodoComponents do
  @moduledoc """
  Function components for todo-related UI elements.
  """
  use Phoenix.Component
  import TodoAppWeb.CoreComponents

  @doc """
  Renders a single todo item with all actions and states.
  """
  attr :todo, :map, required: true
  attr :editing, :map, default: nil
  attr :on_toggle, :string, default: "toggle_todo"
  attr :on_delete, :string, default: "delete_todo"
  attr :on_start_edit, :string, default: "start_edit"
  attr :on_cancel_edit, :string, default: "cancel_edit"
  attr :on_save_edit, :string, default: "save_edit"
  attr :on_toggle_importance, :string, default: "toggle_importance"

  def todo_item(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-3 hover:shadow-md transition-shadow duration-200">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-3 flex-1">
          <!-- Completion Toggle -->
          <button
            phx-click={@on_toggle}
            phx-value-id={@todo.id}
            class={[
              "w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors duration-200",
              if(@todo.completed,
                do: "bg-green-500 border-green-500 text-white",
                else: "border-gray-300 hover:border-green-400"
              )
            ]}
          >
            <%= if @todo.completed do %>
              <.icon name="hero-check" class="w-3 h-3" />
            <% end %>
          </button>
          
    <!-- Todo Content -->
          <div class="flex-1">
            <%= if @editing && @editing.id == @todo.id do %>
              <!-- Edit Mode -->
              <form
                phx-submit={@on_save_edit}
                phx-value-id={@todo.id}
                class="flex items-center space-x-2"
              >
                <input
                  type="text"
                  name="title"
                  value={@todo.title}
                  class="flex-1 px-3 py-1 text-gray-900 bg-white border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  autofocus
                />
                <button
                  type="submit"
                  class="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
                >
                  Save
                </button>
                <button
                  type="button"
                  phx-click={@on_cancel_edit}
                  class="px-3 py-1 text-sm bg-gray-500 text-white rounded hover:bg-gray-600 transition-colors"
                >
                  Cancel
                </button>
              </form>
            <% else %>
              <!-- Display Mode -->
              <div class="flex items-center space-x-2">
                <span class={[
                  "text-gray-900",
                  @todo.completed && "line-through text-gray-500 dark:text-gray-400"
                ]}>
                  {@todo.title}
                </span>
                
    <!-- Categories -->
                <%= if length(@todo.categories) > 0 do %>
                  <div class="flex flex-wrap gap-1">
                    <%= for category <- @todo.categories do %>
                      <.category_badge category={category} />
                    <% end %>
                  </div>
                <% end %>
                
    <!-- Notes Count -->
                <%= if length(@todo.notes) > 0 do %>
                  <span class="inline-flex items-center px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full">
                    <.icon name="hero-document-text" class="w-3 h-3 mr-1" />
                    {length(@todo.notes)}
                  </span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Action Buttons -->
        <%= if !@editing || @editing.id != @todo.id do %>
          <div class="flex items-center space-x-2">
            <!-- Importance Toggle -->
            <button
              phx-click={@on_toggle_importance}
              phx-value-id={@todo.id}
              class={[
                "p-1 rounded transition-colors duration-200",
                if(@todo.important,
                  do: "text-yellow-500 hover:text-yellow-600",
                  else: "text-gray-400 hover:text-yellow-400"
                )
              ]}
              title={if(@todo.important, do: "Remove importance", else: "Mark as important")}
            >
              <.icon
                name="hero-star"
                class={
                  if(@todo.important,
                    do: "w-5 h-5 fill-current",
                    else: "w-5 h-5"
                  )
                }
              />
            </button>
            
    <!-- Edit Button -->
            <button
              phx-click={@on_start_edit}
              phx-value-id={@todo.id}
              class="p-1 text-gray-400 hover:text-blue-500 transition-colors duration-200"
              title="Edit todo"
            >
              <.icon name="hero-pencil" class="w-4 h-4" />
            </button>
            
    <!-- Notes Button -->
            <.link
              navigate={"/todos/#{@todo.id}/notes"}
              class="p-1 text-gray-400 hover:text-green-500 transition-colors duration-200"
              title="View notes"
            >
              <.icon name="hero-document-text" class="w-4 h-4" />
            </.link>
            
    <!-- Delete Button -->
            <button
              phx-click={@on_delete}
              phx-value-id={@todo.id}
              data-confirm="Are you sure you want to delete this todo?"
              class="p-1 text-gray-400 hover:text-red-500 transition-colors duration-200"
              title="Delete todo"
            >
              <.icon name="hero-trash" class="w-4 h-4" />
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a form for adding new todos.
  """
  attr :form, :map, required: true
  attr :on_submit, :string, default: "add_todo"
  attr :on_change, :string, default: "validate"

  def todo_form(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Add New Todo</h2>

      <.form for={@form} id="todo-form" phx-change={@on_change} phx-submit={@on_submit}>
        <div class="flex space-x-3">
          <div class="flex-1">
            <.input
              field={@form[:title]}
              type="text"
              placeholder="What needs to be done? Use #hashtags for categories"
              class="w-full px-4 py-3 text-gray-900 bg-white border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 placeholder-gray-500"
            />
          </div>
          <button
            type="submit"
            class="px-6 py-3 bg-blue-500 text-white font-medium rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
          >
            Add Todo
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @doc """
  Renders an importance badge (star icon).
  """
  attr :important, :boolean, required: true

  def importance_badge(assigns) do
    ~H"""
    <%= if @important do %>
      <span class="inline-flex items-center text-yellow-500" title="Important">
        <.icon name="hero-star" class="w-4 h-4 fill-current" />
      </span>
    <% end %>
    """
  end

  @doc """
  Renders a category badge for hashtags.
  """
  attr :category, :map, required: true

  def category_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center px-2 py-1 text-xs font-medium bg-purple-100 text-purple-800 rounded-full">
      #{@category.name}
    </span>
    """
  end
end
