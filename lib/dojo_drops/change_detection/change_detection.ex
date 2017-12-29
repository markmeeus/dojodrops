defmodule ChangeDetectionClient do
  @callback global_change_detected(pid) :: any
  @callback resource_change_detected(pid, [String.t]) :: any
end

defmodule ChangeDetection do

  use GenServer

  def start_link(client_module, client_pid, dropbox_access_token, dropbox_share_url) do
    {:ok, dropbox_client} = DropBox.Client.start_link(dropbox_access_token)
    GenServer.start_link(__MODULE__,
      {client_module, client_pid, dropbox_client, dropbox_share_url})
  end

  # genserver callbacks
  def init {client_module, client_pid, dropbox_client, dropbox_share_url} do
    GenServer.cast(self(), :init_poll)
    GenServer.cast(self(), :poll)

    {:ok, %{
      client_module: client_module,
      client_pid: client_pid,
      dropbox_client: dropbox_client,
      dropbox_share_url: dropbox_share_url
    }}
  end

  def handle_cast(:init_poll, state) do
    cursor = get_latest_cursor(state.dropbox_client, state.dropbox_share_url)
    {:noreply, Map.put(state, :cursor, cursor)}
  end

  def handle_cast(:get_changes, state) do

    {cursor, entries} = get_changes(state.dropbox_client, state.cursor)
    on_change(state, entries)

    {:noreply, Map.put(state, :cursor, cursor)}
  end

  def handle_cast(:poll, state) do
    poll(state.dropbox_client, state.cursor)
    {:noreply, state}
  end

  # private functions
  defp get_latest_cursor(dropbox_client, dropbox_share_url) do
    DropBox.Client.get_latest_cursor(dropbox_client, dropbox_share_url)
  end

  defp get_changes(dropbox_client, cursor) do
    DropBox.Client.get_changes(dropbox_client, cursor)

  end

  defp poll(dropbox_client, cursor) do
    response = DropBox.Client.poll(dropbox_client, cursor)
    if response["changes"] do
      #on_change()
      # Refetch latest cursor, and poll again
      GenServer.cast(self(), :get_changes)
    end
    #start polling
    GenServer.cast(self(), :poll)
  end

  defp on_change(state, []) do
    state.client_module.global_change_detected(state.client_pid)
  end
  defp on_change(state, resource_names) do
    state.client_module.resource_change_detected(state.client_pid, resource_names)
  end
end