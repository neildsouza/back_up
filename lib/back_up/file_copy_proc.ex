defmodule BackUp.FileCopyProc do
  use GenServer, restart: :transient

  alias BackUp.Filesystem

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
    dst_path = String.replace(
      state.src_file,
      state.start_folder,
      state.backup_folder
    )

    if File.exists?(dst_path) do
      case File.cp(state.src_file, dst_path, &cp_file/2) do
	:ok ->
	  write_file_stats(state.src_file, dst_path)
	{:error, reason} ->
	  msg = """
	     Msg: Error backing up file #{state.src_file} to #{dst_path}
	  Reason: #{inspect reason}
	  """	
	  IO.puts(msg)
      end
    else
      case File.cp(state.src_file, dst_path) do
	:ok ->
	  write_file_stats(state.src_file, dst_path)
	IO.puts("#{state.src_file} --> #{dst_path}")
	{:error, reason} ->
	  msg = """
	     Msg: Error backing up file #{state.src_file} to #{dst_path}
	  Reason: #{inspect reason}
	  """
	  IO.puts(msg)
      end
    end

    {:stop, :shutdown, state}
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
    
    unless src_hash == dst_hash do
      IO.puts("#{src_file} --> #{dst_file}")
      true
    else
      false
    end
  end

  defp write_file_stats(src_file, dst_path) do
    src_file_stat = File.stat!(src_file, time: :posix)
    File.write_stat(dst_path, src_file_stat, time: :posix)
  end
end
