defmodule ChangeDetection do

  @dropbox_get_latest_cursor_url "https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor"
  @dropbox_longpoll_url "https://notify.dropboxapi.com/2/files/list_folder/longpoll"

  use GenServer

  def start_link(dropbox_access_token, dropbox_share_url) do
    GenServer.start_link(__MODULE__, {dropbox_access_token, dropbox_share_url})
  end

  # genserver callbacks
  def init {dropbox_access_token, dropbox_share_url} do
    GenServer.cast(self(), :init_poll)
    GenServer.cast(self(), :poll)

    {:ok, %{
      dropbox_access_token: dropbox_access_token,
      dropbox_share_url: dropbox_share_url
    }}
  end

  def handle_cast(:init_poll, state) do
    cursor = get_latest_cursor(state.dropbox_access_token, state.dropbox_share_url)
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
      on_change()
      # Refetch latest cursor, and poll again
      GenServer.cast(self(), :init_poll)
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

  defp on_change() do
    # Quite brutal, takes down the entire DropServer process tree
    Process.exit(self(), :kill)
  end
end