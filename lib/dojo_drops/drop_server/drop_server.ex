defmodule DropServer do
  use GenServer

  def init drop_id do
    token = Application.get_env(:dojo_drops, :dropbox)[:access_token]
    # Following is a stub share url
    drop_share_url = System.get_env("DROPBOX_SHARE_URL")
    ChangeDetection.start_link(token, drop_share_url)
    {:ok, %{
      drop_id: drop_id,
      drop_share_url: drop_share_url,
      resource_server_pids: %{},
      access_token: token
    }}
  end

  def get_fetch_fun(drop_id, resource) do
    via_tuple(drop_id)
    |> ensure_server()
    |> GenServer.call({:get_fetch_fun, resource})
  end

  # Genserver callbacks
  def handle_call({:get_fetch_fun, resource_name}, _from, state) do
    #fetch resource here
    {content_func, new_state} = lookup_or_create_fetch_fun(state, resource_name)
    {:reply, content_func, new_state}
  end

  # Private functions
  defp via_tuple(drop_id) do
    {:via, Registry, {:drop_server_registry, drop_id}}
  end

  defp lookup_or_create_fetch_fun(state, resource_name) do
    new_state = case Map.get(state.resource_server_pids, resource_name) do
      nil ->
        {:ok, resource_server} = ResourceServer.start_link(
          state.access_token, state.drop_share_url, resource_name)
        new_pids = Map.put(state.resource_server_pids, resource_name, resource_server)
        %{state | resource_server_pids: new_pids}
      _pid -> state
    end
    resource_server_pid = new_state.resource_server_pids[resource_name]

    {fn -> ResourceServer.fetch(resource_server_pid) end, new_state}
  end

  defp ensure_server(name = {:via, Registry, {:drop_server_registry, drop_id}}) do
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

end