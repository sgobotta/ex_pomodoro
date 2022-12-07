defmodule ExPomodoro.SupervisorTest do
  @moduledoc false
  alias ExPomodoro.Helpers.DummyCallbackModule

  use ExUnit.Case
  use ExPomodoro.SupervisorCase

  describe "#{ExPomodoro.Supervisor}" do
    alias ExPomodoro.PomodoroSupervisor

    test "child_spec/2 starts a supervisor" do
      :ok = configure_supervisor()
      pid = start_supervisor()
      assert valid_pid?(pid)
    end

    test "child_spec/2 spawns children" do
      :ok = configure_supervisor()
      pid = start_supervisor()

      children = Supervisor.which_children(pid)

      assert length(children) == 2

      [pomodoro_supervisor, pomodoro_registry] = children

      {PomodoroSupervisor, pomodoro_supervisor_pid, :supervisor,
       [PomodoroSupervisor]} = pomodoro_supervisor

      {Registry.Pomodoro, pomodoro_registry_pid, :supervisor, [Registry]} =
        pomodoro_registry

      assert valid_pid?(pomodoro_supervisor_pid)
      assert valid_pid?(pomodoro_registry_pid)
    end

    test "raises when the callback module is not configured" do
      error = ExPomodoro.Supervisor.missing_callback_module_error()

      assert_raise RuntimeError, ~r/#{error}/, fn ->
        start_supervisor()
      end
    end
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)

  defp start_supervisor, do: start_supervised!(ExPomodoro.Supervisor)
end
