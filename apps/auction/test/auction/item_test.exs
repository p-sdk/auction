defmodule Auction.ItemTest do
  use ExUnit.Case
  import Auction.{Factory, Item}

  @past_datetime DateTime.add(DateTime.utc_now(), -1000)
  @future_datetime DateTime.add(DateTime.utc_now(), 1000)

  test "expired?/1" do
    expired_item = build(:item, ends_at: @past_datetime)
    active_item = build(:item, ends_at: @future_datetime)

    assert expired?(expired_item)
    refute expired?(active_item)
  end
end
