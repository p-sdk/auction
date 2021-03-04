defmodule Auction.Bid do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @timestamps_opts [type: :utc_datetime_usec]

  schema "bids" do
    field(:amount, :integer)
    belongs_to(:item, Auction.Item)
    belongs_to(:user, Auction.User)
    timestamps()
  end

  def changeset(bid, params \\ %{}) do
    bid
    |> cast(params, [:amount, :user_id, :item_id])
    |> validate_required([:amount, :user_id, :item_id])
    |> assoc_constraint(:item)
    |> assoc_constraint(:user)
    |> validate_item_is_active()
    |> validate_amount_higher_than_current_high_bid()
  end

  defp validate_item_is_active(changeset) do
    item_id = get_field(changeset, :item_id)

    with {:is_valid, true} <- {:is_valid, changeset.valid?},
         %Auction.Item{} = item <- Auction.Repo.get(Auction.Item, item_id),
         false <- Auction.Item.expired?(item) do
      changeset
    else
      {:is_valid, false} ->
        changeset

      _ ->
        add_error(changeset, :item_id, "must be active")
    end
  end

  defp validate_amount_higher_than_current_high_bid(changeset) do
    amount = get_field(changeset, :amount)
    item_id = get_field(changeset, :item_id)

    with {:is_valid, true} <- {:is_valid, changeset.valid?},
         highest_bid <- highest_bid_for_item(item_id),
         true <- amount > (highest_bid || 0) do
      changeset
    else
      {:is_valid, false} ->
        changeset

      _ ->
        add_error(changeset, :amount, "must be higher than the current high bid")
    end
  end

  defp highest_bid_for_item(item_id) do
    from(b in __MODULE__,
      select: b.amount,
      where: b.item_id == ^item_id,
      order_by: [desc: :amount],
      limit: 1
    )
    |> Auction.Repo.one()
  end
end
