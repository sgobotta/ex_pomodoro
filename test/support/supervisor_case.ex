defmodule ExPomodoro.SupervisorCase do
  @moduledoc """
  This module defines helpers for tests that require Supervisor setup.
  """

  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      alias ExPomodoro.Helpers.DummyCallbackModule

      opts = unquote(opts)

      @doc """
      Convenience function to use in tests setup where a Supervisor needs to be
      started.
      """
      @spec configure_supervisor :: :ok
      def configure_supervisor do
        :ok =
          Application.put_env(
            :ex_pomodoro,
            :callback_module,
            DummyCallbackModule
          )

        on_exit(fn ->
          :ok = Application.delete_env(:ex_pomodoro, :callback_module)
        end)
      end
    end
  end
end
