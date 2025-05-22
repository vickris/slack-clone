# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SlackClone.Repo.insert!(%SlackClone.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SlackClone.{Repo, Accounts.User, Chat.Channel, Chat.ChannelMembership}

user =
  Repo.insert!(%User{
    email: "test@example.com",
    username: "test",
    hashed_password: Bcrypt.hash_pwd_salt("password")
  })

channel = Repo.insert!(%Channel{name: "other", creator_id: user.id})
Repo.insert!(%ChannelMembership{user_id: user.id, channel_id: channel.id})
