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
      IO.puts("Folder: #{state.current_folder}, Files: #{length(state.files)}")
      Enum.each(state.files, fn(file_path) ->
	Enum.each(state.backup_dst_folders, fn(backup_dst_folder) ->
	  Task.start(fn ->
	    dst_path = String.replace(
	      file_path,
	      state.start_folder,
	      backup_dst_folder.backup_folder
            )

	    if File.exists?(dst_path) do
	      case File.cp(file_path, dst_path, &cp_file/2) do
		:ok ->
		  write_file_stats(file_path, dst_path)
		{:error, reason} ->
		  msg = """
		     Msg: Error backing up file #{file_path} to #{dst_path}
		  Reason: #{inspect reason}
		  """	
		  IO.puts(msg)
	      end
	    else
	      case File.cp(file_path, dst_path) do
		:ok ->
		  write_file_stats(file_path, dst_path)
		  IO.puts("#{file_path} --> #{dst_path}")
		{:error, reason} ->
		  msg = """
		     Msg: Error backing up file #{file_path} to #{dst_path}
		  Reason: #{inspect reason}
		  """
		  IO.puts(msg)
	      end
	    end
	  end)
	end)
      end)
    else
      IO.puts("Folder: #{state.current_folder}, Files: #{length(state.files)}")
    end
  end

  defp cp_file(src_file, dst_file) do
    src_hash_task = Task.async(fn ->
      Filesystem.hash_content(src_file)
    end)

    dst_hash_task = Task.async(fn ->
      Filesystem.hash_content(dst_file)
    end)

    src_hash = Task.await(src_hash_task, :infinity)
    dst_hash = Task.await(dst_hash_task, :infinity)
    
    unless src_hash  == dst_hash do
      IO.puts("#{src_file} --> #{dst_file}")
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

  defp write_file_stats(file_path, dst_path) do
    file_path_stat = File.stat!(file_path, time: :posix)
    File.write_stat(dst_path, file_path_stat, time: :posix)
  end
end
