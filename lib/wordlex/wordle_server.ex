defmodule Wordle do
  use GenServer
  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  @impl true
  def init(_) do
    words =
      HTTPoison.get!(
        "https://gist.githubusercontent.com/dracos/dd0668f281e685bad51479e5acaadb93/raw/6bfa15d263d6d5b63840a8e5b64e04b382fdb079/valid-wordle-words.txt"
      ).body
      |> String.split("\n")

    word = Enum.random(words)
    initial_state = {word, %{}}
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:guess, user_id, guess}, {word, games}) do
    {:noreply, {word, find_game(games, user_id) |> add_guess(guess)}}
  end

  @impl true
  def handle_call({:completed?, user_id}, _from, {_, games} = state) do
    {:reply, Wordle.Game.completed?(find_game(games, user_id)), state}
  end

  @impl true
  def handle_call({:get_guessed, user_id}, _from, {_, games} = state) do
    {:reply, find_game(games, user_id).guesses, state}
  end

  @impl true
  def handle_call(:start_new_game, _from, {word, games}) do
    new_id = Enum.max_by(Map.keys(games), & &1, fn -> 0 end) + 1

    {:reply, new_id, {word, Map.put(games, new_id, %Wordle.Game{})}}
  end

  def start_new_game() do
    GenServer.call(@name, :start_new_game)
  end

  def guess(user_id, guess) do
    GenServer.cast(@name, {:guess, user_id, guess})
  end

  def get_guesses(user_id) do
    GenServer.call(@name, {:get_guessed, user_id})
  end

  def completed?(user_id) do
    GenServer.call(@name, {:completed?, user_id})
  end

  defp add_guess(%Wordle.Game{} = game, guess) do
    case Wordle.Game.calculate_guess(game, guess) do
      {:ok, result} -> Map.update!(game, :guesses, &[{guess, result} | &1])
      {:error, _} -> game
    end
  end

  defp find_game(games, user_id) do
    Map.get(games, user_id)
  end
end
