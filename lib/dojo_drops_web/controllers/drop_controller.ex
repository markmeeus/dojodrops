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
    resource_name = path
    |> stringify_path()
    |> String.downcase()

    content_fetch = DropServer.get_fetch_fun(drop_id, resource_name)
    extension = List.last String.split(resource_name, ".")
    {status, content} = content_fetch.()

    {status_code, resp_content, content_type} = case status do
      :ok -> {200, content.body, MIME.type(extension)}
      :too_large -> {409, "Content is too large", "text/html"}
      :not_found -> {404, "Oooops, this page appears to be missing.", "text/html"}
      _ -> {500, "An error occured", "text/html"}
    end

    conn
    |> assign(:drop_id, drop_id)
    |> assign(:resource_name, resource_name)
    |> put_resp_header("content-type", content_type)
    |> send_resp(status_code, resp_content)
  end

  def stringify_path(path) when is_list(path), do: Enum.join(path, "/")
  def stringify_path(path), do: path
end