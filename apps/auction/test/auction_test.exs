defmodule AuctionTest do
  use ExUnit.Case
  import Ecto.Query
  alias Auction.{Bid, Item, Repo, User}
  doctest Auction, import: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "list_items/0" do
    setup do
      {:ok, item1} = Repo.insert(%Item{title: "Item 1"})
      {:ok, item2} = Repo.insert(%Item{title: "Item 2"})
      {:ok, item3} = Repo.insert(%Item{title: "Item 3"})
      %{items: [item1, item2, item3]}
    end

    test "returns all Items in the database", %{items: items} do
      assert items == Auction.list_items()
    end
  end

  describe "get_item/1" do
    setup do
      {:ok, item1} = Repo.insert(%Item{title: "Item 1"})
      {:ok, item2} = Repo.insert(%Item{title: "Item 2"})
      %{items: [item1, item2]}
    end

    test "returns a single Item based on id", %{items: items} do
      item = Enum.at(items, 1)
      assert item == Auction.get_item(item.id)
    end
  end

  describe "insert_item/1" do
    test "adds an Item to the database" do
      count_query = from(i in Item, select: count(i.id))
      before_count = Repo.one(count_query)
      {:ok, _item} = Auction.insert_item(%{title: "test item"})
      assert Repo.one(count_query) == before_count + 1
    end

    test "the Item in the database has the attributes provided" do
      attrs = %{title: "test item", description: "test description"}
      {:ok, item} = Auction.insert_item(attrs)
      assert item.title == attrs.title
      assert item.description == attrs.description
    end

    test "it returns an error on error" do
      assert {:error, _changeset} = Auction.insert_item(%{foo: :bar})
    end

    test "an Item's ends_at date can't be in the past" do
      title = "test item"
      past_date = DateTime.add(DateTime.utc_now(), -5)
      future_date = DateTime.add(DateTime.utc_now(), 5)
      assert {:error, _item} = Auction.insert_item(%{title: title, ends_at: past_date})
      assert {:ok, _item} = Auction.insert_item(%{title: title, ends_at: future_date})
    end
  end

  describe "insert_bid/1" do
    setup do
      {:ok, item} = Repo.insert(%Item{title: "test item"})
      {:ok, bidder} = Repo.insert(%User{username: "test bidder"})
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
      {:ok, other_bidder} = Repo.insert(%User{username: "other bidder"})
      {:ok, _bid} = Auction.insert_bid(%{amount: 123, item_id: item.id, user_id: other_bidder.id})

      assert {:error, _bid} = Auction.insert_bid(%{amount: 122, item_id: item.id, user_id: bidder.id})
      assert {:ok, _bid} = Auction.insert_bid(%{amount: 124, item_id: item.id, user_id: bidder.id})
    end
  end
end
