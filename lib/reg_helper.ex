
defmodule RegHelper do
  @moduledoc """
  Helps with Registry related tasks...
  """

  import Logger, only: [debug: 1, error: 1, info: 1, warn: 1]

  @mod __MODULE__

  defmacro __using__(_options) do
    quote do
      import unquote @mod

      # Returns the PID of a locally registered process (singleton).
      @spec whereis :: pid | nil
      def whereis do
        case Process.whereis(name()) do
          pid when is_pid(pid) -> pid
          nil -> nil
        end
      end

      # Returns the PID of a process registered using a via tuple.
      @spec whereis(any) :: pid | nil
      def whereis(id) do
        case Registry.lookup(reg_name(), key(id)) do
          [{pid, nil}] -> pid
          [] -> nil
        end
      end
    end
  end

  defmacro name do
    quote do
      __MODULE__
      |> to_string
      |> String.split(".")
      |> List.last
      |> String.to_atom
    end
  end

  defmacro reg_name do
    quote do
      Application.get_env :reg_helper, :registry, :R_E_G_I_S_T_R_Y
    end
  end

  defmacro key(id) do
    quote do: {name(), unquote id}
  end

  defmacro via(id) do
    quote do: {:via, Registry, {reg_name(), key(unquote id)}}
  end

  # Restores the state of a process.
  defmacro restore(id) do
    quote do: Registry.meta reg_name(), key(unquote id)
  end

  # Saves the state of a process.
  defmacro save(id, state) do
    quote do: Registry.put_meta reg_name(), key(unquote id), unquote state
  end

  @doc """
  Logs the start of a process (typically GenServer or Supervisor).

  ## Examples

      use RegHelper
      ...
      def start_link do
        log_start Supervisor.start_link(__MODULE__, :ok, name: name())
      end

      use RegHelper
      ...
      def start_link(id) do
        log_start GenServer.start_link(__MODULE__, id, name: via(id))
      end
  """
  @spec log_start(GenServer.on_start) :: GenServer.on_start
  def log_start(on_start) do
    case on_start do
      {:ok, pid} -> debug reveal(pid, "started ok")
      :ignore -> error "failed to start: :ignore"
      {:error, {:already_started, pid}} -> warn reveal(pid, "already started")
      {:error, reason} -> error "failed to start: #{inspect reason}"
    end
    on_start
  end

  @spec reveal(pid, String.t) :: String.t
  defp reveal(pid, tail) do
    String.trim_trailing "#{tag pid} #{inspect pid} #{tail}"
  end

  # Given a PID, returns the registered name or via tuple (string).
  @spec tag(pid) :: atom | String.t
  defp tag(pid) do
    case Process.info(pid)[:registered_name] do
      nil -> Registry.keys(reg_name(), pid) |> List.first |> inspect
      name -> name
    end
  end

  @doc """
  Logs the initialization of a process (typically GenServer or Supervisor).

  ## Examples

      use RegHelper
      ...
      def init(_) do
        log_init()
        children = [...]
        supervise children, strategy: :one_for_one
      end

      use RegHelper
      ...
      def init(state) do
        log_init()
        {:ok, state}
      end
  """
  @spec log_init(String.t) :: :ok | {:error, term}
  def log_init(tail \\ ""), do: warn reveal(self(), "starting #{tail}")

  @spec log_debug(pid, String.t) :: :ok | {:error, term}
  def log_debug(pid \\ self(), tail), do: debug reveal(pid, tail)

  @spec log_info(pid, String.t) :: :ok | {:error, term}
  def log_info(pid \\ self(), tail), do: info reveal(pid, tail)

  @spec log_warn(pid, String.t) :: :ok | {:error, term}
  def log_warn(pid \\ self(), tail), do: warn reveal(pid, tail)

  @spec log_error(pid, String.t) :: :ok | {:error, term}
  def log_error(pid \\ self(), tail), do: error reveal(pid, tail)
end
