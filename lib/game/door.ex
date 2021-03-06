defmodule Game.Door do
  @moduledoc """
  Door tracker, know if the door is open or closed
  """

  use GenServer

  alias Data.Exit

  @typedoc """
  Door status is `open` or `closed`
  """
  @type status :: String.t()

  @key :doors
  @closed "closed"
  @open "open"

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #
  # Client
  #

  @doc """
  Maybe load a door, only if the exit has a door
  """
  @spec maybe_load(Exit.t()) :: :ok
  def maybe_load(room_exit)
  def maybe_load(%{id: id, has_door: true}), do: load(id)
  def maybe_load(_), do: :ok

  @doc """
  Load a new door into the ETS table
  """
  @spec load(integer()) :: :ok
  def load(%{id: id}), do: load(id)

  def load(exit_id) do
    members = :pg2.get_members(@key)

    Enum.each(members, fn member ->
      GenServer.call(member, {:load, exit_id})
    end)

    @closed
  end

  @doc """
  Get the state of a door
  """
  @spec get(integer()) :: String.t()
  def get(exit_id) do
    case Cachex.get(@key, exit_id) do
      {:ok, state} when state != nil ->
        state

      _ ->
        load(exit_id)
    end
  end

  @doc """
  Set the state of a door, state must be `#{@open}` or `#{@closed}`
  """
  @spec set(Exit.t(), status()) :: :ok
  def set(%{id: id}, state) when state in [@open, @closed], do: set(id, state)

  @spec set(integer(), status()) :: :ok
  def set(exit_id, state) when state in [@open, @closed] do
    members = :pg2.get_members(@key)

    Enum.each(members, fn member ->
      GenServer.call(member, {:set, exit_id, state})
    end)

    state
  end

  @doc """
  Check if a door is closed
  """
  @spec closed?(integer()) :: boolean
  def closed?(exit_id) do
    case get(exit_id) do
      nil ->
        nil

      state ->
        state == @closed
    end
  end

  @doc """
  Check if a door is open
  """
  @spec open?(integer()) :: boolean
  def open?(exit_id) do
    case get(exit_id) do
      nil ->
        nil

      state ->
        state == @open
    end
  end

  @doc """
  Remove an exit from the ETS table after being deleted.
  """
  @spec remove(Exit.t()) :: :ok
  def remove(room_exit)

  def remove(%{id: id}) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:remove, id})
    end)
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  #
  # Server
  #

  def init(_) do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    {:ok, %{}}
  end

  def handle_call({:load, exit_id}, _from, state) do
    Cachex.set(@key, exit_id, @closed)
    {:reply, @closed, state}
  end

  def handle_call({:set, exit_id, door_state}, _from, state) do
    Cachex.set(@key, exit_id, door_state)
    {:reply, door_state, state}
  end

  def handle_call({:remove, exit_id}, _from, state) do
    Cachex.del(@key, exit_id)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)
    {:reply, :ok, state}
  end
end
