-- Run from the repository root: lua tests/keys_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

-- Only the native WezTerm boundary is mocked; callbacks are event actions,
-- not Lua functions. No module, action helper, or compiler logic is replaced.
local callbacks = {}
package.preload.wezterm = function()
	return {
		action = {
			ActivateKeyTable = function(args) return { ActivateKeyTable = args } end,
		},
		action_callback = function(callback)
			local event = tostring(callback)
			callbacks[event] = callback
			return { EmitEvent = event }
		end,
	}
end

local keys = require("wezmacs.keys")

local function binding(bindings, key, mods)
	for _, candidate in ipairs(bindings) do
		if candidate.key == key and (candidate.mods or "") == (mods or "") then
			return candidate
		end
	end
	error("missing binding: " .. (mods or "") .. "+" .. key)
end

local function perform(action)
	local performed = {}
	local pane = {}
	local window = {
		perform_action = function(self, native_action, target)
			assert(target == pane, "action must retain its pane")
			if type(native_action) == "table" and native_action.EmitEvent and callbacks[native_action.EmitEvent] then
				callbacks[native_action.EmitEvent](self, target)
			else
				table.insert(performed, native_action)
			end
		end,
	}
	window:perform_action(action, pane)
	return performed
end

do
	local config = {}
	local action = { SendString = "status" }
	keys.map(config, {
		LEADER = {
			g = {
				s = { action = action, desc = "status/split" },
			},
		},
	}, "git")
	local menu = assert(config.key_tables.git_LEADER_g)
	local leaf = binding(menu, "s")
	local performed = perform(leaf.action)
	assert(#menu == 2, "named table must contain Escape and mapped leaf")
	assert(performed[1] == action, "mapped leaf must execute its action")
	assert(performed[2] == "PopKeyTable" and #performed == 2, "mapped leaf must pop once after execution")
	assert(keys.get_descriptions()["LEADER.g.s"] == "status/split", "mapped leaf must retain its description")
end
print("ok - mapped leaves inside named tables")

do
	local config = {}
	keys.map(config, {
		LEADER = {
			g = { s = { d = { x = { action = "ActivateCopyMode" } } } },
		},
	}, "deep")
	local activation = binding(config.keys, "g", "LEADER").action
	for _, key in ipairs({ "s", "d", "x" }) do
		local table_name = perform(activation)[1].ActivateKeyTable.name
		local menu = assert(config.key_tables[table_name])
		activation = binding(menu, key).action
	end
end
print("ok - nested table keys do not inherit LEADER")

do
	local config = {}
	local action = { SendString = "nested" }
	keys.map(config, {
		LEADER = {
			g = { s = { d = { x = { action = action } } } },
		},
	}, "stack")
	local activation = binding(config.keys, "g", "LEADER").action
	for _, key in ipairs({ "s", "d", "x" }) do
		local performed = perform(activation)
		assert(#performed == 1, "activating a child table must not immediately pop it")
		local options = performed[1].ActivateKeyTable
		assert(options.one_shot == false and options.until_unknown == true, "retain table activation options")
		local menu = assert(config.key_tables[options.name])
		local escaped = perform(binding(menu, "Escape").action)
		assert(#escaped == 1 and escaped[1] == "PopKeyTable", "Escape must pop exactly one table")
		activation = binding(menu, key).action
	end
	local performed = perform(activation)
	assert(#performed == 2 and performed[1] == action and performed[2] == "PopKeyTable", "deep leaf must pop once")
end
print("ok - nested activations stay active and leaves pop once")

do
	local config = {}
	keys.map(config, {
		LEADER = {
			g = { s = { { key = "x", action = "ActivateCopyMode" } } },
		},
		m = { { key = "y", action = "ActivateCopyMode" } },
	}, "lists")
	local parent = assert(config.key_tables.lists_LEADER_g)
	local nested_name = binding(parent, "s").action.ActivateKeyTable.name
	local nested = assert(config.key_tables[nested_name])
	assert(perform(binding(nested, "x").action)[1] == "ActivateCopyMode", "nested list leaf must execute")
	assert(binding(config.keys, "m").action.ActivateKeyTable.name == "lists_m", "retain plain table name")
	assert(
		perform(binding(config.key_tables.lists_m, "y").action)[1] == "ActivateCopyMode",
		"plain list leaf must execute"
	)
end
print("ok - list-only menus at root and nested depths")

do
	local config = { keys = { { key = "existing", action = "Nop" } } }
	local entries = {
		[90] = { key = "x", action = { SendString = "last" }, desc = "last" },
		[10] = { key = "x", action = { SendString = "middle" }, desc = "middle" },
		[2] = { key = "x", action = { SendString = "first" }, desc = "first" },
	}
	keys.map(config, entries, "order")
	assert(config.keys[1].key == "existing", "mapping must append to existing keys")
	for position, index in ipairs({ 2, 10, 90 }) do
		assert(
			config.keys[position + 1].action == entries[index].action,
			"numeric bindings must be emitted in ascending index order"
		)
	end
	assert(keys.get_descriptions().x == "last", "last numeric binding must own the description")
	keys.map(config, { LEADER = { o = entries } }, "order")
	local menu = assert(config.key_tables.order_LEADER_o)
	for position, index in ipairs({ 2, 10, 90 }) do
		assert(perform(menu[position + 1].action)[1] == entries[index].action, "table leaves must retain numeric order")
	end
	assert(keys.get_descriptions()["LEADER.o.x"] == "last", "table description must follow numeric precedence")
end
print("ok - numeric ordering and duplicate precedence")

do
	local config = {}
	local owner = "owner.+"
	keys.map(config, {
		{ key = "owned", mods = "CTRL", action = "Nop", desc = "plain text" },
		LEADER = {
			r = { action = "Nop", desc = "reload" },
			o = {
				{ key = "listed", action = "Nop" },
				mapped = { action = "Nop", desc = "unrelated/description" },
			},
		},
	}, owner)
	keys.map(config, { { key = "owner.+-impostor", action = "Nop", desc = "owner.+/not-owned" } }, "other")
	local descriptions = keys.get_module_descriptions(owner)
	assert(
		descriptions["CTRL+owned"] == "plain text",
		"module ownership must not be inferred from the key path or description"
	)
	assert(descriptions["LEADER.r"] == "reload", "LEADER leaves must record their owner")
	assert(descriptions["LEADER.o.listed"] == "owner.+/listed", "listed table leaves must record their owner")
	assert(descriptions["LEADER.o.mapped"] == "unrelated/description", "mapped table leaves must record their owner")
	assert(descriptions["owner.+-impostor"] == nil, "module names must not be interpreted as path patterns")
	assert(next(keys.get_module_descriptions("absent")) == nil, "unknown modules must have no descriptions")
	keys.map(config, { { key = "owned", mods = "CTRL", action = "Nop", desc = "replacement" } }, "other")
	assert(keys.get_descriptions()["CTRL+owned"] == "replacement", "latest binding retains global precedence")
	assert(keys.get_module_descriptions("other")["CTRL+owned"] == "replacement", "replacement must transfer ownership")
	assert(keys.get_module_descriptions(owner)["CTRL+owned"] == nil, "old owner must not claim another module's binding")
end
print("ok - descriptions track exact module ownership")

do
	local config = {}
	local key_map = { { key = "z", action = "Nop", desc = "listed first" }, LEADER = {} }
	for _, key in ipairs({ "z", "m", "a", "q", "b", "y", "c", "x" }) do
		key_map[key] = { action = "Nop", desc = "mapped " .. key }
		key_map.LEADER[key] = { action = "Nop" }
	end
	keys.map(config, key_map, "mixed")
	assert(config.keys[1].key == "z" and config.keys[1].mods == "", "numeric bindings precede map entries")
	for index, key in ipairs({ "a", "b", "c", "m", "q", "x", "y", "z" }) do
		assert(
			config.keys[index + 1].key == key and config.keys[index + 1].mods == "LEADER",
			"LEADER map order must be lexical"
		)
		assert(
			config.keys[index + 9].key == key and config.keys[index + 9].mods == "",
			"ordinary map order must be lexical"
		)
	end
	assert(keys.get_descriptions().z == "mapped z", "mapped leaves retain precedence over numeric leaves")
end
print("ok - deterministic map order after numeric bindings")

-- Characterization coverage for the existing built-in one-level menu shapes.
do
	for _, fixture in ipairs({
		{ module = "git", prefix = "g", leaves = { "g", "G", "j", "s", "S", "d", "D", "h", "H" } },
		{ module = "app", prefix = ",", leaves = { "d", "D", "k", "K", "s", "S", "m", "M" } },
		{ module = "agent", prefix = "a", leaves = { "a", "A", "c", "C", "Enter", "Space", "x" } },
	}) do
		local entries = {}
		for _, key in ipairs(fixture.leaves) do
			table.insert(entries, { key = key, action = { SendString = key }, desc = "command/" .. key })
		end
		local config = {}
		keys.map(config, { LEADER = { [fixture.prefix] = entries } }, fixture.module)
		local table_name = fixture.module .. "_LEADER_" .. fixture.prefix
		local activation = binding(config.keys, fixture.prefix, "LEADER").action.ActivateKeyTable
		assert(#config.keys == 1 and activation.name == table_name, "retain one-level table name and activation")
		assert(activation.one_shot == false and activation.until_unknown == true, "retain one-level table options")
		local menu = assert(config.key_tables[table_name])
		assert(#menu == #entries + 1 and menu[1].key == "Escape" and menu[1].mods == nil, "retain Escape-first menu shape")
		for index, entry in ipairs(entries) do
			assert(
				menu[index + 1].key == entry.key and menu[index + 1].mods == "",
				"retain built-in leaf order and modifiers"
			)
			local performed = perform(menu[index + 1].action)
			assert(
				performed[1] == entry.action and performed[2] == "PopKeyTable" and #performed == 2,
				"retain one-level leaf execution"
			)
			assert(
				keys.get_descriptions()["LEADER." .. fixture.prefix .. "." .. entry.key] == entry.desc,
				"retain description paths"
			)
		end
	end
end
print("ok - built-in one-level menu compatibility")

do
	local config = {}
	local sent = { SendString = "callback" }
	local callback = function(window, pane) window:perform_action(sent, pane) end
	local event = require("wezterm").action_callback(callback)
	local named_action = { name = "native", args = {} }
	keys.map(config, {
		{ key = "f", mods = "CTRL", action = callback },
		{ key = "n", action = named_action },
		LEADER = {
			r = { action = { action = sent } },
			c = {
				{ key = "f", action = callback },
				{ key = "e", action = event },
				{ key = "p", action = "PopKeyTable" },
				{ key = "s", mods = "SHIFT", action = "ActivateCopyMode" },
			},
		},
	})
	local direct = perform(binding(config.keys, "f", "CTRL").action)
	assert(#direct == 1 and direct[1] == sent, "root callbacks must execute without popping")
	assert(binding(config.keys, "n").action == named_action, "native name/args action tables pass through")
	local leader = perform(binding(config.keys, "r", "LEADER").action)
	assert(#leader == 1 and leader[1] == sent, "direct LEADER action specs resolve without popping")
	local menu = config.key_tables.unknown_LEADER_c
	for _, key in ipairs({ "f", "e" }) do
		local performed = perform(binding(menu, key).action)
		assert(
			#performed == 2 and performed[1] == sent and performed[2] == "PopKeyTable",
			"callbacks must execute before popping once"
		)
	end
	local popped = perform(binding(menu, "p").action)
	assert(#popped == 1 and popped[1] == "PopKeyTable", "explicit PopKeyTable must not pop twice")
	local copied = perform(binding(menu, "s", "SHIFT").action)
	assert(
		#copied == 2 and copied[1] == "ActivateCopyMode" and copied[2] == "PopKeyTable",
		"string actions retain execution order"
	)
	assert(keys.get_descriptions()["CTRL+f"] == "unknown/f", "retain root default description")
	assert(keys.get_descriptions()["LEADER.r"] == "unknown/LEADER.r", "retain direct LEADER default description")
	assert(keys.get_descriptions()["SHIFT+LEADER.c.s"] == "unknown/s", "retain modified table description path")
	local untouched = {}
	---@diagnostic disable-next-line: param-type-mismatch
	keys.map(untouched, false, "invalid")
	---@diagnostic disable-next-line: param-type-mismatch
	keys.map(untouched, nil, "invalid")
	assert(next(untouched) == nil, "invalid key maps leave config untouched")
end
print("ok - callbacks, action specs, modifiers and defaults")

do
	local config = {}
	keys.map(config, {
		LEADER = {
			m = {
				x = { mods = "SHIFT", action = "Nop", desc = "shifted" },
			},
		},
	}, "modified")
	assert(binding(config.key_tables.modified_LEADER_m, "x", "SHIFT"), "mapped leaves retain explicit modifiers")
	assert(
		keys.get_descriptions()["SHIFT+LEADER.m.x"] == "shifted",
		"mapped description paths must include explicit modifiers"
	)
	assert(
		keys.get_module_descriptions("modified")["SHIFT+LEADER.m.x"] == "shifted",
		"modified descriptions retain ownership"
	)
end
print("ok - modified mapped description paths")

print("keys_test.lua: all assertions passed")
