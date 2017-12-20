defmodule ChangeDetectionClient do
  @callback global_change_detected(pid) :: any
  @callback resource_change_detected(pid, [String.t]) :: any
end

defmodule ChangeDetection do

  @dropbox_get_latest_cursor_url "https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor"
  @dropbox_list_folder_continue_cursor_url "https://api.dropboxapi.com/2/files/list_folder/continue"
  @dropbox_longpoll_url "https://notify.dropboxapi.com/2/files/list_folder/longpoll"


  use GenServer

  def start_link(client_module, client_pid, dropbox_access_token, dropbox_share_url) do
    GenServer.start_link(__MODULE__,
      {client_module, client_pid, dropbox_access_token, dropbox_share_url})
  end

  # genserver callbacks
  def init {client_module, client_pid, dropbox_access_token, dropbox_share_url} do
    GenServer.cast(self(), :init_poll)
    GenServer.cast(self(), :poll)

    {:ok, %{
      client_module: client_module,
      client_pid: client_pid,
      dropbox_access_token: dropbox_access_token,
      dropbox_share_url: dropbox_share_url
    }}
  end

  def handle_cast(:init_poll, state) do
    cursor = get_latest_cursor(state.dropbox_access_token, state.dropbox_share_url)
    {:noreply, Map.put(state, :cursor, cursor)}
  end

  def handle_cast(:get_changes, state) do

    {cursor, entries} = get_changes(state.dropbox_access_token, state.cursor)
    on_change(state, entries)

    {:noreply, Map.put(state, :cursor, cursor)}
  end

  def handle_cast(:poll, state) do
    poll(state.dropbox_access_token, state.cursor)
    {:noreply, state}
  end

  # private functions
  defp get_latest_cursor(dropbox_access_token, dropbox_share_url) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> dropbox_access_token}
    ]

    payload = %{
      shared_link: %{url: dropbox_share_url},
      path: ""
    }

    dropbox_api_post(
      @dropbox_get_latest_cursor_url,
      headers,
      payload)["cursor"]
  end

  defp get_changes(dropbox_access_token, cursor) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> dropbox_access_token}
    ]

    payload = %{
      cursor: cursor
    }

    result = %{"cursor" => cursor, "entries" => entries} = dropbox_api_post(
      @dropbox_list_folder_continue_cursor_url,
      headers,
      payload)
    {cursor, Enum.map(entries, &(String.downcase(&1["name"])))}
  end



  defp poll(dropbox_access_token, cursor) do
    headers = [
      {"Content-Type", "application/json"},
    ]

    payload = %{
      cursor: cursor,
      timeout: 30
    }

    response = dropbox_api_post(
      @dropbox_longpoll_url,
      headers,
      payload,
      recv_timeout: 60 * 1000)

    if response["changes"] do
      #on_change()
      # Refetch latest cursor, and poll again
      GenServer.cast(self(), :get_changes)
    end
    #start polling
    GenServer.cast(self(), :poll)
  end

  defp dropbox_api_post(url, headers, payload, options \\ []) do
    {:ok, body} = Poison.encode(payload)

    {:ok, %HTTPoison.Response{status_code: 200, body: response_body}}
      = HTTPoison.post(url, body, headers, options)

    Poison.decode!(response_body)
  end

  defp on_change(state, []) do
    state.client_module.global_change_detected(state.client_pid)
  end
  defp on_change(state, resource_names) do
    state.client_module.resource_change_detected(state.client_pid, resource_names)
  end
end