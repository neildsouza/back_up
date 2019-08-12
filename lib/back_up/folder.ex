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
    app_state = AppState.get_state()
    start_folder = app_state.start_folder
    backup_folders = app_state.backup_folders

    backup_dst_folders = Enum.reduce(backup_folders, [], fn(backup_folder, acc) ->
      dst = String.replace(
	state.current_folder,
	start_folder,
	backup_folder
      )
      acc ++ [%{backup_folder: backup_folder, dst_folder: dst}]
    end)

    state =
      state
      |> Map.put(:start_folder, start_folder)
      |> Map.put(:backup_dst_folders, backup_dst_folders)
    
    # IO.inspect(state)
    
    {:ok, state}
  end

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end

  def handle_cast(:cp, state) do
    Enum.each(state.backup_dst_folders, fn(backup_dst_folder) ->
      create_folder(backup_dst_folder.dst_folder)
    end)
    
    copy_files(state)
    
    {:stop, :shutdown, state}
  end

  def handle_cast(:crawl_folder, state) do
    case BackUp.Filesystem.crawl_folder(state.current_folder)do
      {:ok, files_and_folders} ->
	state = state |> Map.merge(files_and_folders)

	if length(state.folders) > 0 do
	  Enum.each(state.folders, fn(folder) ->
	    {:ok, pid} =
	      DynamicSupervisor.start_child(
		BackUp.FilesystemSup,
		{
		  BackUp.Folder, %{current_folder: folder}
		}
	      )

	    BackUp.Folder.crawl_folder(pid)
	  end)
	end

	# IO.inspect(state)
	cp(self())
	
	{:noreply, state}
	
      {:error, e} ->
	msg = """
	  Msg: Cannot access directory #{state.current_folder}
        Error: #{inspect e}
	"""
	IO.puts(msg)
	{:noreply, state}
    end
  end

  defp copy_files(state) do
    # IO.puts("Folder: #{state.current_folder}, Files: #{length(state.files)}")
    
    unless state.files == [] do
      all_file_hash_tasks = Enum.map(state.files, fn(src_file) ->
	Task.async(fn ->
	  Filesystem.hash_content(src_file)
	end)
      end)

      all_files_and_tasks = Enum.zip(state.files, all_file_hash_tasks)
      
      Enum.each(all_files_and_tasks, fn({src_file, hash_task}) ->
	src_file_hash = Task.await(hash_task, :infinity)
	
	Enum.each(state.backup_dst_folders, fn(backup_dst_folder) ->
	  {:ok, pid} =
	    DynamicSupervisor.start_child(
	      BackUp.FilesystemSup,
	      {
		BackUp.FileCopyProc,
		%{
		  src_file: src_file,
		  src_file_hash: src_file_hash,
		  start_folder: state.start_folder,
		  backup_folder: backup_dst_folder.backup_folder
		}
	      }
	    )
	  
	  BackUp.FileCopyProc.run(pid)
	end)
      end)
    end
  end
  
  defp create_folder(dst_folder) do
    unless File.exists?(dst_folder) do
      case File.mkdir_p(dst_folder) do
	:ok ->
	  IO.puts("Created folder #{dst_folder}")
	  
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
