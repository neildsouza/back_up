defmodule BackUp.DeleteExtraFilesProc do
  use GenServer, restart: :transient

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def run(pid) do
    GenServer.cast(pid, :run)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast(:run, state) do
    case File.ls(state.current_folder) do
      {:ok, files_and_folders} ->
	dst_folder = state.dst_folder

	if File.dir?(dst_folder) do
	  case File.ls(dst_folder) do
	    {:ok, dst_files_and_folders} ->
	      # Will get files & folders that don't exist in the current_folder
	      temp = dst_files_and_folders -- files_and_folders

	      Enum.each(temp, fn(file_or_dir) ->
		unless File.dir?(file_or_dir) do
		  file = file_or_dir

		  dst_file = state.dst_folder <> "/" <> file

		  case File.rm(dst_file) do
		    :ok ->
		      IO.puts("Deleted #{dst_file}")

		    {:error, reason} ->
		      msg = """
		        Msg: Could not delete file #{dst_file}
		      Error: #{IO.inspect reason}
		      """
		      IO.puts(msg)
		  end
		end
	      end)

	    {:error, reason} ->
	      msg = """
	        Msg: Could not File.ls #{dst_folder}
	      Error: #{IO.inspect reason}
	      """
	      IO.puts(msg)
	  end
	end

      {:error, reason} ->
	msg = """
	  Msg: Could not File.ls #{state.current_folder}
	Error: #{IO.inspect reason}
	"""
	IO.puts(msg)
    end

    {:stop, :shutdown, state}
  end
end
