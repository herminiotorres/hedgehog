defmodule Streamer.Binance.TradeEvent do
  defstruct ~w(
    event_type
    event_time
    symbol
    trade_id
    price
    quantity
    buyer_order_id
    seller_order_id
    buyer_market_maker
  )a
end
