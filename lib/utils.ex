defmodule ExBanking.Utils do
  @moduledoc """
  Provides helper functions
  """
  @spec format_amount(amount :: number()) :: number()
  def format_amount(amount) when is_float(amount) do
    Float.round(amount, 2)
  end

  def format_amount(amount) when is_integer(amount) do
    amount + 0.0
  end
end
