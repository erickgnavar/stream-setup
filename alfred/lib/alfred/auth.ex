defmodule Alfred.Auth do
  alias Alfred.Core

  @spec change_admin_password(String.t()) :: {:ok, Core.ConfigParam.t()}
  def change_admin_password(raw_password) when is_binary(raw_password) do
    hashed_password = Bcrypt.hash_pwd_salt(raw_password)
    Core.update_config_param("secret.admin.password", hashed_password)
  end
end
