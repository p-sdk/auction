defmodule Auction.Factory do
  use ExMachina.Ecto, repo: Auction.Repo

  def item_factory do
    %Auction.Item{
      title: sequence(:title, &"Item #{&1}"),
      ends_at: DateTime.add(DateTime.utc_now(), 1000)
    }
  end

  def user_factory do
    %Auction.User{
      username: sequence(:username, &"User #{&1}")
    }
  end
end
