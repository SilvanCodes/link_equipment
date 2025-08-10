defmodule LinkEquipment.ScanManager do
  @moduledoc false

  alias LinkEquipment.Link
  alias Util.Result

  @cache_name :scan_cache

  @spec check_scan(URI.t()) :: Result.t([Link.t()])
  def check_scan(url) do
    case Cachex.fetch(@cache_name, url, fn url -> get_scan(url) end) do
      {:ignore, {:error, error}} ->
        {:error, error}

      {:ignore, results} ->
        {:ok, results}

      {:ok, results} ->
        {:ok, results}

      {:commit, results} ->
        {:ok, results}
    end
  end

  defp get_scan(url) do
    IO.puts("HIT NETWORK")

    case LinkEquipment.Lychee.collect_links(url) do
      {:ok, results} ->
        # We could group here if it turns out to be interesting when a resource is linked multiple times in different places.
        {:commit, results |> Enum.sort() |> Enum.uniq_by(& &1.url)}

      error ->
        {:ignore, error}
    end
  end
end
