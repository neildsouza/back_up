defmodule BackUp do
  alias BackUp.AppState

  def test() do
    BackUp.set_start_folder "/home/neil/downloads"
    BackUp.set_backup_folder "/home/neil/test_folder_1"
    BackUp.set_backup_folder "/home/neil/test_folder_2"
    start()
  end

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
	BackUp.TallyProc.start_link(:ok)
	BackUp.TallyProc.get_pending()
    end
  end

  def set_backup_folder(folder) do
    AppState.set_backup_folder(folder)
  end

  def set_start_folder(folder) do
    AppState.set_start_folder(folder)
  end
end
