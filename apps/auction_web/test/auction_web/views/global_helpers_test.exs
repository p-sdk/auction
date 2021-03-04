defmodule AuctionWeb.GlobalHelpersTest do
  use ExUnit.Case
  import AuctionWeb.GlobalHelpers

  test "integer_to_currency/1" do
    cents = 123
    assert integer_to_currency(cents) == "$1.23"
  end
end
