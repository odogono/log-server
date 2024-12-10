# lib/your_app_web/channels/user_socket.ex
defmodule LogserverWeb.UserSocket do
  use Phoenix.Socket

  # Channels
  channel "room:*", LogserverWeb.RoomChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
