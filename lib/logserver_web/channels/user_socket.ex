# lib/your_app_web/channels/user_socket.ex
defmodule LogserverWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  # Channels
  channel "room:*", LogserverWeb.RoomChannel

  # Socket params are passed from the client
  def connect(%{"token" => token}, socket, _connect_info) do
    # Add your auth logic here
    Logger.info("User connected with token: #{token}")
    {:ok, socket}
  end

  def connect(_params, socket, _connect_info) do
    Logger.info("User connected without token")
    {:ok, socket}
  end

  def id(_socket), do: nil
end
