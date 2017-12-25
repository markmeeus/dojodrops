defmodule DojoDropsWeb.LiveReloader.Socket do
  @moduledoc """
  The Socket handler for live reload channels.
  """

  use Phoenix.Socket
  channel "live_reload:*", DojoDropsWeb.LiveReloader.Channel

  transport :websocket, Phoenix.Transports.WebSocket
  transport :longpoll, Phoenix.Transports.LongPoll

  def connect(_params, socket), do: {:ok, socket}

  def id(_socket), do: nil
end
