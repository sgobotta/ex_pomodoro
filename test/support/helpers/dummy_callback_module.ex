defmodule ExPomodoro.Helpers.DummyCallbackModule do
  @moduledoc false

  require Logger

  @doc """
  Helper function to test callbacks from the Pomodoro Server.
  """
  @spec on_activity_change(any()) :: :ok
  def on_activity_change(payload) do
    :ok = Logger.debug("#{__MODULE__}.on_activity_change payload=#{payload}")
  end
end
