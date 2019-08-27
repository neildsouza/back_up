defmodule BackUp.Folder do
  use GenServer, restart: :transient

  alias BackUp.AppState
  
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
      |> Map.put(:ignore_folders, app_state.ignore_folders)
      |> Map.put(:ignore_files, app_state.ignore_files)
      |> Map.put(:mirror_folders, app_state.mirror_folders)
    
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
    provision_links(state)
    
    {:stop, :shutdown, state}
  end

  def handle_cast(:crawl_folder, state) do
    Task.start(fn ->
      delete_if_mirrored(state)
    end)
    
    case BackUp.Filesystem.crawl_folder(state.current_folder) do
      {:ok, files_folders_links} ->
	state = state |> Map.merge(files_folders_links)

	if length(state.folders) > 0 do
	  Enum.each(state.folders, fn(folder) ->
	    cond do
	      Enum.member?(state.ignore_folders, folder) ->
		IO.puts("Ignoring folder #{folder}")

	      true ->
		{:ok, pid} =
		  DynamicSupervisor.start_child(
		    BackUp.FilesystemSup,
		    {
		      BackUp.Folder, %{current_folder: folder}
		    }
		  )

		BackUp.Folder.crawl_folder(pid)
	    end
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
      relevant_files = state.files -- state.ignore_files
      
      all_file_stats = Enum.map(relevant_files, fn(src_file) ->
	case File.lstat(src_file, time: :posix) do
	  {:ok, src_file_stat} -> src_file_stat

	  {:error, reason} ->
	    msg = """
	      Msg: Cannot get file stat for #{src_file}
	    Error: #{inspect(reason)}
	    """
	    IO.puts(msg)
	end
      end)

      all_files_with_stats = Enum.zip(relevant_files, all_file_stats)
      
      Enum.each(all_files_with_stats, fn({src_file, file_stat}) ->
	Enum.each(state.backup_dst_folders, fn(backup_dst_folder) ->
	  {:ok, pid} =
	    DynamicSupervisor.start_child(
	      BackUp.FilesystemSup,
	      {
		BackUp.FileCopyProc,
		%{
		  src_file: src_file,
		  src_file_stat: file_stat,
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

  defp delete_if_mirrored(state) do
    mirrored? = Enum.any?(state.mirror_folders, fn(mirror_folder) ->
      String.contains?(state.current_folder, mirror_folder)
    end)

    if mirrored? do
      Enum.each(state.backup_dst_folders, fn(backup_dst_folder) ->
	{:ok, pid} =
	  DynamicSupervisor.start_child(
	    BackUp.FilesystemSup,
	    {
	      BackUp.DeleteExtraFilesProc,
	      %{
		current_folder: state.current_folder,
		start_folder: state.start_folder,
		dst_folder: backup_dst_folder.dst_folder,
		backup_folder: backup_dst_folder.backup_folder
	      }
	    }
	  )
	
	BackUp.DeleteExtraFilesProc.run(pid)
      end)
    end
  end

  defp provision_links(state) do
    Enum.each(state.links, fn(link) ->
      case File.read_link(link) do
	{:ok, path} ->
	  Enum.each(state.backup_dst_folders, fn(backup_dst_folder) ->
	    new_link_path =
	      String.replace(
		link,
		state.start_folder,
		backup_dst_folder.backup_folder
	      )
	    
	    new_path =
	      String.replace(
		path,
		state.start_folder,
		backup_dst_folder.backup_folder
	      )

	    BackUp.LinkCreationProc.add({new_path, new_link_path})
	  end)
      end
    end)
  end
end
