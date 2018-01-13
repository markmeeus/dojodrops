defmodule DropRegistry do

  @initialization_delay 5000

  @behaviour ChangeDetectionClient
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: :drop_registry)
  end

  def refresh() do
    GenServer.cast(:drop_registry, :refresh)
  end

  def get_share_url_for_drop_id(drop_id) do
    GenServer.call(:drop_registry, {:get_share_url_for_drop_id, drop_id})
  end

  def init(nil) do
    token = Application.get_env(:dojo_drops, :dropbox)[:access_token]
    {:ok, dropbox_client} = DropBox.Client.start_link(token)
    share_url = System.get_env("DROPBOX_SHARE_URL")

    Process.send_after(self(), :init_dropbox, @initialization_delay)

    {:ok, %{token: token, share_url: share_url, dropbox_client: dropbox_client}}
  end

  # ChangeDetectionClient callbacks
  def global_change_detected pid do
    DropRegistry.refresh()
  end
  def resource_change_detected pid, resource_names do
    DropRegistry.refresh()
  end

  #genserver callbacks
  def handle_cast(:refresh, state) do
    {:ok, response} = state.dropbox_client
    |> DropBox.Client.get_shared_link_file(state.share_url, "registry.json")

    data = response
    |> Map.get(:body)
    |> Poison.decode!()

    newState = Map.put(state, :data, data)
    {:noreply, newState}
  end

  def handle_call({:get_share_url_for_drop_id, drop_id}, _from, state) do
    {:reply, Map.get(state.data, drop_id), state}
  end

  def handle_info(:init_dropbox, state) do
    ChangeDetection.start_link(__MODULE__, self(), state.token, state.share_url)
    DropRegistry.refresh()
    {:noreply, state}
  end
end