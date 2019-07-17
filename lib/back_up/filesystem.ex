defmodule BackUp.Filesystem do
  @back_up_file ".back_up_config.json"
  
  def crawl_folder(folder) do
    get_folder_contents(folder)
    |> create_paths()
    |> separate_into_files_and_folders()
  end

  defp create_paths(contents) do
    case contents do
      {:ok, folder, contents} ->
	Enum.map(contents, fn(content) ->
	  Path.join(folder, content)
	end)
    end
  end

  defp get_folder_contents(folder) do
    case File.ls(folder) do
      {:ok, contents} -> {:ok, folder, contents -- [@back_up_file]}
      {:error, e} -> IO.inspect(e)
    end
  end

  defp separate_into_files_and_folders(folder_contents) do
    Enum.reduce(
      folder_contents,
      %{files: [], folders: []},
      fn(content, acc) ->
	case File.lstat(content) do
	  {:ok, %File.Stat{type: :directory}} ->
	    put_in(acc.folders, acc.folders ++ [content])
	  {:ok, %File.Stat{type: :regular}} ->
	    put_in(acc.files, acc.files ++ [content])
	  _ -> acc
	end
      end
    )
  end
  
  def hash_content(content) do
    File.stream!(content,[],2048) 
    |> Enum.reduce(:crypto.hash_init(:sha256), fn(line, acc) ->
         :crypto.hash_update(acc,line)
       end)
    |> :crypto.hash_final 
    |> Base.encode16
  end
end
