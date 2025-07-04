# Clinical Todo App

A modern, real-time todo application built with Phoenix LiveView, featuring intelligent hashtag parsing, rich markdown notes, and a clean clinical design inspired by medical journals.

## 🚀 Live Demo

**Production App:** https://todo-app-still-shadow-1422.fly.dev

## ✨ Features

### 📝 Smart Todo Management
- **Intelligent Hashtag Parsing:** Add todos like "Buy groceries #shopping #weekend" - hashtags automatically become categories
- **Real-time Updates:** Changes sync instantly across all browser tabs using Phoenix PubSub
- **Clean Todo Titles:** Hashtags are extracted and removed from display titles for clean presentation

### 📂 Category System
- **Auto-Generated Categories:** Categories created automatically from hashtags in todo titles
- **Category Filtering:** Click any category to filter todos instantly
- **Category Management:** Dedicated `/categories` page to view and manage all categories
- **Smart Deletion:** Deleting categories removes associations but preserves todos

### 📋 Rich Notes System
- **Markdown Support:** Full markdown rendering with syntax highlighting
- **Per-Todo Notes:** Each todo can have detailed notes accessible via `/todos/:id/notes`
- **Live Preview:** Real-time markdown preview as you type
- **Clinical Styling:** Clean, readable formatting optimized for professional use

### 🎨 Professional Design
- **Clinical UI:** Clean, minimal design inspired by medical journals (NEJM-style)
- **Responsive Layout:** Works perfectly on desktop, tablet, and mobile
- **Accessibility:** Proper contrast ratios and semantic HTML
- **Modern Interactions:** Smooth animations and hover effects

## 🛠 Tech Stack

### Backend
- **Phoenix Framework 1.8+** - Modern web framework for Elixir
- **Phoenix LiveView** - Real-time, interactive web applications
- **Ecto & PostgreSQL** - Database ORM and robust data persistence
- **PubSub** - Real-time updates across browser sessions

### Frontend
- **Tailwind CSS v4** - Utility-first CSS framework
- **DaisyUI** - Component library for consistent styling
- **Alpine.js** (via LiveView) - Reactive frontend interactions
- **Heroicons** - Beautiful SVG icons

### Infrastructure
- **Fly.io** - Production deployment platform
- **PostgreSQL** - Production database
- **Docker** - Containerized deployment

## 🚀 Quick Start

### Prerequisites
- Elixir 1.15+
- Phoenix 1.8+
- PostgreSQL (for production) or SQLite (for development)
- Node.js (for asset compilation)

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/edwallitt/phoenix-todo-app.git
   cd phoenix-todo-app
   ```

2. **Install dependencies:**
   ```bash
   mix setup
   ```

3. **Start the development server:**
   ```bash
   mix phx.server
   ```

4. **Visit the app:**
   Open [http://localhost:4000](http://localhost:4000) in your browser

### Database Setup

The app uses PostgreSQL in production and can use SQLite for development. Migrations are included for both.

**Run migrations:**
```bash
mix ecto.migrate
```

**Seed sample data (optional):**
```bash
mix run priv/repo/seeds.exs
```

## 🌐 Production Deployment

### Deploy to Fly.io

1. **Install Fly CLI:**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login to Fly.io:**
   ```bash
   fly auth login
   ```

3. **Deploy the application:**
   ```bash
   fly deploy
   ```

4. **Set up the database:**
   ```bash
   fly postgres create
   fly postgres attach <postgres-app-name>
   ```

5. **Run migrations:**
   ```bash
   fly ssh console
   /app/bin/todo_app eval "TodoApp.Release.migrate"
   ```

### Environment Variables

The following environment variables are required for production:

- `DATABASE_URL` - PostgreSQL connection string (automatically set by Fly.io)
- `SECRET_KEY_BASE` - Phoenix secret key (automatically generated)
- `PHX_HOST` - Your production domain

## 📁 Project Structure

```
lib/
├── todo_app/                 # Business logic
│   ├── todos/               # Todo domain
│   │   ├── todo.ex         # Todo schema
│   │   ├── category.ex     # Category schema
│   │   ├── todo_category.ex # Join table
│   │   └── note.ex         # Note schema
│   └── todos.ex            # Context module
├── todo_app_web/           # Web interface
│   ├── live/               # LiveView modules
│   │   ├── todo_live.ex    # Main todo interface
│   │   ├── category_live.ex # Category management
│   │   └── notes_live.ex   # Notes interface
│   └── components/         # Reusable components
priv/repo/migrations/       # Database migrations
assets/                     # Frontend assets
```

## 🧪 Testing

Run the test suite:
```bash
mix test
```

Run tests with coverage:
```bash
mix test --cover
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Links

- **Live App:** https://todo-app-still-shadow-1422.fly.dev
- **Repository:** https://github.com/edwallitt/phoenix-todo-app
- **Phoenix Framework:** https://phoenixframework.org
- **Fly.io:** https://fly.io
