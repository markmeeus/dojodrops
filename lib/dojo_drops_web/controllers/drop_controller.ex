defmodule DojoDropsWeb.DropController do

  use DojoDropsWeb, :controller

  def home(conn, %{"drop_id" => drop_id}) do
    respond_with_content(conn, drop_id, "index.html")
  end

  def resource(conn, %{"drop_id" => drop_id, "resource" => resource}) do
    respond_with_content(conn, drop_id, resource)
  end

  defp respond_with_content(conn, drop_id, resource) do
    content_fetch = DropServer.get_fetch_fun(drop_id, resource)
    send_resp(conn, 200, content_fetch.())
  end
end