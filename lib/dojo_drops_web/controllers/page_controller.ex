defmodule DojoDropsWeb.PageController do
  use DojoDropsWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
