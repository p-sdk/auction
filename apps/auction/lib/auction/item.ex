defmodule Auction.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field(:title, :string)
    field(:description, :string)
    field(:ends_at, :utc_datetime)
    has_many(:bids, Auction.Bid)
    belongs_to(:user, Auction.User)
    timestamps()
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:title, :description, :ends_at, :user_id])
    |> validate_required([:title, :ends_at])
    |> assoc_constraint(:user)
    |> validate_length(:title, min: 3)
    |> validate_length(:description, max: 200)
    |> validate_change(:ends_at, &validate/2)
  end

  defp validate(:ends_at, ends_at_date) do
    case DateTime.compare(ends_at_date, DateTime.utc_now()) do
      :lt -> [ends_at: "can't be in the past"]
      _ -> []
    end
  end

  def expired?(item) do
    validate(:ends_at, item.ends_at)
    |> Enum.any?()
  end
end
