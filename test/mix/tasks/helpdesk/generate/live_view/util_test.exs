defmodule Mix.Tasks.Helpdesk.Generate.LiveView.UtilTest do
  use ExUnit.Case
  alias Mix.Tasks.Helpdesk.Generate.LiveView.Util

  test "get_plural_module_name" do
    assert Util.get_plural_module_name(Util) == "utils"
  end
end
