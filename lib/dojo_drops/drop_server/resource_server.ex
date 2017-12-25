defmodule ResourceServer do

  @dropbox_content_url "https://content.dropboxapi.com/2/sharing/get_shared_link_file"

  use GenServer

  def start_link(dropbox_access_token, dropbox_share_url, resource_name) do
    GenServer.start_link(__MODULE__,
      {dropbox_access_token, dropbox_share_url, resource_name})
  end
  def init({dropbox_access_token, dropbox_share_url, resource_name}) do
    {:ok, %{
      dropbox_access_token: dropbox_access_token,
      dropbox_share_url: dropbox_share_url,
      resource_name: resource_name
    }}
  end

  def reset(pid) do
    GenServer.cast(pid, :reset)
    #cast fetch, so caller can continue
    GenServer.cast(pid, :fetch)
  end
  def fetch(pid) do
    GenServer.call(pid, :fetch)
  end

  # Genserver callbacks
  def handle_cast(:reset, state) do
    {:noreply, Map.delete(state, :response)}
  end
  def handle_cast(:fetch, state) do
    new_state = fetch_response(state)
    {:noreply, new_state}
  end

  def handle_call(:fetch, _from, state) do
    new_state = fetch_response(state)
    {:reply, new_state.response, new_state}
  end

  defp fetch_response(state = %{response: %HTTPoison.Response{}}), do: state
  defp fetch_response(state) do
    new_state = Map.put(state, :response,
      fetch_content(state.dropbox_access_token, state.resource_name, state.dropbox_share_url))
    new_state
  end

  # Private functions
  defp fetch_content(dropbox_access_token, resource_name, dropbox_share_url) do
    {:ok, dropbox_api_args} = Poison.encode(%{
      url: dropbox_share_url,
      path: "/" <> resource_name
    })

    headers = [
      {"Authorization", "Bearer " <> dropbox_access_token},
      {"Dropbox-API-Arg", dropbox_api_args}
    ]

    {:ok, response = %HTTPoison.Response{status_code: 200}}
      = HTTPoison.post @dropbox_content_url, "", headers

    response
  end
end