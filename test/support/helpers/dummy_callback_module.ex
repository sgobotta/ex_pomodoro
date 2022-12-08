defmodule ExPomodoro.Helpers.DummyCallbackModule do
  @moduledoc false

  require Logger

  @doc """
  Helper function to test callbacks from the Pomodoro Server.
  """
  @spec handle_activity_change(any()) :: :ok
  def handle_activity_change(payload) do
    :ok =
      Logger.debug(
        "#{__MODULE__}.on_activity_change payload=#{inspect(payload, pretty: true)}"
      )
  end
end
