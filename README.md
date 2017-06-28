
# Registry Helper

Helps with Registry related tasks...

## Using

To use `Registry Helper` in your Mix project, first add it as a dependency:

```elixir
def deps do
  [{:reg_helper, "~> 0.1"}]
end
```

Then run `mix deps.get` to install all dependencies or more specifically:

  - `mix deps.get reg_helper`
  - `mix deps.unlock reg_helper` (if required)
  - `mix deps.update reg_helper` (if required)
  - `mix deps.compile reg_helper`

In your `config/config.exs` file, you should then name the registry:

  config :reg_helper, registry: :Registry # here name is :Registry

## Examples

  **To log the start of an Application:**

  ```elixir
  use RegHelper
  ...
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised...
    children = [
      supervisor(Registry, [:unique, reg_name()]),
      supervisor(SomeSupervisor, [])
    ]
    opts = [strategy: :rest_for_one, name: name()]
    log_start Supervisor.start_link(children, opts)
  end
  ```

  **To log the start of a Supervisor:**

  ```elixir
  use RegHelper
  ...
  def start_link do
    log_start Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  ```

  **To log the initialization of a Supervisor:**

  ```elixir
  use RegHelper
  ...
  def init(_) do
    log_init()
    children = [...]
    supervise(children, strategy: :one_for_one)
  end
  ```

  **To log the initialization of a GenServer:**

  ```elixir
  use RegHelper
  ...
  def init(_) do
    log_init()
    ...
  end
  ```
