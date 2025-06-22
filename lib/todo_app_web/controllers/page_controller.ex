defmodule TodoAppWeb.PageController do
  use TodoAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
