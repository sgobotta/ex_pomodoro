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

  describe "#{PomodoroServer} timeout lifecycle" do
    test "a server starts properly" do
      # Setup
      pid = start_server(timeout: ratio(2))
      assert is_pid(pid)

      # Exercise
      :ok = sleep_with_ratio(1)

      # Verify
      assert Process.alive?(pid)
    end

    test "a server is terminated on timeout" do
      # Setup
      pid = start_server(timeout: ratio(2))
      assert is_pid(pid)

      # Exercise
      :ok = sleep_with_ratio(1)
      assert Process.alive?(pid)

      # Verify
      :ok = sleep_with_ratio(1)
      refute Process.alive?(pid)
    end
  end

  describe "#{PomodoroServer} exercise" do
    test "state changes to break when exercise duration is completed" do
      # Setup
      args = [
        timeout: ratio(30),
        exercise_duration: ratio(15),
        break_duration: ratio(5),
        rounds: 1
      ]

      pid = start_server(args)
      assert is_pid(pid)

      # Exercise
      assert Process.alive?(pid)
      sleep_with_ratio(15)

      # Verify

      %Pomodoro{
        activity: :break,
        current_round: 0
      } = do_get_state(pid)

      # Teardown
      sleep_with_ratio(30)
      refute Process.alive?(pid)
    end
  end

  describe "#{PomodoroServer} client interface" do
    setup do
      %Pomodoro{id: id} = pomodoro = do_new([])

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

  defp start_server(opts) do
    %{id: pomodoro_id} = PomodoroFixtures.valid_attrs()
    %Pomodoro{id: ^pomodoro_id} = Pomodoro.new(pomodoro_id, [])

    args =
      [
        id: pomodoro_id,
        timeout: Keyword.fetch!(opts, :timeout)
      ]
      |> Keyword.merge(opts)

    start_supervised!({PomodoroServer, args})
  end

  describe "#{PomodoroServer} implementation" do
    setup do
      %Pomodoro{id: id} = pomodoro = do_new()
      args = [id: id]
      state = PomodoroServer.initial_state(args)

      %{state: state, pomodoro: pomodoro}
    end

    test "handle_call/3 :get_state replies with a state", %{
      state: state,
      pomodoro: %Pomodoro{id: pomodoro_id} = pomodoro
    } do
      expected_state = %{
        activity_ref: nil,
        id: pomodoro_id,
        pomodoro: pomodoro,
        timeout: @server_default_timeout,
        timeout_ref: nil
      }

      response = PomodoroServer.handle_call(:get_state, self(), state)

      {:reply, ^pomodoro, ^expected_state} = response
    end
  end

  defp do_new(opts \\ []) do
    %{id: pomodoro_id} = PomodoroFixtures.valid_attrs(Enum.into(opts, %{}))
    %Pomodoro{id: ^pomodoro_id} = Pomodoro.new(pomodoro_id, [])
  end
end
