defmodule ExPomodoroTest do
  @moduledoc false

  use ExUnit.Case
  doctest ExPomodoro

  describe "#{ExPomodoro}" do
    test "child_spec/1 returns an #{ExPomodoro.Supervisor} spec" do
      %{
        id: ExPomodoro.Supervisor,
        start: {ExPomodoro.Supervisor, :start_link, [[]]},
        type: :supervisor
      } = ExPomodoro.child_spec([])
    end
  end
end
