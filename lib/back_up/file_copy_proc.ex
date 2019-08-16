defmodule BackUp.FileCopyProc do
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
    dst_file = String.replace(
      state.src_file,
      state.start_folder,
      state.backup_folder
    )

    if File.exists?(dst_file) do
      case File.lstat(dst_file, time: :posix) do
	{:ok, dst_file_stat} ->
	  mtime_check = state.src_file_stat.mtime == dst_file_stat.mtime
	  
	  unless mtime_check do
	    cp_file(state.src_file, dst_file)
	  end
	  
	{:error, reason} ->
	  msg = """
	    Msg: Cannot get file stat for #{dst_file}
	  Error: #{inspect(reason)}
	  """
	  IO.puts(msg)
      end
    else
      cp_file(state.src_file, dst_file)
    end

    {:stop, :shutdown, state}
  end

  defp cp_file(src_file, dst_file) do
    case File.cp(src_file, dst_file) do
      :ok ->
	write_file_stats(src_file, dst_file)
        IO.puts("#{src_file} --> #{dst_file}")

      {:error, reason} ->
	msg = """
	   Msg: Error backing up file #{src_file} to #{dst_file}
	Reason: #{inspect reason}
	"""
	IO.puts(msg)
    end
  end

  defp write_file_stats(src_file, dst_path) do
    src_file_stat = File.stat!(src_file, time: :posix)
    File.write_stat(dst_path, src_file_stat, time: :posix)
  end
end
