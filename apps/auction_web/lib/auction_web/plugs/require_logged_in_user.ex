defmodule AuctionWeb.Plugs.RequireLoggedInUser do
  import Plug.Conn
  import Phoenix.Controller
  alias AuctionWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(%{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> put_flash(:error, "You must be logged in.")
    |> redirect(to: Routes.item_path(conn, :index))
    |> halt()
  end

  def call(conn, _opts), do: conn
end
