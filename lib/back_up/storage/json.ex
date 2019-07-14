defmodule BackUp.Storage.Json do
  def read(json_file) do
    with {:ok, json_str} <- File.read(json_file),
         {:ok, json} <- Jason.decode(json_str) do
      json
    end
  end

  def write(path, json) do
    with {:ok, json_str} <- Jason.encode(json) do
      File.write(path, json_str)
    end
  end
end
