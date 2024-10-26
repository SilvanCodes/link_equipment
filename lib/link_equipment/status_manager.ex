defmodule LinkEquipment.StatusManager do
  @moduledoc false

  @cache_name :status_cache
  def check_status(url) do
    case Cachex.fetch(@cache_name, url, fn url -> get_status(url) end) do
      {:ignore, {:error, error}} ->
        {:error, error}

      {:ignore, status} ->
        {:ok, status}

      {:ok, status} ->
        {:ok, status}

      {:commit, status} ->
        {:ok, status}
    end
  end

  @doc """
  We only cache status 200 codes as they should be the majority and are anticipated to be least likely to change.
  """
  defp get_status(url) do
    IO.puts("HIT NETWORK")

    case Req.head(url) do
      {:ok, %{status: status}} ->
        if status in 200..299 do
          {:commit, status, expire: :timer.minutes(3)}
        else
          {:ignore, status}
        end

      error ->
        {:ignore, error}
    end
  end
end
