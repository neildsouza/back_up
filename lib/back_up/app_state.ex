defmodule BackUp.AppState do
  use GenServer

  @init_state %{
    backup_folders: [],
    ignore_folders: [],
    ignore_files: [],
    mirror_folders: [],
    start_folder: ""
  }

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      @init_state,
      name: __MODULE__
    )
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def remove_all_backup_folders() do
    GenServer.call(__MODULE__, :remove_all_backup_folders)
  end

  def remove_backup_folder(folder) do
    GenServer.call(__MODULE__, {:remove_backup_folder, folder})
  end

  def reset_state() do
    GenServer.call(__MODULE__, :reset_state)
  end

  def set_backup_folder(folder) do
    GenServer.call(__MODULE__, {:set_backup_folder, folder})
  end

  def set_ignore_file(file) do
    GenServer.call(__MODULE__, {:set_ignore_file, file})
  end

  def set_ignore_folder(folder) do
    GenServer.call(__MODULE__, {:set_ignore_folder, folder})
  end

  def set_mirror_folder(folder) do
    GenServer.call(__MODULE__, {:set_mirror_folder, folder})
  end

  def set_start_folder(folder) do
    GenServer.call(__MODULE__, {:set_start_folder, folder})
  end

  def set_start_time() do
    GenServer.call(__MODULE__, :set_start_time)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end

  def handle_call(:remove_all_backup_folders, _, state) do
    state = put_in(state.backup_folders, [])
    {:reply, state, state}
  end

  def handle_call({:remove_backup_folder, folder}, _, state) do
    folder = Path.split(folder) |> Path.join()
    backup_folders = Enum.filter(state.backup_folders, fn(backup_folder) ->
      backup_folder != folder
    end)
    state = put_in(state.backup_folders, backup_folders)
    {:reply, state, state}
  end

  def handle_call(:reset_state, _, _state) do
    {:reply, @init_state, @init_state}
  end

  def handle_call({:set_backup_folder, folder}, _, state) do
    if state.start_folder != "" do
      unless String.contains?(folder, state.start_folder) do
	folder = Path.split(folder) |> Path.join()

	unless Enum.member?(state.backup_folders, folder) do
	  state = put_in(
	    state,
	    [:backup_folders],
	    state.backup_folders ++ [folder]
	  )
	  
	  {:reply, state, state}
	else
	  {:reply, state, state}
	end
      else
	{:reply, "Start folder cannot contain backup folder", state}
      end
    else
      {:reply, "Please set start folder first", state}
    end
  end

  def handle_call({:set_ignore_file, file}, _, state) do
    if state.start_folder != "" do
      if String.contains?(file, state.start_folder) do
	file = Path.split(file) |> Path.join()

	unless Enum.member?(state.ignore_files, file) do
	  state = put_in(
	    state,
	    [:ignore_files],
	    state.ignore_files ++ [file]
	  )
	  
	  {:reply, state, state}
	else
	  {:reply, state, state}
	end
      else	
	{:reply, state, state}
      end
    else
      {:reply, "Please set start folder first", state}
    end
  end

  def handle_call({:set_ignore_folder, folder}, _, state) do
    if state.start_folder != "" do
      if String.contains?(folder, state.start_folder) do
	folder = Path.split(folder) |> Path.join()

	unless Enum.member?(state.ignore_folders, folder) do
	  state = put_in(
	    state,
	    [:ignore_folders],
	    state.ignore_folders ++ [folder]
	  )
	  
	  {:reply, state, state}
	else
	  {:reply, state, state}
	end
      else
	{:reply, state, state}
      end
    else
      {:reply, "Please set start folder first", state}
    end
  end

  def handle_call({:set_mirror_folder, folder}, _, state) do
    if state.start_folder != "" do
      if String.contains?(folder, state.start_folder) do
	folder = Path.split(folder) |> Path.join()

	unless Enum.member?(state.mirror_folders, folder) do
	  state = put_in(
	    state,
	    [:mirror_folders],
	    state.mirror_folders ++ [folder]
	  )
	  
	  {:reply, state, state}
	else
	  {:reply, state, state}
	end
      else
	{:reply, state, state}
      end
    else
      {:reply, "Please set start folder first", state}
    end
  end

  def handle_call({:set_start_folder, folder}, _, state) do
    folder = Path.split(folder) |> Path.join()
    state = put_in(state, [:start_folder], folder)
    {:reply, state, state}
  end

  def handle_call(:set_start_time, _, state) do
    {:reply, :ok, put_in(state, [:start_time], Time.utc_now())}
  end
end
