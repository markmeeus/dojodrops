defmodule DojoDropsWeb.LiveReloader.Channel do
  @behaviour DropServer.ChangeListener
  @moduledoc """
  Phoenix's live-reload channel.
  """
  use Phoenix.Channel
  require Logger

  def join("live_reload:" <> drop_id, _msg, socket) do
    #subscribe for changes via drop_server
    DropServer.register_for_change(__MODULE__, self(), drop_id)
    {:ok, socket}
  end

  # ChangeListener callbacks
  def global_change pid, drop_id do
    send(pid, {:global_change, drop_id})
  end

  def resource_change pid, drop_id, resource_name do
    send(pid, {:resource_change, drop_id, resource_name})
  end

  def handle_info({:global_change, _drop_id}, socket) do
    push socket, "assets_change", %{asset_type: "html"}
    {:noreply, socket}
  end

  def handle_info({:resource_change, _drop_id, resource_name}, socket) do
    asset_type = remove_leading_dot(Path.extname(resource_name))
    push socket, "assets_change", %{asset_type: asset_type}
    {:noreply, socket}
  end

  defp remove_leading_dot("." <> rest), do: rest
  defp remove_leading_dot(rest), do: rest

end
