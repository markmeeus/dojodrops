defmodule DropServer.ChangeListener do
  @callback global_change(pid, String.t) :: any
  @callback resource_change(pid, String.t, String.t) :: any
end

defmodule DropServer do
  use GenServer
  @behaviour ChangeDetectionClient

  def init {drop_id, drop_share_url} do
    token = Application.get_env(:dojo_drops, :dropbox)[:access_token]
    ChangeDetection.start_link(__MODULE__, self(), token, drop_share_url)

    {:ok, %{
      drop_id: drop_id,
      drop_share_url: drop_share_url,
      resource_server_pids: %{},
      access_token: token,
      change_listeners: %{}
    }}
  end

  def get_content(drop_id, resource) do
    fetch_fun = via_tuple(drop_id)
    |> ensure_server()
    |> GenServer.call({:get_fetch_fun, resource})
    fetch_fun.()
  end

  def register_for_change(module, pid, drop_id) do
    GenServer.cast(via_tuple(drop_id), {:register_for_change, module, pid})
  end
  # ChangeDetectionClient callbacks
  def global_change_detected pid do
    GenServer.cast(pid, {:global_change_detected})
  end
  def resource_change_detected pid, resource_names do
    GenServer.cast(pid, {:resource_change_detected, resource_names})
  end

  # Genserver callbacks
  def handle_call({:get_fetch_fun, resource_name}, _from, state) do
    #fetch resource here
    {content_func, new_state} = lookup_or_create_fetch_fun(state, resource_name)
    {:reply, content_func, new_state}
  end

  def handle_cast({:register_for_change, module, pid}, state) do
    Process.monitor(pid)
    new_change_listeners = Map.put(state.change_listeners, pid, {module, pid})
    {:noreply, %{state | change_listeners: new_change_listeners}}
  end

  def handle_cast({:global_change_detected}, state) do
    Enum.each(state.resource_server_pids, fn {_resource_name, pid} ->
      ResourceServer.reset(pid)
    end)
    Enum.each state.change_listeners, fn {pid, {module, pid}} ->
      module.global_change(pid, state.drop_id)
    end
    {:noreply, state}
  end

  def handle_cast({:resource_change_detected, resource_names}, state) do
    Enum.each(resource_names, fn resource_name ->
      case(state.resource_server_pids[resource_name]) do
        nil -> nil
        resource_server_pid ->
          ResourceServer.reset(resource_server_pid)
      end
      Enum.each state.change_listeners, fn {pid, {module, pid}} ->
        module.resource_change(pid, state.drop_id, resource_name)
      end
    end)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_change_listeners = Map.delete(state.change_listeners, pid)
    {:noreply, %{state | change_listeners: new_change_listeners}}
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
        case DropRegistry.get_share_url_for_drop_id(drop_id) do
          nil -> nil
          share_url -> start_server(name, share_url)
        end

      _ -> nil
    end
    name
  end

  defp start_server(name = {:via, Registry, {:drop_server_registry, drop_id}}, share_url) do
    GenServer.start_link(__MODULE__, {drop_id, share_url}, name: name)
  end
end