defmodule BackUp.LinkCreationProc do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add(link) do
    GenServer.cast(__MODULE__, {:add, link})
  end

  def run() do
    GenServer.call(__MODULE__, :run)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end

  def handle_call(:run, state) do
    IO.puts("Creating links")

    Enum.each(state, fn({new_path, new_link_path}) ->
      if File.exists?(new_link_path) do
	case File.rm(new_link_path) do
	  :ok ->
	    create_link(new_path, new_link_path)

	  {:error, reason} ->
	    msg = """
	      Msg: Cannot remove link #{new_link_path}
	    Error: #{inspect(reason)}
	    """
	    IO.puts(msg)
	end
      else
	create_link(new_path, new_link_path)
      end
    end)
    
    {:noreply, state}
  end

  def handle_cast({:add, link}, state) do
    state = [link] ++ state
    {:noreply, state}
  end

  defp create_link(new_path, new_link_path) do
    case File.ln_s(new_path, new_link_path) do
      :ok ->
	msg = "Created link from #{new_link_path} to #{new_path}"
	IO.puts(msg)

      {:error, reason} ->
	msg = """
 	  Msg: Cannot create link #{new_link_path}
	Error: #{inspect(reason)}
	"""
	IO.puts(msg)
    end
  end
end
