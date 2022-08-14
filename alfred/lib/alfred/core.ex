defmodule Alfred.Core do
  @moduledoc """
  The Core context.
  """

  import Ecto.Query, warn: false
  alias Alfred.Repo

  alias Alfred.Core.ConfigParam
  alias Phoenix.PubSub

  @flags_topic "flags"

  def flags_topic, do: @flags_topic

  @doc """
  Returns the list of config_params.

  ## Examples

      iex> list_config_params()
      [%ConfigParam{}, ...]

  """
  def list_config_params do
    Repo.all(ConfigParam)
  end

  @doc """
  Gets a single config_param.

  Raises `Ecto.NoResultsError` if the Config param does not exist.

  ## Examples

      iex> get_config_param!(123)
      %ConfigParam{}

      iex> get_config_param!(456)
      ** (Ecto.NoResultsError)

  """
  def get_config_param!(id), do: Repo.get!(ConfigParam, id)

  def get_config_param(key) do
    ConfigParam
    |> where(key: ^key)
    |> Repo.one()
  end

  @doc """
  Creates a config_param.

  ## Examples

      iex> create_config_param(%{field: value})
      {:ok, %ConfigParam{}}

      iex> create_config_param(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_config_param(attrs \\ %{}) do
    %ConfigParam{}
    |> ConfigParam.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a config_param.

  ## Examples

      iex> update_config_param(config_param, %{field: new_value})
      {:ok, %ConfigParam{}}

      iex> update_config_param(config_param, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_config_param(%ConfigParam{} = config_param, attrs) do
    config_param
    |> ConfigParam.changeset(attrs)
    |> Repo.update()
    |> update_pubsub()
  end

  def toggle_flag(flag, value) when is_boolean(value) do
    key = "flags.#{flag}"

    case get_config_param(key) do
      nil ->
        {:error, :not_found}

      config_param ->
        update_config_param(config_param, %{"value" => to_string(value)})
    end
  end

  defp update_pubsub({:ok, %{key: key, value: value} = updated}) do
    if String.starts_with?(key, "flags.") do
      PubSub.broadcast(Alfred.PubSub, @flags_topic, {:flag_updated, key, value})
    end

    # updates that are not flags will be ignored

    {:ok, updated}
  end

  defp update_pubsub({:error, error}), do: {:error, error}

  @doc """
  Deletes a config_param.

  ## Examples

      iex> delete_config_param(config_param)
      {:ok, %ConfigParam{}}

      iex> delete_config_param(config_param)
      {:error, %Ecto.Changeset{}}

  """
  def delete_config_param(%ConfigParam{} = config_param) do
    Repo.delete(config_param)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking config_param changes.

  ## Examples

      iex> change_config_param(config_param)
      %Ecto.Changeset{data: %ConfigParam{}}

  """
  def change_config_param(%ConfigParam{} = config_param, attrs \\ %{}) do
    ConfigParam.changeset(config_param, attrs)
  end
end
