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

  # ----------------------------------------------------------------------------
  # GenServer lifecycle tests
  #

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

  # ----------------------------------------------------------------------------
  # GenServer implementation tests
  #

  describe "#{PomodoroServer} activity" do
    test "changes when duration is completed" do
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

      sleep_with_ratio(5)

      %Pomodoro{
        activity: :idle,
        current_round: 0
      } = do_get_state(pid)

      # Teardown
      sleep_with_ratio(40)
      refute Process.alive?(pid)
    end
  end

  # ----------------------------------------------------------------------------
  # GenServer interface tests
  #

  describe "#{PomodoroServer}.pause/1" do
    test "changes activity to idle" do
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
      :ok = sleep_with_ratio(5)

      {:ok, %Pomodoro{activity: :idle}} = do_pause(pid)

      # Verify
      %Pomodoro{
        activity: :idle,
        current_round: 0
      } = do_get_state(pid)

      # After some time the activity did not change.
      :ok = sleep_with_ratio(15)

      %Pomodoro{
        activity: :idle,
        current_round: 0
      } = do_get_state(pid)

      # Teardown
      :ok = sleep_with_ratio(40)
      refute Process.alive?(pid)
    end
  end

  describe "#{PomodoroServer}.resume/1" do
    test "continues the previously paused activity" do
      # Setup
      args = [
        timeout: ratio(30),
        exercise_duration: ratio(15),
        break_duration: ratio(5),
        rounds: 1
      ]

      pid = start_server(args)
      assert is_pid(pid)

      assert Process.alive?(pid)

      %Pomodoro{
        activity: :exercise,
        current_round: 0
      } = do_get_state(pid)

      :ok = sleep_with_ratio(5)

      {:ok, %Pomodoro{activity: :idle}} = do_pause(pid)

      # We wait some time but nothing should change, the pomodoro is idle and a
      # timeout is not reached.
      :ok = sleep_with_ratio(25)

      # Exercise
      {:ok, %Pomodoro{activity: :exercise}} = do_resume(pid)

      # Verify
      %Pomodoro{
        activity: :exercise,
        current_round: 0
      } = do_get_state(pid)

      # ------------------------------------------------------------------------
      # Wait until the exercise is completed and the break starts
      #

      # Setup
      :ok = sleep_with_ratio(10)

      %Pomodoro{
        activity: :break,
        current_round: 0
      } = do_get_state(pid)

      :ok = sleep_with_ratio(4)

      {:ok, %Pomodoro{activity: :idle}} = do_pause(pid)

      # We wait some time but nothing should change, the pomodoro is idle and a
      # timeout is not reached.
      :ok = sleep_with_ratio(25)

      # Exercise
      {:ok, %Pomodoro{activity: :break}} = do_resume(pid)

      # Verify
      %Pomodoro{
        activity: :break,
        current_round: 0
      } = do_get_state(pid)

      # ------------------------------------------------------------------------
      # Teardown
      #

      :ok = sleep_with_ratio(5)

      %Pomodoro{
        activity: :idle,
        current_round: 0
      } = do_get_state(pid)

      :ok = sleep_with_ratio(30)

      refute Process.alive?(pid)
    end
  end

  describe "#{PomodoroServer}.get_state/1" do
    setup do
      %Pomodoro{id: id} = pomodoro = do_new([])

      args = [id: id]
      pid = start_supervised!({PomodoroServer, args})

      %{pid: pid, pomodoro: pomodoro}
    end

    test "returns the server state", %{
      pid: pid,
      pomodoro: %Pomodoro{} = pomodoro
    } do
      response = do_get_state(pid)

      assert response == pomodoro
    end
  end

  defp do_get_state(pid), do: PomodoroServer.get_state(pid)

  defp do_pause(pid), do: PomodoroServer.pause(pid)

  defp do_resume(pid), do: PomodoroServer.resume(pid)

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

  # ----------------------------------------------------------------------------
  # GenServer implementation tests
  #

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
      # Setup
      expected_state = %{
        activity_ref: nil,
        id: pomodoro_id,
        pomodoro: pomodoro,
        previous_activity: nil,
        previous_activity_timeleft: nil,
        timeout: @server_default_timeout,
        timeout_ref: nil
      }

      # Exercise
      response = PomodoroServer.handle_call(:get_state, self(), state)

      # Verify
      {:reply, ^pomodoro, ^expected_state} = response
    end

    test "handle_info/2 :on_activity_change updates the Pomodoro activity to break",
         %{
           state: state
         } do
      # Exercise
      response = PomodoroServer.handle_info(:on_activity_change, state)

      # Verify
      {:noreply, %{pomodoro: %Pomodoro{activity: :break}}} = response
    end

    test "handle_info/2 :on_activity_change updates the Pomodoro activity to idle",
         %{
           state: state,
           pomodoro: %Pomodoro{} = pomodoro
         } do
      # Setup
      state = %{
        state
        | pomodoro: Pomodoro.break(pomodoro),
          activity_ref: dummy_timer_ref()
      }

      # Exercise
      response = PomodoroServer.handle_info(:on_activity_change, state)

      # Verify
      {:noreply, %{pomodoro: %Pomodoro{activity: :idle}}} = response
    end
  end

  defp do_new(opts \\ []) do
    %{id: pomodoro_id} = PomodoroFixtures.valid_attrs(Enum.into(opts, %{}))
    %Pomodoro{id: ^pomodoro_id} = Pomodoro.new(pomodoro_id, [])
  end

  defp dummy_timer_ref(timeout \\ 5000),
    do: Process.send_after(self(), :test, timeout)
end
