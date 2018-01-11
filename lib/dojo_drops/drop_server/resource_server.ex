defmodule ResourceServer do

  @dropbox_content_url "https://content.dropboxapi.com/2/sharing/get_shared_link_file"
  @max_content_length 256 * 1024 #256KB max content size

  use GenServer

  def start_link(dropbox_access_token, dropbox_share_url, resource_name) do
    GenServer.start_link(__MODULE__,
      {dropbox_access_token, dropbox_share_url, resource_name})
  end
  def init({dropbox_access_token, dropbox_share_url, resource_name}) do
    {:ok, dropbox_client} = DropBox.Client.start_link(dropbox_access_token)
    {:ok, %{
      dropbox_client: dropbox_client,
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
    {:noreply, Map.delete(state, :resource)}
  end
  def handle_cast(:fetch, state) do
    new_state = fetch_resource(state)
    {:noreply, new_state}
  end

  def handle_call(:fetch, _from, state) do
    new_state = fetch_resource(state)
    {:reply, new_state.resource, new_state}
  end

  defp fetch_resource(state = %{resource: resource}), do: state
  defp fetch_resource(state) do
    resource = {status, request} = DropBox.Client.get_shared_link_file(
      state.dropbox_client, state.dropbox_share_url, state.resource_name)
    resource_to_keep = if (status == :ok) do
      if content_length(request) > @max_content_length,
        do: {:too_large, nil},
        else: resource
    else
      resource
    end

    new_state = Map.put(state, :resource, resource_to_keep)
    new_state
  end

  def content_length(request) do
    {_, header_val} = Enum.find(request.headers, fn
        {"Content-Length", _} -> true
        _ -> false
      end)
    String.to_integer(header_val)
  end

  defp is_content_length_header({"Content-Length", _}), do: true
  defp is_content_length_header(_), do: false

end