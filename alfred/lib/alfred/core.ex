defmodule Alfred.Core do
  @moduledoc """
  The Core context.
  """

  import Ecto.Query, warn: false
  alias Alfred.Repo

  alias Alfred.Core.ConfigParam

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
  end

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
