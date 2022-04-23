defmodule Alfred.CoreTest do
  use Alfred.DataCase

  alias Alfred.Core

  describe "config_params" do
    alias Alfred.Core.ConfigParam

    import Alfred.CoreFixtures

    @invalid_attrs %{key: nil, value: nil}

    test "list_config_params/0 returns all config_params" do
      config_param = config_param_fixture()
      assert Core.list_config_params() == [config_param]
    end

    test "get_config_param!/1 returns the config_param with given id" do
      config_param = config_param_fixture()
      assert Core.get_config_param!(config_param.id) == config_param
    end

    test "create_config_param/1 with valid data creates a config_param" do
      valid_attrs = %{key: "some key", value: "some value"}

      assert {:ok, %ConfigParam{} = config_param} = Core.create_config_param(valid_attrs)
      assert config_param.key == "some key"
      assert config_param.value == "some value"
    end

    test "create_config_param/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Core.create_config_param(@invalid_attrs)
    end

    test "update_config_param/2 with valid data updates the config_param" do
      config_param = config_param_fixture()
      update_attrs = %{key: "some updated key", value: "some updated value"}

      assert {:ok, %ConfigParam{} = config_param} =
               Core.update_config_param(config_param, update_attrs)

      assert config_param.key == "some updated key"
      assert config_param.value == "some updated value"
    end

    test "update_config_param/2 with invalid data returns error changeset" do
      config_param = config_param_fixture()
      assert {:error, %Ecto.Changeset{}} = Core.update_config_param(config_param, @invalid_attrs)
      assert config_param == Core.get_config_param!(config_param.id)
    end

    test "delete_config_param/1 deletes the config_param" do
      config_param = config_param_fixture()
      assert {:ok, %ConfigParam{}} = Core.delete_config_param(config_param)
      assert_raise Ecto.NoResultsError, fn -> Core.get_config_param!(config_param.id) end
    end

    test "change_config_param/1 returns a config_param changeset" do
      config_param = config_param_fixture()
      assert %Ecto.Changeset{} = Core.change_config_param(config_param)
    end
  end
end
