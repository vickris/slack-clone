defmodule SlackCloneWeb.ChannelLiveTest do
  use SlackCloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import SlackClone.ChatFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_channel(_) do
    channel = channel_fixture()
    %{channel: channel}
  end

  describe "Index" do
    setup [:create_channel]

    test "lists all channels", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/channels")

      assert html =~ "Listing Channels"
    end

    test "saves new channel", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/channels")

      assert index_live |> element("a", "New Channel") |> render_click() =~
               "New Channel"

      assert_patch(index_live, ~p"/channels/new")

      assert index_live
             |> form("#channel-form", channel: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#channel-form", channel: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/channels")

      html = render(index_live)
      assert html =~ "Channel created successfully"
    end

    test "updates channel in listing", %{conn: conn, channel: channel} do
      {:ok, index_live, _html} = live(conn, ~p"/channels")

      assert index_live |> element("#channels-#{channel.id} a", "Edit") |> render_click() =~
               "Edit Channel"

      assert_patch(index_live, ~p"/channels/#{channel}/edit")

      assert index_live
             |> form("#channel-form", channel: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#channel-form", channel: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/channels")

      html = render(index_live)
      assert html =~ "Channel updated successfully"
    end

    test "deletes channel in listing", %{conn: conn, channel: channel} do
      {:ok, index_live, _html} = live(conn, ~p"/channels")

      assert index_live |> element("#channels-#{channel.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#channels-#{channel.id}")
    end
  end

  describe "Show" do
    setup [:create_channel]

    test "displays channel", %{conn: conn, channel: channel} do
      {:ok, _show_live, html} = live(conn, ~p"/channels/#{channel}")

      assert html =~ "Show Channel"
    end

    test "updates channel within modal", %{conn: conn, channel: channel} do
      {:ok, show_live, _html} = live(conn, ~p"/channels/#{channel}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Channel"

      assert_patch(show_live, ~p"/channels/#{channel}/show/edit")

      assert show_live
             |> form("#channel-form", channel: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#channel-form", channel: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/channels/#{channel}")

      html = render(show_live)
      assert html =~ "Channel updated successfully"
    end
  end
end
