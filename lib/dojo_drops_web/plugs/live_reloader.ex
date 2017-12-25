defmodule DojoDropsWeb.LiveReloader do

  import Plug.Conn

  @behaviour Plug

  reload_path  = Application.app_dir(:dojo_drops, "priv/static/js/app.js")
  @external_resource reload_path
  @live_reload_js File.read!(reload_path)

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{path_info: ["__live_reload", "frame", drop_id | resource_name]} = conn , _) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
      <html><body>
      <script>
        document.liveReloadChannel='live_reload:#{drop_id}';
        #{@live_reload_js}
      </script>
      </body></html>
    """)
    |> halt()
  end

  def call(conn, _) do
    endpoint = conn.private.phoenix_endpoint
    before_send_inject_reloader(conn, endpoint)
  end

  defp before_send_inject_reloader(conn, endpoint) do
    register_before_send(conn, fn conn ->
      drop_id = conn.assigns[:drop_id]
      resource_name = conn.assigns[:resource_name]
      if conn.resp_body != nil && html?(conn) && drop_id && resource_name do
        resp_body = IO.iodata_to_binary(conn.resp_body)
        if has_body?(resp_body) and :code.is_loaded(endpoint) do
          [page | rest] = String.split(resp_body, "</body>")
          body = page <> reload_assets_tag(conn, drop_id, resource_name) <> Enum.join(["</body>" | rest], "")
          put_in conn.resp_body, body
        else
          put_in conn.resp_body, resp_body <> reload_assets_tag(conn, drop_id, resource_name)
        end
      else
        conn
      end
    end)
  end

  defp html?(conn) do
    case get_resp_header(conn, "content-type") do
      [] -> false
      [type | _] -> String.starts_with?(type, "text/html")
    end
  end

  defp has_body?(resp_body), do: String.contains?(resp_body, "<body")

  defp reload_assets_tag(conn, drop_id, resource_name) do
    path = conn.private.phoenix_endpoint.path("/__live_reload/frame//#{drop_id}/#{resource_name}")
    """
    <iframe src="#{path}" style="display: none;"></iframe>
    """
  end
end
