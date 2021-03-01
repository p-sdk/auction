defmodule AuctionTest do
  use ExUnit.Case
  import Ecto.Query
  import Auction.Factory
  alias Auction.{Bid, Item, Repo}
  doctest Auction, import: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  @past_datetime DateTime.add(DateTime.utc_now(), -1000)
  @future_datetime DateTime.add(DateTime.utc_now(), 1000)

  describe "list_items/0" do
    test "returns all Items in the database" do
      items = insert_list(3, :item)

      assert items == Auction.list_items()
    end
  end

  describe "get_item/1" do
    test "returns a single Item based on id" do
      items = insert_pair(:item)
      item = Enum.at(items, 1)

      assert item == Auction.get_item(item.id)
    end
  end

  describe "insert_item/1" do
    test "adds an Item to the database" do
      count_query = from(i in Item, select: count(i.id))
      before_count = Repo.one(count_query)
      {:ok, _item} = Auction.insert_item(%{title: "test item", ends_at: @future_datetime})
      assert Repo.one(count_query) == before_count + 1
    end

    test "the Item in the database has the attributes provided" do
      attrs = %{
        title: "test item",
        description: "test description",
        ends_at: @future_datetime
      }
      {:ok, item} = Auction.insert_item(attrs)
      assert item.title == attrs.title
      assert item.description == attrs.description
    end

    test "it returns an error on error" do
      assert {:error, _changeset} = Auction.insert_item(%{foo: :bar})
    end

    test "an Item's ends_at date can't be in the past" do
      title = "test item"
      assert {:error, _item} = Auction.insert_item(%{title: title, ends_at: @past_datetime})
      assert {:ok, _item} = Auction.insert_item(%{title: title, ends_at: @future_datetime})
    end
  end

  describe "insert_bid/1" do
    setup do
      item = insert(:item)
      bidder = insert(:user)
      %{item: item, bidder: bidder}
    end

    test "adds a Bid to the database", %{item: item, bidder: bidder} do
      before_count = Repo.aggregate(Bid, :count)
      {:ok, _bid} = Auction.insert_bid(%{amount: 123, item_id: item.id, user_id: bidder.id})
      assert Repo.aggregate(Bid, :count) == before_count + 1
    end

    test "the Bid in the database has the attributes provided", %{item: item, bidder: bidder} do
      attrs = %{amount: 123, item_id: item.id, user_id: bidder.id}
      {:ok, bid} = Auction.insert_bid(attrs)
      assert bid.amount == attrs.amount
      assert bid.item_id == attrs.item_id
      assert bid.user_id == attrs.user_id
    end

    test "it returns an error on error" do
      assert {:error, _changeset} = Auction.insert_bid(%{foo: :bar})
    end

    test "only allow bids that have a higher amount than the current high bid", %{item: item, bidder: bidder} do
      other_bidder = insert(:user)
      {:ok, _bid} = Auction.insert_bid(%{amount: 123, item_id: item.id, user_id: other_bidder.id})

      assert {:error, _bid} = Auction.insert_bid(%{amount: 122, item_id: item.id, user_id: bidder.id})
      assert {:ok, _bid} = Auction.insert_bid(%{amount: 124, item_id: item.id, user_id: bidder.id})
    end

    test "don't allow bids on items after the item's ends_at datetime have passed", %{item: active_item, bidder: bidder} do
      expired_item = insert(:item, ends_at: @past_datetime)

      assert {:error, _bid} = Auction.insert_bid(%{amount: 123, item_id: expired_item.id, user_id: bidder.id})
      assert {:ok, _bid} = Auction.insert_bid(%{amount: 123, item_id: active_item.id, user_id: bidder.id})
    end
  end
end
