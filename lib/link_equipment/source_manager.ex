defmodule LinkEquipment.SourceManager do
  @moduledoc false

  alias Util.Result

  @cache_name :source_cache

  @spec check_source(URI.t()) :: Result.t(String.t())
  def check_source(url) do
    case Cachex.fetch(@cache_name, url, fn url -> get_source(url) end) do
      {:ignore, {:error, error}} ->
        {:error, error}

      {:ignore, body} ->
        {:ok, body}

      {:ok, body} ->
        {:ok, body}

      {:commit, body} ->
        {:ok, body}
    end
  end

  defp get_source(url) do
    case Req.get(url) do
      {:ok, response} ->
        if response.status == 200 do
          {:commit, response.body, expire: :timer.minutes(5)}
        else
          {:ignore, response.body}
        end

      error ->
        {:ignore, error}
    end
  end
end
