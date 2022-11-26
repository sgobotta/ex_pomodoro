defmodule ExPomodoro.PomodoroServerTest do
  @moduledoc """
  Pomodoro Server tests
  """
  use ExPomodoro.RuntimeCase, ratio: 1 / 32
  use ExUnit.Case

  alias ExPomodoro.Pomodoro
  alias ExPomodoro.PomodoroServer

  alias ExPomodoro.Fixtures.PomodoroFixtures

  @server_default_timeout :timer.minutes(90)

  describe "server lifecycle" do
    test "a server starts properly" do
      pid = start_server(ratio(2))
      assert is_pid(pid)

      :ok = sleep_with_ratio(1)

      assert Process.alive?(pid)
    end

    # test "a server is terminated by timeout" do
    #   pid = start_server(ratio(2))

    #   assert is_pid(pid)

    #   :ok = sleep_with_ratio(1)

    #   assert Process.alive?(pid)
    # end

    defp start_server(_timeout) do
      %{id: pomodoro_id} = PomodoroFixtures.valid_attrs()
      %Pomodoro{id: id} = Pomodoro.new(pomodoro_id, [])

      args = [id: id]

      start_supervised!({PomodoroServer, args})
    end
  end

  describe "server client interface" do
    setup do
      %{id: pomodoro_id} = PomodoroFixtures.valid_attrs()
      %Pomodoro{id: id} = pomodoro = Pomodoro.new(pomodoro_id, [])

      args = [id: id]
      pid = start_supervised!({PomodoroServer, args})

      %{pid: pid, pomodoro: pomodoro}
    end

    test "get_state/2 returns the server state", %{
      pid: pid,
      pomodoro: %Pomodoro{} = pomodoro
    } do
      response = do_get_state(pid)

      assert response == pomodoro
    end
  end

  defp do_get_state(pid), do: PomodoroServer.get_state(pid)

  describe "server implementation" do
    setup do
      %{id: pomodoro_id} = PomodoroFixtures.valid_attrs()
      %Pomodoro{id: id} = pomodoro = Pomodoro.new(pomodoro_id, [])
      args = [id: id]
      state = PomodoroServer.initial_state(args)

      %{state: state, pomodoro: pomodoro}
    end

    test "handle_call/3 :get_state replies with a state", %{
      state: state,
      pomodoro: %Pomodoro{id: pomodoro_id} = pomodoro
    } do
      expected_state = %{id: pomodoro_id, pomodoro: pomodoro, timeout: @server_default_timeout}

      response = PomodoroServer.handle_call(:get_state, self(), state)

      {:reply, ^pomodoro, ^expected_state} = response
    end
  end
end
