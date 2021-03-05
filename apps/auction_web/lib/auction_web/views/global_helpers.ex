defmodule AuctionWeb.GlobalHelpers do
  def integer_to_currency(cents) do
    dollars_and_cents =
      cents
      |> Decimal.div(100)
      |> Decimal.round(2)

    "$#{dollars_and_cents}"
  end

  def format_timestamp(timestamp, timezone) do
    timestamp
    |> DateTime.shift_zone!(timezone)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end
end
