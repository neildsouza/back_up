defmodule BackUp.TallyProc do
  use GenServer

  @poll_time (1000 * 10)

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_pending() do
    GenServer.cast(__MODULE__, :get_pending)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast(:get_pending, state) do
    Process.send_after(__MODULE__, :pending, @poll_time)
    {:noreply, state}
  end

  def handle_info(:pending, state) do
    %{active: active} = DynamicSupervisor.count_children(
      BackUp.FilesystemSup
    )

    if active > 0 do
      IO.puts("Files & folders pending: #{active}")
      Process.send_after(__MODULE__, :pending, @poll_time)
    else
      app_state = BackUp.AppState.get_state()
      start_time = app_state.start_time
      end_time = Time.utc_now()
      diff = Time.diff(end_time, start_time)
      time_taken = BackUp.Util.convert(diff)
      msg = "ALL DONE in #{time_taken}"
      x = Enum.reduce(1..String.length(msg) + 16, "", fn(_x, acc) ->
	acc <> "="
      end)
      
      final_msg = """
        #{x}

                #{msg}

        #{x}
      """
      IO.puts("\n")
      IO.puts(final_msg)
    end
    
    {:noreply, state}
  end
end
