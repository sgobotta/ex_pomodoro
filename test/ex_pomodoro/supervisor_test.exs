defmodule ExPomodoro.SupervisorTest do
  @moduledoc false

  use ExUnit.Case

  describe "#{ExPomodoro.Supervisor}" do
    setup do
      pid = start_supervised!(ExPomodoro.Supervisor)

      %{pid: pid}
    end

    test "child_spec/2 starts a supervisor", %{pid: pid} do
      assert valid_pid?(pid)
    end

    test "child_spec/2 spawns children", %{pid: pid} do
      children = Supervisor.which_children(pid)

      assert length(children) == 2

      [pomodoro_supervisor, pomodoro_registry] = children

      {ExPomodoro.PomodoroSupervisor, pomodoro_supervisor_pid, :supervisor,
       [ExPomodoro.PomodoroSupervisor]} = pomodoro_supervisor

      {Registry.Pomodoro, pomodoro_registry_pid, :supervisor, [Registry]} =
        pomodoro_registry

      assert valid_pid?(pomodoro_supervisor_pid)
      assert valid_pid?(pomodoro_registry_pid)
    end
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)
end
