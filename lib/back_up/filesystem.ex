defmodule BackUp.Filesystem do
  def crawl_folder(folder) do
    case get_folder_contents(folder) do
      {:ok, folder, contents} ->
        files_folders_links =
          create_paths(folder, contents)
          |> separate_into_files_folders_links()

        {:ok, files_folders_links}

      {:error, e} ->
        {:error, e}
    end
  end

  def hash_content(content) do
    if File.exists?(content) do
      File.stream!(content, [], 2048)
      |> Enum.reduce(:crypto.hash_init(:sha256), fn line, acc ->
        :crypto.hash_update(acc, line)
      end)
      |> :crypto.hash_final()
      |> Base.encode16()
    end
  end

  defp create_paths(folder, contents) do
    Enum.map(contents, fn content ->
      Path.join(folder, content)
    end)
  end

  defp get_folder_contents(folder) do
    case File.ls(folder) do
      {:ok, contents} -> {:ok, folder, contents}
      {:error, e} -> IO.inspect(e)
    end
  end

  defp separate_into_files_folders_links(folder_contents) do
    Enum.reduce(
      folder_contents,
      %{files: [], folders: [], links: []},
      fn content, acc ->
        case File.lstat(content) do
          {:ok, %File.Stat{type: :directory}} ->
            put_in(acc.folders, acc.folders ++ [content])

          {:ok, %File.Stat{type: :regular}} ->
            put_in(acc.files, acc.files ++ [content])

          {:ok, %File.Stat{type: :symlink}} ->
            put_in(acc.links, acc.links ++ [content])

          _ ->
            acc
        end
      end
    )
  end
end
