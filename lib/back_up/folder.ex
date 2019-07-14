defmodule BackUp.Folder do
  use GenServer, restart: :transient

  alias BackUp.AppState
  alias BackUp.Filesystem
  
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def cp(pid) do
    GenServer.cast(pid, :cp)
  end

  def crawl_folder(pid) do
    GenServer.cast(pid, :crawl_folder)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(state) do
    folder_dir_state = AppState.get_state()
    start_folder = folder_dir_state.start_folder
    backup_folder = folder_dir_state.backup_folder

    dst_folder = String.replace(
      state.current_folder,
      start_folder,
      backup_folder
    )

    state =
      state
      |> Map.put(:start_folder, start_folder)
      |> Map.put(:backup_folder, backup_folder)
      |> Map.put(:dst_folder, dst_folder)
    
    # IO.inspect(state)
    
    {:ok, state}
  end

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end

  def handle_cast(:cp, state) do
    create_folder(state.dst_folder)
    copy_files(state)
    
    {:stop, :shutdown, state}
  end

  def handle_cast(:crawl_folder, state) do
    files_and_folders =
      BackUp.Filesystem.crawl_folder(state.current_folder)
    
    state = state |> Map.merge(files_and_folders)

    if length(state.folders) > 0 do
      Enum.each(state.folders, fn(folder) ->
	{:ok, pid} = DynamicSupervisor.start_child(
	  BackUp.FilesystemSup,
	  {
	    BackUp.Folder,
	    %{
	      current_folder: folder
	    }
	  }
	)
	BackUp.Folder.crawl_folder(pid)
      end)
    end

    # IO.inspect(state)

    cp(self())
    
    {:noreply, state}
  end

  defp copy_files(state) do
    unless state.files == [] do
      Enum.each(state.files, fn(file_path) ->
	dst_path = String.replace(
	  file_path,
	  state.start_folder,
	  state.backup_folder
        )
	
	case File.cp(file_path, dst_path, &cp_file/2) do
	  :ok ->
	    IO.puts("Backed up #{file_path} to #{dst_path}")
	  {:error, reason} ->
	    msg = """
	    Msg: Error backing up file #{file_path} to #{dst_path}
	    Reason: #{inspect reason}
	    """
	    IO.puts(msg)
	end
      end)
    else
      IO.puts("No files to back up from #{state.current_folder}")
    end
  end

  defp cp_file(src_file, dst_file) do
    src_hash_task = Task.async(fn ->
      Filesystem.hash_content(src_file)
    end)
    dst_hash_task = Task.async(fn ->
      Filesystem.hash_content(dst_file)
    end)
    
    unless Task.await(src_hash_task) == Task.await(dst_hash_task) do
      true
    else
      false
    end
  end

  defp create_folder(dst_folder) do
    unless File.exists?(dst_folder) do
      case File.mkdir_p(dst_folder) do
	:ok -> "Created folder #{dst_folder}"
	{:error, reason} ->
	  msg = """
	    Msg: Cannot create directory #{dst_folder}
	  Error: #{inspect(reason)}
	  """
	  IO.puts(msg)
      end
    end
  end
end
