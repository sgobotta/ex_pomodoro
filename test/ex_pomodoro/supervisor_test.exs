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

      assert length(children) == 1

      {ExPomodoro.PomodoroSupervisor, child_pid, :supervisor, _modules} =
        hd(children)

      assert valid_pid?(child_pid)
    end
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)
end
