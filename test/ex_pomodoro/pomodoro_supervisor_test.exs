defmodule ExPomodoro.PomodoroSupervisorTest do
  @moduledoc """
  Pomodoro Supervisor tests
  """
  use ExUnit.Case

  describe "pomodoro_supervisor" do
    alias ExPomodoro.Pomodoro
    alias ExPomodoro.PomodoroSupervisor

    alias ExPomodoro.Fixtures.PomodoroFixtures

    @supervisor_name :pomodoro_supervisor_test

    setup do
      pid = start_supervised!({PomodoroSupervisor, [name: @supervisor_name]})

      %{id: pomodoro_id} = PomodoroFixtures.valid_attrs()

      %{pid: pid, pomodoro: Pomodoro.new(pomodoro_id, [])}
    end

    test "child_spec/2 starts a supervisor", %{pid: pid} do
      assert valid_pid?(pid)
    end

    test "start_child/2 starts a server with args", %{
      pid: pid,
      pomodoro: %Pomodoro{id: pomodoro_id}
    } do
      {:ok, pid} = start_child(pid, id: pomodoro_id)

      assert valid_pid?(pid)
    end

    test "list_children/1 returns a list of pids", %{
      pid: pid,
      pomodoro: %Pomodoro{id: pomodoro_id}
    } do
      {:ok, child_pid} = start_child(pid, id: pomodoro_id)

      assert Enum.member?(list_children(pid), child_pid)
    end

    test "get_child/1 returns a pid and state", %{
      pid: pid,
      pomodoro: %Pomodoro{id: pomodoro_id}
    } do
      {:ok, child_pid} = start_child(pid, id: pomodoro_id)

      {^child_pid, %{id: ^pomodoro_id} = state} = get_child(pid, pomodoro_id)

      valid_pid?(child_pid)
      assert is_map(state)
    end

    test "terminate_child/2 shuts down a pid", %{
      pid: pid,
      pomodoro: %Pomodoro{id: pomodoro_id}
    } do
      {:ok, child_pid} = start_child(pid, id: pomodoro_id)

      assert valid_pid?(child_pid)

      :ok = terminate_child(pid, child_pid)
      refute valid_pid?(child_pid)
    end

    defp start_child(pid, args), do: PomodoroSupervisor.start_child(pid, args)

    defp list_children(pid), do: PomodoroSupervisor.list_children(pid)

    defp get_child(pid, pomodoro_id),
      do: PomodoroSupervisor.get_child(pid, pomodoro_id)

    defp terminate_child(pid, child_pid),
      do: PomodoroSupervisor.terminate_child(pid, child_pid)
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)
end
