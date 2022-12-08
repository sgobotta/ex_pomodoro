defmodule ExPomodoro.Helpers.DummyCallbackModule do
  @moduledoc false

  require Logger

  @doc """
  Helper function to test callbacks from the Pomodoro Server.
  """
  @spec handle_activity_changed(any()) :: :ok
  def handle_activity_changed(payload) do
    :ok =
      Logger.debug(
        "#{__MODULE__}.handle_activity_changed payload=#{inspect(payload, pretty: true)}"
      )
  end
end
