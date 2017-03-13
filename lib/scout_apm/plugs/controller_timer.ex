defmodule ScoutApm.Plugs.ControllerTimer do
  require Logger

  def init(default), do: default

  def call(conn, _default) do
    t1 = System.monotonic_time()

    conn
    |> Plug.Conn.register_before_send(
                                      fn conn ->
                                        t2 = System.monotonic_time()
                                        tdiff = t2 - t1
                                        Logger.info("Scout Timer: #{tdiff}")

                                        payload = ScoutApm.Payload.new
                                        ScoutApm.Payload.post(payload)

                                        case Process.whereis(ScoutApm.Worker) do
                                          nil -> Logger.info("Couldn't find worker?")
                                          pid ->
                                            Logger.info("Found worker!")
                                            GenServer.cast(pid, {:time, tdiff})
                                        end

                                        print_payload(payload)

                                        conn
                                      end)
  end

  def print_payload(payload) do
    Logger.info Poison.encode!( payload )
  end

end
