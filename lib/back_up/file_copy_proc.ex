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
      dst_hash = Filesystem.hash_content(dst_path)

      unless state.src_file_hash == dst_hash do
	cp_file(state.src_file, dst_path)
      end
    else
      cp_file(state.src_file, dst_path)
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
