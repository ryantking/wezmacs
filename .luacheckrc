-- WezMacs Luacheck Configuration
-- Static analysis for Lua code quality

std = "luajit"
max_line_length = 100

-- Globals provided by WezTerm
globals = {
  "wezterm",
}

-- Ignore patterns
exclude_files = {
  ".git",
  "*.swp",
  "*.swo",
  "*~",
}

-- Per-file configuration
files["wezmacs"] = {
  globals = { "wezterm" },
}

files["user"] = {
  globals = { "wezterm" },
}

files["examples"] = {
  globals = { "wezterm" },
}
