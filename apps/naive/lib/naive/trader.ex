defmodule Naive.Trader do
  use GenServer

  alias Naive.Trader.State
  alias Streamer.Binance.TradeEvent

  require Logger

  def start_link(%{} = args) do
    GenServer.start_link(__MODULE__, args, name: :trader)
  end

  def init(args) do
    with %{symbol: symbol, profit_interval: profit_interval} <- args do
      symbol = String.upcase(symbol)

      Logger.info("Initializing new trader for #{symbol}")

      tick_size = fetch_tick_size(symbol)

      state = %State{symbol: symbol, profit_interval: profit_interval, tick_size: tick_size}

      {:ok, state}
    else
      error ->
        Logger.info("Error: #{error}")
        :error
    end
  end

  def handle_cast(
        %TradeEvent{price: price},
        %State{symbol: symbol, buy_order: nil} = state
      ) do
    # hardcoded until chapter 7
    quantity = 100

    Logger.info("Placing BUY order for #{symbol} @ #{price}, quantity: #{quantity}")

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_buy(symbol, quantity, price, "GTC")

    {:noreply, %{state | buy_order: order}}
  end

  def handle_cast(
        %TradeEvent{buyer_order_id: order_id, quantity: quantity},
        %State{
          symbol: symbol,
          buy_order: %Binance.OrderResponse{
            price: buy_price,
            order_id: order_id,
            orig_qty: quantity
          },
          profit_interval: profit_interval,
          tick_size: tick_size
        } = state
      ) do
    sell_price = calculate_sell_price(buy_price, profit_interval, tick_size)

    Logger.info(
      "Buy order filled, placing SELL order for " <>
        "#{symbol} @ #{sell_price}, quantity: #{quantity}"
    )

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_sell(symbol, quantity, sell_price, "GTC")

    {:noreply, %{state | sell_order: order}}
  end

  def handle_cast(
        %TradeEvent{seller_order_id: order_id, quantity: quantity},
        %State{sell_order: %Binance.OrderResponse{order_id: order_id, orig_qty: quantity}} = state
      ) do
    Logger.info("Trade finished, trader will now exit")

    {:stop, :normal, state}
  end

  def handle_cast(%TradeEvent{}, state) do
    {:noreply, state}
  end

  defp fetch_tick_size(symbol) do
    Binance.get_exchange_info()
    |> elem(1)
    |> Map.get(:symbols)
    |> Enum.find(&(&1["symbol"] == symbol))
    |> Map.get("filters")
    |> Enum.find(&(&1["filterType"] == "PRICE_FILTER"))
    |> Map.get("tickSize")
    |> Decimal.new()
  end

  defp calculate_sell_price(buy_price, profit_interval, tick_size) do
    fee = Decimal.new("1.001")

    buy_price
    |> Decimal.new()
    |> Decimal.mult(fee)
    |> Decimal.mult(Decimal.add("1.0", profit_interval))
    |> Decimal.mult(fee)
    |> Decimal.div_int(tick_size)
    |> Decimal.mult(tick_size)
    |> Decimal.to_float()
  end
end
