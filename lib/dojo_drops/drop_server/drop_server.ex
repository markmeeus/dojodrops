defmodule DropServer do
  use GenServer

  def get_async(drop_id, resource) do
    #fetch resource here
    fn ->  resource  end
  end

end