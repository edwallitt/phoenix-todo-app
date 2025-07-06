defmodule TodoApp.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Index for category lookups by slug (unique constraint)
    create unique_index(:categories, [:slug])

    # Index for filtering todos by completion status
    create index(:todos, [:completed])

    # Index for ordering todos by insertion order
    create index(:todos, [:inserted_at])

    # Composite index for completed todos ordered by date
    create index(:todos, [:completed, :inserted_at])

    # Index for notes lookup by todo_id (foreign key)
    create index(:notes, [:todo_id])

    # Index for notes ordering by creation date
    create index(:notes, [:inserted_at])

    # Indexes for the many-to-many relationship
    create index(:todo_categories, [:category_id])
    create index(:todo_categories, [:todo_id])

    # Composite index for efficient join queries
    create index(:todo_categories, [:todo_id, :category_id])
  end
end
