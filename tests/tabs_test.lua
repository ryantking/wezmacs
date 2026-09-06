package.path = "./?.lua;./?/init.lua;" .. package.path
package.loaded.wezterm = {
	home_dir = "/home/test",
	nerdfonts = setmetatable({}, {
		__index = function(_, key)
			if key:match("^mdi_") then
				return nil
			end
			return key
		end,
	}),
}
local hooks = require("wezmacs.modules.tabs.hooks")
local tab = { active_pane = { title = "curl - download", current_working_dir = { file_path = "/home/test" } } }
local output = hooks.format_tab_title(tab)
assert(output[1].Text:find("cod_globe", 1, true), "curl must use an available native icon")
tab.active_pane.title = "wget - download"
assert(hooks.format_tab_title(tab)[1].Text:find("md_arrow_down_box", 1, true), "wget icon is missing")
print("PASS tab icons use current native identifiers")
