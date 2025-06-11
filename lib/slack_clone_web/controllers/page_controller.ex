defmodule SlackCloneWeb.PageController do
  use SlackCloneWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/channels")
    else
      redirect(conn, to: ~p"/users/log_in")
    end
  end
end
