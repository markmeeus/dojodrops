defmodule DropBox.Client do

  @content_url "https://content.dropboxapi.com/2/sharing/get_shared_link_file"
  @get_latest_cursor_url "https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor"
  @list_folder_continue_cursor_url "https://api.dropboxapi.com/2/files/list_folder/continue"
  @longpoll_url "https://notify.dropboxapi.com/2/files/list_folder/longpoll"

  use GenServer
  def start_link (access_token) do
    GenServer.start_link(__MODULE__, access_token)
  end

  def init(access_token) do
    {:ok, %{access_token: access_token}}
  end

  def get_shared_link_file(client, share_url, filename) do
    GenServer.call(client, {:get_shared_link_file, share_url, filename})
  end

  def poll(client, cursor) do
    GenServer.call(client, {:poll, cursor}, :infinity)
  end

  def get_changes(client, cursor) do
    GenServer.call(client, {:get_changes, cursor})
  end

  def get_latest_cursor(client, share_url) do
    GenServer.call(client, {:get_latest_cursor, share_url})
  end

  #genserver callbacks
  def handle_call({:get_shared_link_file, share_url, filename}, _sender, state = %{access_token: access_token}) do
    {:ok, api_args} = Poison.encode(%{
      url: share_url,
      path: "/" <> filename
    })

    headers = [
      {"Authorization", "Bearer " <> access_token},
      {"Dropbox-API-Arg", api_args}
    ]

    respond_from_409 = fn response ->
      data = Poison.decode!(response.body)
      if(Map.get(data, "error") && Map.get(data["error"], ".tag")
        && data["error"][".tag"] == "shared_link_not_found") do
        {:not_found, response}
      else
        {:failed, nil}
      end
    end

    case HTTPoison.post(@content_url, "", headers) do
      {:ok, response = %HTTPoison.Response{status_code: 200}}
        ->  {:reply, {:ok, response}, state}
      {:ok, response = %HTTPoison.Response{status_code: 409}}
        -> {:reply, respond_from_409.(response), state}
      _ -> {:reply, {:failed, nil}, state}
    end
  end

  def handle_call({:get_latest_cursor, share_url}, _sender, state = %{access_token: access_token}) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> access_token}
    ]

    payload = %{
      shared_link: %{url: share_url},
      path: ""
    }

    response = api_post(
      @get_latest_cursor_url,
      headers,
      payload)["cursor"]
    {:reply, response, state}
  end

  def handle_call({:get_changes, cursor}, _sender, state = %{access_token: access_token}) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> access_token}
    ]

    payload = %{
      cursor: cursor
    }

    %{"cursor" => cursor, "entries" => entries} = api_post(
      @list_folder_continue_cursor_url,
      headers,
      payload)
    result = {cursor, Enum.map(entries, &(String.downcase(&1["name"])))}
    {:reply, result, state}
  end

  def handle_call({:poll, cursor}, _sender, state) do
    headers = [
      {"Content-Type", "application/json"},
    ]

    payload = %{
      cursor: cursor,
      timeout: 30
    }

    response = api_post(
      @longpoll_url,
      headers,
      payload,
      recv_timeout: 60 * 1000)
    {:reply, response, state}
  end

  defp api_post(url, headers, payload, options \\ []) do
    {:ok, body} = Poison.encode(payload)

    {:ok, %HTTPoison.Response{status_code: 200, body: response_body}}
      = HTTPoison.post(url, body, headers, options)

    Poison.decode!(response_body)
  end
end