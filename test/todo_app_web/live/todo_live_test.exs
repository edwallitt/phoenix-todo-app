defmodule TodoAppWeb.TodoLiveTest do
  use TodoAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import TodoApp.TodosFixtures

  alias TodoApp.Todos

  describe "mount" do
    test "displays empty state when no todos exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Clinical Todo"
      assert html =~ "A clean, focused task management system"
      assert html =~ "Add a new task"
    end

    test "displays existing todos with categories", %{conn: conn} do
      todo = todo_fixture(%{title: "Buy groceries"})
      category = category_fixture(%{name: "shopping"})
      Todos.associate_todo_with_categories(todo, [category])

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Buy groceries"
      assert html =~ "#shopping"
    end

    test "displays category filter buttons", %{conn: conn} do
      todo = todo_fixture(%{title: "Clean house"})
      category = category_fixture(%{name: "chores"})
      Todos.associate_todo_with_categories(todo, [category])

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "All"
      assert html =~ "chores"
    end
  end

  describe "add_todo" do
    test "creates a new todo with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> form("#todo-form", todo: %{title: "New task"})
             |> render_submit()

      html = render(view)
      assert html =~ "New task"
    end

    test "parses hashtags and creates categories", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> form("#todo-form", todo: %{title: "Study for exam #education #urgent"})
             |> render_submit()

      html = render(view)
      assert html =~ "Study for exam"
      assert html =~ "#education"
      assert html =~ "#urgent"
      assert html =~ "education"
      assert html =~ "urgent"
    end

    test "shows validation errors for empty title", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#todo-form", todo: %{title: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "validates todo on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#todo-form", todo: %{title: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "toggle_todo" do
    test "toggles todo completion status", %{conn: conn} do
      todo = todo_fixture(%{title: "Complete task", completed: false})

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button[phx-click='toggle_todo'][phx-value-id='#{todo.id}']")
      |> render_click()

      updated_todo = Todos.get_todo!(todo.id)
      assert updated_todo.completed == true

      html = render(view)
      assert html =~ "line-through"
    end

    test "untoggle completed todo", %{conn: conn} do
      todo = todo_fixture(%{title: "Complete task", completed: true})

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button[phx-click='toggle_todo'][phx-value-id='#{todo.id}']")
      |> render_click()

      updated_todo = Todos.get_todo!(todo.id)
      assert updated_todo.completed == false

      html = render(view)
      refute html =~ "line-through"
    end
  end

  describe "delete_todo" do
    test "deletes a todo", %{conn: conn} do
      todo = todo_fixture(%{title: "Delete me"})

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button[phx-click='delete_todo'][phx-value-id='#{todo.id}']")
      |> render_click()

      html = render(view)
      refute html =~ "Delete me"

      assert_raise Ecto.NoResultsError, fn ->
        Todos.get_todo!(todo.id)
      end
    end

    test "deletes todo with categories", %{conn: conn} do
      todo = todo_fixture(%{title: "Clean kitchen"})
      category = category_fixture(%{name: "chores"})
      Todos.associate_todo_with_categories(todo, [category])

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button[phx-click='delete_todo'][phx-value-id='#{todo.id}']")
      |> render_click()

      html = render(view)
      refute html =~ "Clean kitchen"
      refute html =~ "#chores"
    end
  end

  describe "inline editing" do
    test "starts edit mode when clicking on todo", %{conn: conn} do
      todo = todo_fixture(%{title: "Edit me"})

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      html = render(view)
      assert html =~ "edit-todo-form-#{todo.id}"
      assert html =~ "Save"
      assert html =~ "Cancel"
    end

    test "reconstructs hashtags in edit field", %{conn: conn} do
      todo = todo_fixture(%{title: "Buy groceries"})
      category1 = category_fixture(%{name: "shopping"})
      category2 = category_fixture(%{name: "weekend"})
      Todos.associate_todo_with_categories(todo, [category1, category2])

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      html = render(view)
      # Check that the edit field contains the reconstructed title with hashtags
      assert html =~ "Buy groceries #shopping #weekend" or
               html =~ "Buy groceries #weekend #shopping"
    end

    test "saves edited todo with new hashtags", %{conn: conn} do
      todo = todo_fixture(%{title: "Original task"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Start editing
      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      # Submit edit with new title and hashtags
      view
      |> form("#edit-todo-form-#{todo.id}", todo: %{title: "Updated task #work #urgent"})
      |> render_submit()

      html = render(view)
      assert html =~ "Updated task"
      assert html =~ "#work"
      assert html =~ "#urgent"
      refute html =~ "Original task"

      # Verify database was updated
      updated_todo = Todos.get_todo!(todo.id)
      assert updated_todo.title == "Updated task"
    end

    test "cancels edit mode", %{conn: conn} do
      todo = todo_fixture(%{title: "Don't edit me"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Start editing
      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      # Cancel editing
      view
      |> element("button[phx-click='cancel_edit']")
      |> render_click()

      html = render(view)
      refute html =~ "edit-todo-form-#{todo.id}"
      refute html =~ "Save"
      refute html =~ "Cancel"
      assert html =~ "Don&#39;t edit me"
    end

    test "hides add todo form during edit mode", %{conn: conn} do
      todo = todo_fixture(%{title: "Edit me"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Start editing
      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      html = render(view)
      # The add todo form should be hidden during edit mode
      refute html =~ "Add a new task... (use #hashtags for categories)"
    end

    test "shows add todo form after editing complete", %{conn: conn} do
      todo = todo_fixture(%{title: "Edit me"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Start editing
      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      # Save edit
      view
      |> form("#edit-todo-form-#{todo.id}", todo: %{title: "Edited"})
      |> render_submit()

      html = render(view)
      assert html =~ "todo-form"
    end
  end

  describe "category filtering" do
    test "filters todos by category", %{conn: conn} do
      todo1 = todo_fixture(%{title: "Work task"})
      todo2 = todo_fixture(%{title: "Home task"})

      work_category = category_fixture(%{name: "work"})
      home_category = category_fixture(%{name: "home"})

      Todos.associate_todo_with_categories(todo1, [work_category])
      Todos.associate_todo_with_categories(todo2, [home_category])

      {:ok, view, _html} = live(conn, ~p"/")

      # Filter by work category
      view
      |> element("button[phx-click='filter_by_category'][phx-value-category='work']")
      |> render_click()

      html = render(view)
      assert html =~ "Work task"
      refute html =~ "Home task"

      # Filter by home category
      view
      |> element("button[phx-click='filter_by_category'][phx-value-category='home']")
      |> render_click()

      html = render(view)
      assert html =~ "Home task"
      refute html =~ "Work task"
    end

    test "shows all todos when filtering by 'all'", %{conn: conn} do
      todo1 = todo_fixture(%{title: "Work task"})
      todo2 = todo_fixture(%{title: "Home task"})

      work_category = category_fixture(%{name: "work"})
      home_category = category_fixture(%{name: "home"})

      Todos.associate_todo_with_categories(todo1, [work_category])
      Todos.associate_todo_with_categories(todo2, [home_category])

      {:ok, view, _html} = live(conn, ~p"/")

      # Filter by work first
      view
      |> element("button[phx-click='filter_by_category'][phx-value-category='work']")
      |> render_click()

      # Then filter by all
      view
      |> element("button[phx-click='filter_by_category'][phx-value-category='all']")
      |> render_click()

      html = render(view)
      assert html =~ "Work task"
      assert html =~ "Home task"
    end

    test "highlights active filter button", %{conn: conn} do
      todo = todo_fixture(%{title: "Work task"})
      category = category_fixture(%{name: "work"})
      Todos.associate_todo_with_categories(todo, [category])

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button[phx-click='filter_by_category'][phx-value-category='work']")
      |> render_click()

      html = render(view)
      assert html =~ "bg-green-100 text-green-800"
    end
  end

  describe "validation" do
    test "validates edit form on change", %{conn: conn} do
      todo = todo_fixture(%{title: "Edit me"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Start editing
      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      # Change to empty title
      html =
        view
        |> form("#edit-todo-form-#{todo.id}", todo: %{title: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "prevents saving edit with invalid data", %{conn: conn} do
      todo = todo_fixture(%{title: "Edit me"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Start editing
      view
      |> element("div[phx-click='start_edit'][phx-value-id='#{todo.id}']")
      |> render_click()

      # Try to submit empty title
      html =
        view
        |> form("#edit-todo-form-#{todo.id}", todo: %{title: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      # Should still be in edit mode
      assert html =~ "edit-todo-form-#{todo.id}"
    end
  end
end
