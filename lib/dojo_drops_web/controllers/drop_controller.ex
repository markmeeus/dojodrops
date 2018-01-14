defmodule DojoDropsWeb.DropController do

  @content_not_found "Oooops, this page appears to be missing."
  @content_too_large "Content is too large"

  use DojoDropsWeb, :controller

  def home(conn, %{"drop_id" => drop_id}) do
    if String.ends_with?(conn.request_path, "/") do
      respond_with_content(conn, drop_id, "index.html")
    else
      redirect(conn, to: conn.request_path <> "/")
    end
  end

  #blocks access to confif folder
  def resource(conn, %{"drop_id" => drop_id, "resource_name" => ["config", _]}) do
    send_resp(conn, 404, @content_not_found)
  end
  def resource(conn, %{"drop_id" => drop_id, "resource_name" => resource_name}) do
    if(access_allowed(conn, drop_id)) do
      respond_with_content(conn, drop_id, resource_name)
    else
      conn
      |> put_resp_header("WWW-Authenticate", "Basic")
      |> send_resp(401, "")
    end
  end

  defp respond_with_content(conn, drop_id, path) do
    resource_name = path
    |> stringify_path()
    |> String.downcase()

    {status, content} = DropServer.get_content(drop_id, resource_name)
    extension = List.last String.split(resource_name, ".")

    {status_code, resp_content, content_type} = case status do
      :ok -> {200, content.body, MIME.type(extension)}
      :too_large -> {409, @content_too_large, "text/html"}
      :not_found -> {404, @content_not_found, "text/html"}
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

  defp access_allowed(conn, drop_id) do
    case DropServer.get_content(drop_id, "config/users.txt") do
      {:not_found, users} -> true
      {:ok, users} -> conn
        |> get_req_header("authorization")
        |> credentials_match?(users)
      _  -> false #block access by default
    end
  end

  defp credentials_match?(["Basic " <> encoded_credentials], %{body: users}) do
    {:ok, credentials} = Base.decode64(encoded_credentials)
    users
    |> String.split("\n")
    |> Enum.find(&(&1 == credentials))
  end
  defp credentials_match?(_, _), do: false
end