defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking

  test "Creates the user account" do
    user = "Kotso"
    assert ExBanking.create_user(user) == :ok
  end

  test "Creates the user account and check if it's an existing user" do
    user = "Jose"
    ExBanking.create_user(user)
    assert ExBanking.create_user(user) == {:error, :user_already_exists}
  end

  test "Deposit amount into an existing user account" do
    user = "Valim"
    ExBanking.create_user(user)
    assert ExBanking.deposit(user, 25.25, "USD") == {:ok, 25.25}
  end

  test "Deposit amount into a non-existing user account" do
    user = "Kane"
    assert ExBanking.deposit(user, 25.25, "USD") == {:error, :user_does_not_exist}
  end

  test "Desposit invalid amount into an existing user account" do
    user = "Jose"
    ExBanking.create_user(user)
    assert ExBanking.deposit(user, "25.25", "Euro") == {:error, :wrong_arguments}
  end

  test "Withdraw amount by currency from an existing user acccount" do
    user = "Kayle"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25.25, "USD")
    assert ExBanking.withdraw(user, 15.25, "USD") == {:ok, 10.0}
  end

  test "Withdraw amount by currency from an existing user acccount before deposit" do
    user = "Kent"
    ExBanking.create_user(user)
    assert ExBanking.withdraw(user, 25.25, "USD") == {:error, :not_enough_money}
  end

  test "Withdraw amount from an existing user account with wrong arguments" do
    user = "Seren"
    ExBanking.create_user(user)
    assert ExBanking.withdraw(user, "Euro", 25.25) == {:error, :wrong_arguments}
  end

  test "Get balance of an existing user acccount" do
    user = "Abc"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25.25, "USD")
    assert ExBanking.get_balance(user, "USD") == {:ok, 25.25}
  end

  test "Get balance of an existing user account with not available currency" do
    user = "Ali"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25.25, "Euro")
    assert ExBanking.get_balance(user, "PKR") == {:ok, 0.00}
  end

  test "Send amount to an existing user account" do
    sender = "Keto"
    receiver = "Meno"
    ExBanking.create_user(sender)
    ExBanking.create_user(receiver)

    ExBanking.deposit(sender, 25.25, "Euro")
    ExBanking.deposit(sender, 30.00, "USD")

    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:ok, 15.25, 10.0}
    assert ExBanking.send(sender, receiver, 20.00, "USD") == {:ok, 10.0, 20.0}
  end

  test "Send amount to an existing user account when no money available in sender account" do
    sender = "Bob"
    receiver = "Martini"
    ExBanking.create_user(sender)
    ExBanking.create_user(receiver)
    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:error, :not_enough_money}
  end

  test "Send amount when sender does not exist" do
    sender = "Ben"
    receiver = "Max"
    ExBanking.create_user(receiver)
    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:error, :sender_does_not_exist}
  end

  test "Send amount when receiver does not exist" do
    sender = "Sula"
    receiver = "Keller"
    ExBanking.create_user(sender)
    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:error, :receiver_does_not_exist}
  end
end
