defmodule BackUp do
  alias BackUp.AppState

  def remove_all_backup_folders() do
    AppState.remove_all_backup_folders()
  end
  
  def remove_backup_folder(folder) do
    AppState.remove_backup_folder(folder)
  end
  
  def reset() do
    AppState.reset_state()
  end
  
  def start() do
    reset()
    
    set_from_config()
    
    AppState.set_start_time()
    app_state = AppState.get_state()
    
    cond do
      app_state.start_folder == "" ->
	IO.puts("Please set the start folder")
      app_state.backup_folders == [] ->
	IO.puts("Please set the backup folder")
      true ->
	IO.puts("Here goes nothing ...")
	{:ok, pid} = DynamicSupervisor.start_child(
	  BackUp.FilesystemSup,
	  {
	    BackUp.Folder,
	    %{
	      current_folder: app_state.start_folder
	    }
	  }
	)
	BackUp.Folder.crawl_folder(pid)
	BackUp.TallyProc.get_pending()
    end
  end

  def set_backup_folder(folder) do
    AppState.set_backup_folder(folder)
  end

  def set_from_config() do
    case File.read("priv/folders.txt") do
      {:ok, config} ->
	all_folders = Enum.filter(String.split(config, "\n"), fn(folder) ->
	  String.trim(folder) != ""
        end)
	[start_folder | backup_folders] = all_folders
	set_start_folder(start_folder)
	Enum.each(backup_folders, fn(folder) -> set_backup_folder(folder) end)
	
      {:error, reason} ->
	msg = """
	  Msg: Cannot read config
	Error: #{inspect(reason)}
	"""
	IO.puts(msg)
    end
  end

  def set_start_folder(folder) do
    AppState.set_start_folder(folder)
  end
end
