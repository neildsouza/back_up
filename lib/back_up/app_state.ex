defmodule BackUp.AppState do
  use GenServer

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      %{
	backup_folder: "",
	start_folder: ""
      },
      name: __MODULE__
    )
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def set_backup_folder(folder) do
    GenServer.call(__MODULE__, {:set_backup_folder, folder})
  end

  def set_start_folder(folder) do
    GenServer.call(__MODULE__, {:set_start_folder, folder})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end

  def handle_call({:set_backup_folder, folder}, _, state) do
    if state.start_folder != "" do
      unless String.contains?(folder, state.start_folder) do
	state =
	  state
	  |> Map.put(:backup_folder, Path.split(folder) |> Path.join())
	{:reply, state, state}
      else
	{:reply, "Start folder cannot contain backup folder", state}
      end
    else
      {:reply, "Please set start folder first", state}
    end
  end

  def handle_call({:set_start_folder, folder}, _, state) do
    state =
      state
      |> Map.put(:start_folder, Path.split(folder) |> Path.join())
    {:reply, state, state}
  end
end
