defmodule LinkEquipment.StatusManager do
  @moduledoc false

  @cache_name :status_cache
  def check_status(url) do
    case warm_cache(url) do
      {:commit, status} ->
        {:ok, status}

      {:ok, status} ->
        {:ok, status}

      {:ignore, error} ->
        {:error, error}
    end
  end

  defp warm_cache(url) do
    Cachex.fetch(@cache_name, url, fn ->
      case Req.head(url) do
        {:ok, response} -> {:commit, response.status, expire: :timer.seconds(60)}
        {:error, error} -> {:ignore, error}
      end
    end)
  end
end
