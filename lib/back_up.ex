defmodule BackUp do
  alias BackUp.AppState

  def test do
    BackUp.set_start_folder("/home/neil/stuff")
    BackUp.set_backup_folder("/home/neil/test_backup")
    BackUp.start
  end
  
  def start() do
    folder_dir_state = AppState.get_state()
    cond do
      folder_dir_state.start_folder == "" ->
	IO.puts("Please set the start folder")
      folder_dir_state.backup_folder == "" ->
	IO.puts("Please set the backup folders")
      true ->
	IO.puts("Here goes nothing ...")
	{:ok, pid} = DynamicSupervisor.start_child(
	  BackUp.FilesystemSup,
	  {
	    BackUp.Folder,
	    %{
	      current_folder: folder_dir_state.start_folder
	    }
	  }
	)
	BackUp.Folder.crawl_folder(pid)
    end
  end

  def set_backup_folder(folder) do
    AppState.set_backup_folder(folder)
  end

  def set_start_folder(folder) do
    AppState.set_start_folder(folder)
  end
end
