# NEJM-Style Todo App with Hashtag Categories Plan

- [x] Generate a Phoenix LiveView project called `todo_app` 
- [x] Start the server to follow along with development
- [x] Replace default home page with static NEJM-inspired design mockup
- [x] Create Todo schema and migration with:
  - `title` (string, required)
  - `completed` (boolean, default false)
  - `inserted_at` and `updated_at` timestamps
- [x] Create Category schema and TodoCategory join table for many-to-many relationships
- [x] Implement TodoLive LiveView with real-time PubSub updates:
  - `mount/3` - load all todos and assign form
  - `handle_event("add_todo", ...)` - create new todo with hashtag parsing
  - `handle_event("toggle_todo", ...)` - toggle completion, broadcast update  
  - `handle_event("delete_todo", ...)` - delete todo, broadcast update
  - `handle_event("filter_by_category", ...)` - filter todos by category
  - `handle_event("validate", ...)` - validate form inputs
- [x] Enhanced Todos context with hashtag parsing:
  - `parse_hashtags_from_title/1` - extract #hashtags from todo text
  - `find_or_create_category/1` - get existing or create new category
  - `associate_todo_with_categories/2` - link todo to categories via join table
  - `list_todos/1` - filter todos by category (optional parameter)
  - `list_categories/0` - get all existing categories
- [x] Create todo_live.html.heex template with modern clinical design:
  - Clean form for adding todos with hashtag support
  - Category filter buttons with active state styling
  - Category pills displayed on each todo
  - List of todos with toggle/delete actions
  - Mobile-responsive layout
  - Green accent colors for actions and category styling
- [x] Update layouts to match NEJM clinical aesthetic:
  - Force light theme in root.html.heex
  - Remove default Phoenix styling from <Layouts.app>
  - Update app.css with clinical colors and typography
- [x] Update router (replace home route with todo route)
- [x] Test hashtag parsing functionality ("Buy groceries #shopping #weekend")
- [x] Test category filtering and UI interactions
- [x] Final verification and cleanup

## Features Working:
✅ Automatic hashtag parsing (#work, #personal, etc.)
✅ Clean todo titles (hashtags removed after parsing)
✅ Category creation and association
✅ Real-time category filtering
✅ Beautiful category pills with clinical styling
✅ All original todo functionality (add, toggle, delete)

