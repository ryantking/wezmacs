package.path = "./?.lua;./?/init.lua;" .. package.path
package.loaded.wezterm = { action = { SpawnCommandInNewTab = function(spec) return spec end } }
package.loaded.wezmacs = { config = { shell = "/bin/sh" } }
local action = require("wezmacs.action")
local spec = action.NewTab("false || printf wezmacs-fallback-ok")
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local command = {}
for _, value in ipairs(spec.args) do
	table.insert(command, quote(value))
end
local pipe = assert(io.popen(table.concat(command, " ")))
local output = pipe:read("*a")
pipe:close()
assert(output == "wezmacs-fallback-ok", "shell fallback must run after a failed first command; got: " .. output)
print("PASS action shell command preserves fallback and exits")
