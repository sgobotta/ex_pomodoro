defmodule ExPomodoroTest do
  use ExUnit.Case
  doctest ExPomodoro

  test "greets the world" do
    assert ExPomodoro.hello() == :world
  end
end
