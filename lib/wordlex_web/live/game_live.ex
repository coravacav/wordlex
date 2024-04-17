defmodule WordlexWeb.WordleSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "my_schema" do
    field(:text_field, :string)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:text_field])
    |> validate_length(:text_field, is: 5)
    |> validate_format(:text_field, ~r/^[a-zA-Z0-9]+$/, message: "must be alphanumeric")
  end
end

defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(id: Wordle.start_new_game())
     |> assign(
       form: to_form(WordlexWeb.WordleSubmission.changeset(%WordlexWeb.WordleSubmission{}))
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="game">
      <div class="word">Your id: <%= @id %></div>
      <%!-- put previous guesses here --%>
      <div class="guesses">
        <%!-- for loop over Wordle.get_guesses() --%>
      </div>
      <.form for={@form} phx-change="validate" phx-submit="submit">
        <.input type="text" name="text-field" value={@form[:text_field]} />
        <button type="submit">Submit</button>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"wordle_submission" => params}, socket) do
    changeset =
      %WordlexWeb.WordleSubmission{}
      |> WordlexWeb.WordleSubmission.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: changeset)}
  end

  def handle_event("submit", %{"wordle_submission" => params}, socket) do
    case WordlexWeb.WordleSubmission.changeset(%WordlexWeb.WordleSubmission{}, params) do
      %{valid?: true} = _ ->
        # Handle valid form submission
        {:noreply, socket}

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, form: changeset)}
    end
  end

  def handle_event(a, b, c) do
    IO.inspect({a, b, c})
    {:noreply, c}
  end
end
