defmodule DojoDropsWeb.DropController do

  use DojoDropsWeb, :controller

  def home(conn, %{"drop_id" => drop_id}) do
    if String.ends_with?(conn.request_path, "/") do
      respond_with_content(conn, drop_id, "index.html")
    else
      redirect(conn, to: conn.request_path <> "/")
    end
  end

  def resource(conn, %{"drop_id" => drop_id, "resource_name" => resource_name}) do
    respond_with_content(conn, drop_id, resource_name)
  end

  defp respond_with_content(conn, drop_id, path) do
    resource_name = create_resource_name(path)
    content_fetch = DropServer.get_fetch_fun(drop_id, resource_name)
    extension = List.last String.split(resource_name, ".")

    conn
    |> assign(:drop_id, drop_id)
    |> assign(:resource_name, resource_name)
    # |> html("<html><body>hallo</body></html>")
    |> put_resp_header("content-type", MIME.type(extension))
    |> send_resp(200, content_fetch.().body)
  end

  def create_resource_name(path) when is_list(path), do: Enum.join(path, "/")
  def create_resource_name(path) do
    path
  end
end