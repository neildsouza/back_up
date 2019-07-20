defmodule BackUp.TallyProc do
  use GenServer, restart: :temporary

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
    Process.send_after(__MODULE__, :pending, 10000)
    {:noreply, state}
  end

  def handle_info(:pending, state) do
    %{active: active} = DynamicSupervisor.count_children(
      BackUp.FilesystemSup
    )

    if active > 0 do
      IO.puts("Files & folders pending: #{active}")
      Process.send_after(__MODULE__, :pending, 10000)
      {:noreply, state}
    else
      IO.puts("All done")
      {:stop, :shutdown, state}
    end
  end
end
