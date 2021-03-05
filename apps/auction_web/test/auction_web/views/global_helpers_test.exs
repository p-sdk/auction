defmodule AuctionWeb.GlobalHelpersTest do
  use ExUnit.Case
  import AuctionWeb.GlobalHelpers

  test "integer_to_currency/1" do
    cents = 123
    assert integer_to_currency(cents) == "$1.23"
  end

  test "format_timestamp/2" do
    {:ok, datetime, 0} = DateTime.from_iso8601("2021-03-04T20:28:07.686813Z")
    timezone = "Europe/Warsaw"

    assert format_timestamp(datetime, timezone) == "2021-03-04 21:28:07"
  end
end
