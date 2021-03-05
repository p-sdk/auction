defmodule AuctionWeb.Plugs.Timezone do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    timezone = get_session(conn, :timezone) || "Etc/UTC"
    assign(conn, :timezone, timezone)
  end
end
