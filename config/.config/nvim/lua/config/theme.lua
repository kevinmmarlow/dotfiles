local default_theme = "kanagawa-wave"

local function read_theme_name()
  local file = io.open(vim.fn.expand("~/.config/themes/current"), "r")
  if not file then
    return default_theme
  end

  local name
  for line in file:lines() do
    name = line:match("^nvim=(.+)$") or name
  end
  file:close()

  return name or default_theme
end

-- pcall covers first-run before lazy.nvim finishes installing the colorscheme plugins.
local ok, err = pcall(vim.cmd.colorscheme, read_theme_name())
if not ok then
  vim.notify("colorscheme failed to load: " .. err, vim.log.levels.WARN)
end
