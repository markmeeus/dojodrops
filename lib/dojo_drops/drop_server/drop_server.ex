defmodule DropServer do
  use GenServer

  def init drop_id do
    {:ok, %{drop_id: drop_id, cache: %{}}}
  end

  def get_async(drop_id, resource) do
    via_tuple(drop_id)
    |> ensure_server()
    |> GenServer.call({:get_async, resource})
  end

  #genserver callback
  def handle_call({:get_async, resource}, _from, state) do
    #fetch resource here
    {content_func, new_state} = get_content_func(state, resource)
    {:reply, content_func, new_state}
  end

  #private funcs
  defp via_tuple(drop_id) do
    {:via, Registry, {:drop_server_registry, drop_id}}
  end

  defp get_content_func state, resource do
    new_state = case Map.get(state.cache, resource) do
      nil ->
        fetch_func =  build_fetch_func(resource)
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

  def build_fetch_func(resource) do
    #dropbox fetch happens here, returning resource name for testing purposes.
    fn ->  resource  end
  end
end