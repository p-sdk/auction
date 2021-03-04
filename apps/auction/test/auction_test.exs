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

      assert Enum.map(items, &{&1.id, &1.title}) == Enum.map(Auction.list_items(), &{&1.id, &1.title})
    end
  end

  describe "get_item/1" do
    test "returns a single Item based on id" do
      items = insert_pair(:item)
      item = Enum.at(items, 1)

      assert item.title == Auction.get_item(item.id).title
    end
  end

  describe "insert_item/1" do
    setup do
      owner = insert(:user)

      valid_params = %{
        title: "test item",
        description: "test description",
        ends_at: @future_datetime,
        user_id: owner.id
      }

      [valid_params: valid_params]
    end

    test "adds an Item to the database", %{valid_params: valid_params} do
      count_query = from(i in Item, select: count(i.id))
      before_count = Repo.one(count_query)
      {:ok, _item} = Auction.insert_item(valid_params)
      assert Repo.one(count_query) == before_count + 1
    end

    test "the Item in the database has the attributes provided", %{valid_params: valid_params} do
      attrs = valid_params
      {:ok, item} = Auction.insert_item(attrs)
      assert item.title == attrs.title
      assert item.description == attrs.description
    end

    test "it returns an error on error" do
      assert {:error, _changeset} = Auction.insert_item(%{foo: :bar})
    end

    test "an Item's ends_at date can't be in the past", %{valid_params: valid_params} do
      attrs = valid_params
      assert {:error, _item} = Auction.insert_item(%{attrs | ends_at: @past_datetime})
      assert {:ok, _item} = Auction.insert_item(%{attrs | ends_at: @future_datetime})
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

  test "get_bids_for_user/1" do
    [item1, item2] = insert_pair(:item)
    [user1, user2] = insert_pair(:user)
    b1 = insert(:bid, item: item1, user: user1)
    b2 = insert(:bid, item: item1, user: user2)
    b3 = insert(:bid, item: item2, user: user1)
    b4 = insert(:bid, item: item2, user: user2)
    b5 = insert(:bid, item: item1, user: user1)
    b6 = insert(:bid, item: item1, user: user2)

    user1_bids = Auction.get_bids_for_user(user1)
    user2_bids = Auction.get_bids_for_user(user2)

    assert bid_tuples(user1_bids) == bid_tuples([b5, b3, b1])
    assert bid_tuples(user2_bids) == bid_tuples([b6, b4, b2])
  end

  defp bid_tuple(bid), do: {bid.id, bid.amount}
  defp bid_tuples(bids), do: Enum.map(bids, &bid_tuple/1)
end
