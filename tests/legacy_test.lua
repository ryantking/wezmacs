-- Legacy integrations must not be restored by the framework or its fixtures.
local function absent(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		error("legacy path still exists: " .. path)
	end
end
absent("wezmacs/modules/agent/init.lua")
absent("wezmacs/modules/agent/actions.lua")
absent(".mcp.json")
absent(".claude/agents/engineer.md")
local modules = assert(loadfile("test/modules.lua"))()
for _, entry in ipairs(modules) do
	assert((type(entry) == "table" and entry[1] or entry) ~= "agent", "legacy module enabled in fixture")
end
print("PASS legacy integrations removed")
