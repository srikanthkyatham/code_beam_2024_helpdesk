defmodule Mix.Tasks.Helpdesk.Generate.UtilTest do
  use ExUnit.Case
  alias Mix.Tasks.Helpdesk.Generate.Util
  import Igniter.Test

  # :skip

  # test "app_name" do
  #   igniter = test_project(app_name: :helpdesk)
  #   assert Util.app_name(igniter) == "Elixir.Helpdesk"
  # end

  test "web_module as string" do
  end

  test "table_componet_name" do
  end

  test "get_module_base_name" do
    module = Mix.Tasks.Helpdesk.Generate.Util
    assert Util.get_module_base_name(module) == "Util"
  end

  test "split_module_name" do
    assert Util.split_module_name(Mix.Tasks.Helpdesk.Generate.Util) == [
             "Util"
           ]
  end

  test "module_name_to_string_with_underscores" do
    assert Util.module_name_to_string_with_underscores(Mix.Tasks.Helpdesk.Generate.UtilTest) ==
             "util_test"
  end
end
