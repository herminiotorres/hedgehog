defmodule Streamer.Binance do
  use WebSockex

  alias Streamer.Binance.TradeEvent

  require Logger

  @stream_endpoint "wss://stream.binance.com:9443/ws/"

  def start_link(symbol) do
    WebSockex.start_link(
      "#{@stream_endpoint}#{symbol}@trade",
      __MODULE__,
      nil
    )
  end

  def handle_frame({_type, msg}, state) do
    case Jason.decode(msg) do
      {:ok, event} -> process_event(event)
      {:error, _} -> Logger.error("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  defp process_event(%{"e" => "trade"} = event) do
    trade_event = %TradeEvent{
      event_type: event["e"],
      event_time: event["E"],
      symbol: event["s"],
      trade_id: event["T"],
      price: event["p"],
      quantity: event["q"],
      buyer_order_id: event["b"],
      seller_order_id: event["a"],
      buyer_market_maker: event["m"]
    }

    Logger.debug("Trade event received #{trade_event.symbol}@#{trade_event.price}")
  end
end
