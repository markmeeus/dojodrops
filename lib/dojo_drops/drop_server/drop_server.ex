defmodule DropServer do
  use GenServer

  def init drop_id do
    token = Application.get_env(:dojo_drops, :dropbox)[:access_token]
    #following is a stub share url
    drop_share_url = System.get_env("DROPBOX_SHARE_URL")
    {:ok, %{
      drop_id: drop_id,
      drop_share_url: drop_share_url,
      cache: %{},
      access_token: token,
      client: ElixirDropbox.Client.new(token)}}
  end

  def get_fetch_fun(drop_id, resource) do
    via_tuple(drop_id)
    |> ensure_server()
    |> GenServer.call({:get_fetch_fun, resource})
  end

  #genserver callback
  def handle_call({:get_fetch_fun, resource}, _from, state) do
    #fetch resource here
    {content_func, new_state} = lookup_or_create_fetch_fun(state, resource)
    {:reply, content_func, new_state}
  end

  def handle_cast({:update_cache, resource, content_fun}, state) do
    new_state = %{state | cache: Map.put(state.cache, resource, content_fun) }
    {:noreply, new_state}
  end

  #private funcs
  defp via_tuple(drop_id) do
    {:via, Registry, {:drop_server_registry, drop_id}}
  end

  defp lookup_or_create_fetch_fun state, resource do
    new_state = case Map.get(state.cache, resource) do
      nil ->
        fetch_func =  build_fetch_fun(resource, state)
        %{state | cache: Map.put(state.cache, resource, fetch_func) }
      _ -> state
    end
    {new_state.cache[resource], new_state}
  end

  def ensure_server(name = {:via, Registry, {:drop_server_registry, drop_id}}) do
    case Registry.lookup :drop_server_registry, drop_id do
      [] -> #process not found, let's start it
        start_server(name)
      _ -> nil
    end
    name
  end

  defp start_server(name = {:via, Registry, {:drop_server_registry, drop_id}}) do
    GenServer.start_link(__MODULE__, drop_id, name: name)
  end

  @dropbox_content_url "https://content.dropboxapi.com/2/sharing/get_shared_link_file"

  defp build_fetch_fun(resource, state) do
    fn ->
      {:ok, dropbox_api_args} = Poison.encode(%{
        url: state.drop_share_url,
        path: "/" <> resource
      })

      headers = [
        {"Authorization", "Bearer " <> state.access_token},
        {"Dropbox-API-Arg", dropbox_api_args}
      ]
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}
        = HTTPoison.post @dropbox_content_url, "", headers

      GenServer.cast(via_tuple(state.drop_id), {:update_cache, resource, fn -> body end})

      body
    end
  end
end