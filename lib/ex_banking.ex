defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.Accounts
  alias ExBanking.Accounts.User
  alias ExBanking.Utils

  @doc """
  Creates new user in the system

  ## Examples
  iex> ExBanking.create_user("Raymond")
  :ok
  iex> ExBanking.create_user("Raymond")
  {:error, :user_already_exists}
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    case Accounts.create_account(user) do
      {:ok, _user} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @doc """
  Increases user’s balance in given currency by amount value
  Returns new_balance of the user in given format

  ## Examples
  iex> ExBanking.deposit("Raymond", 25.25, "USD")
  {:ok, 25.25}
  iex> ExBanking.deposit("Kayne", 25.25, "USD")
  {:error, :user_does_not_exist}
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) and amount >= 0 do
    case Accounts.get_user_account(user) do
      {:ok, account} ->
        currencies = Map.get(account, :currencies)

        balance = Map.get(currencies, currency, 0.0)

        new_balance =
          (balance + Utils.format_amount(amount))
          |> Utils.format_amount()

        # Add or update existing currency amount
        currencies = Map.put(currencies, currency, new_balance)

        # Update user account
        account = %User{currencies: currencies}
        Accounts.update_account(user, account)

        {:ok, new_balance}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @doc """
  Decreases user’s balance in given currency by amount value
  Returns new_balance of the user in given format

  ## Examples
  iex> ExBanking.withdraw("Raymond", 25.425, "USD")
  {:error, :not_enough_money}
  iex> ExBanking.withdraw("Raymond", 25.05, "USD")
  {:ok, 0.19}
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount >= 0 and is_binary(currency) do
    case Accounts.get_user_account(user) do
      {:ok, account} ->
        currencies = Map.get(account, :currencies)

        blanace = Map.get(currencies, currency, 0.0)

        if(amount > blanace) do
          {:error, :not_enough_money}
        else
          new_balance =
            (blanace - Utils.format_amount(amount))
            |> Utils.format_amount()

          # Update existing currency amount
          currencies = Map.put(currencies, currency, new_balance)

          # Update user account
          account = %User{currencies: currencies}
          Accounts.update_account(user, account)

          {:ok, new_balance}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @doc """
  Returns balance of the user in given format

  ## Examples
  iex> ExBanking.get_balance("Raymond", "USD")
  {:ok, 0.19}
  iex> ExBanking.get_balance("Raymond", "Euro")
  {:ok, 0.00}
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    case Accounts.get_user_account(user) do
      {:ok, account} ->
        balance =
          Map.get(account, :currencies)
          |> Map.get(currency, 0.00)

        {:ok, balance}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @doc """
  Decreases from_user’s balance in given currency by amount value
  Increases to_user’s balance in given currency by amount value
  Returns balance of from_user and to_user in given format

  ## Examples
  iex> ExBanking.send("Raymond", "Kayne", 250, "USD")
  {:ok, 2050.45, 500.0}
  iex> ExBanking.send("Raymond", "Kayne", 2500, "USD")
  {:error, :not_enough_money}
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and amount >= 0 and
             is_binary(currency) do
    with(
      {:ok, _from_user_account} <- validate_from_user(from_user),
      {:ok, _to_user_account} <- vallidate_to_user(to_user),
      {:ok, from_user_balance} <- from_user_withdraw(from_user, amount, currency),
      {:ok, to_user_balance} <- to_user_deposit(to_user, amount, currency)
    ) do
      {:ok, from_user_balance, to_user_balance}
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  defp validate_from_user(user) do
    case Accounts.get_user_account(user) do
      {:ok, user} ->
        {:ok, user}

      {:error, _reason} ->
        {:error, :sender_does_not_exist}
    end
  end

  defp vallidate_to_user(user) do
    case Accounts.get_user_account(user) do
      {:ok, user} ->
        {:ok, user}

      {:error, _reason} ->
        {:error, :receiver_does_not_exist}
    end
  end

  defp from_user_withdraw(user, amount, currency) do
    case withdraw(user, amount, currency) do
      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_sender}

      other ->
        other
    end
  end

  defp to_user_deposit(user, amount, currency) do
    case deposit(user, amount, currency) do
      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_receiver}

      other ->
        other
    end
  end
end
