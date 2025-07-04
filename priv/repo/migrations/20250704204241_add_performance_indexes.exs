defmodule TodoApp.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Composite index for todos filtering and ordering
    # Optimizes: ORDER BY important DESC, inserted_at DESC
    create index(:todos, [:important, :inserted_at])

    # Index for category slug lookups (very common in filtering)
    # Optimizes: WHERE c.slug = ?
    create index(:categories, [:slug]) unless index_exists?(:categories, [:slug])

    # Composite index for todo-category joins with category filtering
    # Optimizes: JOIN todo_categories ON todo_id AND category_id
    create index(:todo_categories, [:category_id, :todo_id])

    # Index for notes ordering by todo
    # Optimizes: WHERE todo_id = ? ORDER BY inserted_at DESC
    create index(:notes, [:todo_id, :inserted_at])

    # Index for completed todos filtering
    # Optimizes: WHERE completed = true/false
    create index(:todos, [:completed])

    # Composite index for category todo counts
    # Optimizes: COUNT(*) WHERE category_id = ?
    create index(:todo_categories, [:category_id]) unless index_exists?(:todo_categories, [:category_id])

    # Index for orphaned category cleanup queries
    # Optimizes: Finding categories with no todos
    create index(:todo_categories, [:todo_id]) unless index_exists?(:todo_categories, [:todo_id])

    # Partial index for important todos only (space efficient)
    # Optimizes: WHERE important = true
    create index(:todos, [:inserted_at], where: "important = true", name: :todos_important_inserted_at_idx)

    # Index for recent notes queries
    create index(:notes, [:inserted_at])
  end
end
