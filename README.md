# ExPomodoro

**The `ex_pomodoro` program is a simple set of functions that let developers manage pomodoro sessions withing their Elixir applications.**

<h4 align="center">
  An Elixir Pomodoro 🍅
</h4>

<p align="center" style="margin-top: 14px;">
  <a href="https://github.com/sgobotta/ex_pomodoro/actions/workflows/ci.yml">
    <img
      src="https://github.com/sgobotta/ex_pomodoro/actions/workflows/ci.yml/badge.svg?branch=main"
      alt="CI Status"
    >
  </a>
  <a
    href='https://coveralls.io/github/sgobotta/ex_pomodoro?branch=main'
  >
    <img
      src='https://coveralls.io/repos/github/sgobotta/ex_pomodoro/badge.svg?branch=main'
      alt='Coverage Status'
    />
  </a>
</p>

<p align="center" style="margin-top: 14px;">
  <a
    href="https://github.com/sgobotta/ex_pomodoro/blob/main/LICENSE"
  >
    <img
      src="https://img.shields.io/badge/License-GPL%20v3-white.svg"
      alt="License"
    >
  </a>
</p>

## Introduction

> [About the Pomodoro technique](https://en.wikipedia.org/wiki/Pomodoro_Technique)

**ExPomodoro** is an Elixir library that let developers easily manage pomodoro sessions by using a simple set of fuctions that can start a pomodoro session, pause a session, get the current session details.

The motivation behind **ExPomodoro** development was initially driven by HTTP integrations in chat applications, such as [Mattermost](https://en.wikipedia.org/wiki/Mattermost) or [Slack](https://es.wikipedia.org/wiki/Slack_(software)), where one could create slash commands that interact to an HTTP server or create bots that send and receive notifications. This library includes only the domain logic for managing pomodoro sessions.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_pomodoro` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_pomodoro, "~> 1.0.0"}
  ]
end
```

Otherwise it can be installed using the git remote url:

```elixir
def deps do
  [
    {:ex_pomodoro,
     git: "git@github.com:sgobotta/ex_pomodoro.git", tag: "1.0.0"}
  ]
end
```

## Setup

**ExPomodoro** uses a `Supervisor` and `GenServer` to perform runtime operations for pomodoros. Add the `ExPomodoro` child spec to your application tree.

*application.ex:*

```elixir
@impl true
def start(_type, _args) do
  children = [
      ...

      ExPomodoro # <- Add ExPomodoro to the children array
    ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Create a module that implements the following function. This is used to receive callbacks from the lib.

*your_callback_module.ex:*

```elixir
defmodule MyApp.ExPomodoroClient do
  @moduledoc false

  require Logger

  @doc """
  Helper function to test callbacks from the Pomodoro Server.
  """
  @spec handle_activity_changed(any()) :: :ok
  def handle_activity_changed(payload) do
    :ok =
      Logger.debug(
        "#{__MODULE__}.handle_activity_changed payload=#{inspect(payload, pretty: true)}"
      )
  end
end
```

*runtime.exs:*

```elixir
config :ex_pomodoro,
  callback_module: MyApp.ExPomodoroClient
```

## Usage

The `ExPomodoro` is the main module to interact with the APIs using a `Pomodoro` struct. There should be no need to use the rest of modules that handle runtime logic.

A `Pomodoro` has four states: `:idle`, `:exercise`, `:break`, `:finished`

Calling the APIs affect the state, and return an updated `Pomodoro` struct.

All pomodoro functions are documented, check the [`ExPomodoro`](./lib/ex_pomodoro.ex) for more usage examples.

### Start a pomodoro session

A `%Pomodoro{}` is created with an `id` that must be unique between sessions. Starting a pomodoro with a non-unique id will cause no effect.

This command will create a pomodoro with default options. The work time is `25` minutes by default, the break time is `5` and the number of periods is `4`.

```elixir
iex> ExPomodoro.start("some id")
{:ok, %ExPomodoro.Pomodoro{
  id: "some id",
  activity: :exercise,
  exercise_duration: 1_500_000,
  break_duration: 300_000,
  rounds: 4
}}
```

Check the [`ExPomodoro`](./lib/ex_pomodoro.ex) module docs for examples with options.

### Pause a pomodoro session

A `%Pomodoro{}` can be paused by passing the `id`.

```elixir
iex> ExPomodoro.pause("some id")
{:ok, %Pomodoro{
  id: "some id",
  activity: :idle,
  current_duration: timeleft
}}
```

### Get a pomodoro session

A `%Pomodoro{}` can be obtained by passing the `id`.

```elixir
iex> ExPomodoro.get("some id")
{:ok, %ExPomodoro.Pomodoro{id: "some id"}}
```

If the session does not exist, the function returns an error tuple.

```elixir
iex> ExPomodoro.get("some other id")
{:error, :not_found}
```

A `Pomodoro` has a timeout of 90 minutes. if no interaction is made the `Pomodoro` will not be found and it's stats lost.

## Development

### Requirements

* Elixir `1.11` or later. It should work on other versions but it isn't tested.

> If you use `asdf` just run `asdf install` in the root repository to install the required **Elixir** version.

### Installation and setup

Install and compile dependencies and library.

```bash
make setup
```

Run format checks, credo, dialyzer and tests

```bash
make check
```

Run tests only

```bash
make test
```

Run test coverage

```bash
make test.cover
```

Run `make` to find a complete list of commands.

## Future features

* Allow callbacks on `GenServer` creation to support PubSub subscriptions, message passing, notifications and other real-time features.
* Allow description for pomodoro periods

## License

[**GNU General Public License version 3**](LICENSE)
