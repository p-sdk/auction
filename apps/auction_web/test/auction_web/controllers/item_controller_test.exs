defmodule AuctionWeb.ItemControllerTest do
  use AuctionWeb.ConnCase
  import Auction.Factory

  test "GET /", %{conn: conn} do
    insert(:item, title: "test item")
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "test item"
  end

  describe "POST /items" do
    @valid_params %{
      "item" => %{
        "title" => "Item 1",
        "ends_at" => %{
          "year" => "2030",
          "month" => "5",
          "day" => "16",
          "hour" => "11",
          "minute" => "15"
        }
      }
    }

    setup %{conn: conn} do
      [conn: sign_in(conn)]
    end

    test "with valid params, creates a new Item", %{conn: conn} do
      before_count = Enum.count(Auction.list_items())
      post conn, "/items", @valid_params
      assert Enum.count(Auction.list_items()) == before_count + 1
    end

    test "with valid params, redirects to the new Item", %{conn: conn} do
      conn = post conn, "/items", @valid_params
      assert redirected_to(conn) =~ ~r|/items/\d+|
    end

    test "with invalid params, does not create a new Item", %{conn: conn} do
      before_count = Enum.count(Auction.list_items())
      post conn, "/items", %{"item" => %{"bad_param" => "Item 1"}}
      assert Enum.count(Auction.list_items()) == before_count
    end

    test "with invalid params, shows the new Item form", %{conn: conn} do
      conn = post conn, "/items", %{"item" => %{"bad_param" => "Item 1"}}
      assert html_response(conn, 200) =~ "<h1>New Item</h1>"
    end

    test "don't allow the creation of an item if a user is not logged in", %{conn: conn} do
      before_count = Enum.count(Auction.list_items())

      conn
      |> delete("/logout")
      |> post("/items", @valid_params)

      assert Enum.count(Auction.list_items()) == before_count
    end

    def sign_in(conn) do
      user = insert(:user)

      post conn, "/login", %{
        "user" => %{
          "username" => user.username,
          "password" => user.password,
          "timezone" => "Europe/Warsaw"
        }
      }
    end
  end
end
