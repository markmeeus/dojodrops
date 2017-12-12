defmodule DojoDropsWeb.DropController do

  use DojoDropsWeb, :controller

  def home(conn, %{"drop_id" => drop_id}) do
    respond_with_content(conn, drop_id, "index.html")
  end

  def resource(conn, %{"drop_id" => drop_id, "resource_name" => resource_name}) do
    respond_with_content(conn, drop_id, resource_name)
  end

  defp respond_with_content(conn, drop_id, resource) do
    content_fetch = DropServer.get_fetch_fun(drop_id, resource)
    extension = List.last String.split(resource, ".")
    conn
    |> put_resp_header("content-type", MIME.type(extension))
    |> send_resp(200, content_fetch.().body)
  end
end