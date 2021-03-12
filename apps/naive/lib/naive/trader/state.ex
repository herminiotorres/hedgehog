defmodule Naive.Trader.State do
  @enforce_keys ~w(symbol profit_interval tick_size)a

  defstruct ~w(
    symbol
    buy_order
    sell_order
    profit_interval
    tick_size
  )a
end
