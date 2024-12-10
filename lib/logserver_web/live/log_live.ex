defmodule LogserverWeb.LogLive do
  use LogserverWeb, :live_view
  require Logger
  alias Logserver.Repo
  alias Logserver.Logging.Message

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Logserver.PubSub, "log:messages")
    end

    messages =
      Message.ordered_messages()
      |> Repo.all()
      |> Enum.map(fn msg ->
        {msg.timestamp, message_tuple(msg.type, msg.content)}
      end)

    {:ok, assign(socket, messages: messages)}
  end

  @impl true
  def handle_info({:new_message, {timestamp, message}}, socket) do
    messages = [{timestamp, message} | socket.assigns.messages]
    {:noreply, assign(socket, messages: messages)}
  end

  @impl true
  def handle_event("delete_message", %{"timestamp" => timestamp}, socket) do
    timestamp = NaiveDateTime.from_iso8601!(timestamp)

    Message.delete_message(timestamp)
    |> Repo.delete_all()

    messages =
      Enum.reject(socket.assigns.messages, fn {msg_timestamp, _} ->
        NaiveDateTime.compare(msg_timestamp, timestamp) == :eq
      end)

    {:noreply, assign(socket, messages: messages)}
  end

  defp message_tuple("json", content), do: {:json, content}
  defp message_tuple("text", content), do: {:text, content}
  defp message_tuple("status", content), do: {:status, content}

  defp message_tuple("image", content) do
    parsed = Jason.decode!(content)
    {:image, parsed["data"], parsed["metadata"]}
  end

  defp message_tuple("svg_path", content) do
    parsed = Jason.decode!(content)
    {:svg_path, parsed["path"], parsed["metadata"]}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Message Log</h1>
      <div class="bg-gray-100 p-4 rounded-lg">
        <%= for {timestamp, message} <- @messages do %>
          <div class="mb-2 p-2 bg-white rounded shadow group relative">
            <div class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                phx-click="delete_message"
                phx-value-timestamp={NaiveDateTime.to_iso8601(timestamp)}
                class="text-gray-400 hover:text-red-500 focus:outline-none"
                title="Delete message"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>
            <div class="text-xs text-gray-500 mb-1">
              <%= Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%SS.%f") |> String.slice(0..-4//1) %>
            </div>
            <%= case message do %>
              <% {:json, json_string} -> %>
                <pre class="whitespace-pre overflow-x-auto bg-gray-50 p-2 rounded"><code class="text-sm"><%= json_string %></code></pre>
              <% {:text, text} -> %>
                <div class="text-gray-700"><%= text %></div>
              <% {:status, status} -> %>
                <div class="text-orange-700"><%= status %></div>
              <% {:image, data, metadata} -> %>
                <div class="space-y-2">
                  <img
                    src={data}
                    class="max-w-full h-auto rounded-lg shadow-sm"
                    style="max-height: 400px;"
                  />
                  <div class="text-sm text-gray-600 bg-gray-50 p-2 rounded">
                    <div class="grid grid-cols-2 gap-2">
                      <div>Dimensions: <%= metadata["width"] %>x<%= metadata["height"] %>px</div>
                      <div>Type: <%= metadata["type"] %></div>
                      <%= if metadata["filename"] do %>
                        <div>Filename: <%= metadata["filename"] %></div>
                      <% end %>
                      <%= if metadata["size"] do %>
                        <div>Size: <%= format_size(metadata["size"]) %></div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% {:svg_path, path, metadata} -> %>
                <div class="space-y-2">
                  <svg
                    class="w-full h-auto bg-white rounded-lg shadow-sm"
                    viewBox={metadata["viewBox"] || "0 0 100 100"}
                    width={metadata["width"] || "300"}
                    height={metadata["height"] || "300"}
                    style="max-height: 400px;"
                  >
                    <path
                      d={path}
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    />
                  </svg>
                  <div class="text-sm text-gray-600 bg-gray-50 p-2 rounded">
                    <div class="grid grid-cols-2 gap-2">
                      <%= if metadata["width"] && metadata["height"] do %>
                        <div>Size: <%= metadata["width"] %> x <%= metadata["height"] %></div>
                      <% end %>
                      <%= if metadata["viewBox"] do %>
                        <div>ViewBox: <%= metadata["viewBox"] %></div>
                      <% end %>
                    </div>
                  </div>
                </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_size(size) when is_integer(size) do
    cond do
      size > 1_000_000 -> "#{Float.round(size / 1_000_000, 2)} MB"
      size > 1_000 -> "#{Float.round(size / 1_000, 2)} KB"
      true -> "#{size} bytes"
    end
  end

  defp format_size(_), do: "Unknown size"
end
