defmodule Auction.Bid do
  use Ecto.Schema

  schema "bids" do
    field :amount, :integer
    belongs_to :item, Auction.Item
    belongs_to :user, Auction.User
    timestamps()
  end
end
