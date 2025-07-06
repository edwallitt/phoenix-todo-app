defmodule TodoAppWeb.PageControllerTest do
  use TodoAppWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Ed's Todo List"
  end
end
