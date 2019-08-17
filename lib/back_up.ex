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

  def set_backup_folder(folder) do
    AppState.set_backup_folder(folder)
  end

  def set_from_config() do
    case File.read("priv/backup_configs/folders.txt") do
      {:ok, config} ->
	config_file =
	  Enum.filter(String.split(config, "\n"), fn(folder) ->
	    String.trim(folder) != ""
	  end)

	config_map = parse_config_file(config_file)
	# IO.inspect(config_map)

	if File.exists?(config_map.from) do
	  set_start_folder(config_map.from)
	end

	Enum.each(config_map.to, fn(folder) ->
	  if File.exists?(folder) do
	    set_backup_folder(folder)
	  else
	    IO.puts("Backup folder #{folder} does not exist")
	  end
	end)

	Enum.each(config_map.ignore_folders, fn(folder) ->
	  if File.exists?(folder) do
	    set_ignore_folder(folder)
	  end
	end)

	Enum.each(config_map.ignore_files, fn(file) ->
	  if File.exists?(file) do
	    set_ignore_file(file)
	  end
	end)

	Enum.each(config_map.mirror_folders, fn(folder) ->
	  if File.exists?(folder) do
	    set_mirror_folder(folder)
	  end
	end)
	
      {:error, reason} ->
	msg = """
	  Msg: Cannot read config
	Error: #{inspect(reason)}
	"""
	IO.puts(msg)
    end
  end

  def set_ignore_file(file) do
    AppState.set_ignore_file(file)
  end

  def set_ignore_folder(folder) do
    AppState.set_ignore_folder(folder)
  end

  def set_mirror_folder(folder) do
    AppState.set_mirror_folder(folder)
  end

  def set_start_folder(folder) do
    AppState.set_start_folder(folder)
  end
  
  def start() do
    reset()

    AppState.set_start_time()
    
    set_from_config()
    
    app_state = AppState.get_state()
    # IO.inspect(app_state)
    
    cond do
      app_state.start_folder == "" ->
	IO.puts("Please set the start folder")
      app_state.backup_folders == [] ->
	IO.puts("Please set the backup folders")
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

  defp parse_config_file(config_file) do
    config_map = %{
      current: "",
      from: "",
      to: [],
      ignore_files: [],
      ignore_folders: [],
      mirror_folders: []
    }
    
    Enum.reduce(config_file, config_map, fn(val, acc) ->
      val = String.trim(val)
      
      cond do
	String.downcase(val) == "[from]" ->
	  put_in(acc, [:current], "from")

	String.downcase(val) == "[to]" ->
	  put_in(acc, [:current], "to")

	String.downcase(val) == "[ignore_folders]" ->
	  put_in(acc, [:current], "ignore_folders")

	String.downcase(val) == "[ignore_files]" ->
	  put_in(acc, [:current], "ignore_files")

	String.downcase(val) == "[mirror_folders]" ->
	  put_in(acc, [:current], "mirror_folders")

	val == "" ->
	  :skip

	true ->
	  val = Path.split(val) |> Path.join()
	  
	  case acc.current do
	    "from" -> put_in(acc, [:from], val)

	    "to" -> put_in(acc, [:to], acc.to ++ [val])

	    "ignore_folders" -> put_in(acc, [:ignore_folders], acc.ignore_folders ++ [val])

	    "ignore_files" -> put_in(acc, [:ignore_files], acc.ignore_files ++ [val])

	    "mirror_folders" -> put_in(acc, [:mirror_folders], acc.mirror_folders ++ [val])

	    _ -> IO.puts("Cannot parse #{inspect val}")
	  end
      end
    end)
  end
end
