local M = {}

local T = "com.superlogical.terminal"
local ROOT = debug.getinfo(1, "S").source:gsub("^@", ""):match("(.*)/") or "."

local defaults = {
  key = "cmd+shift+e",
  sidebar_ratio = 0.2,
  viewer_ratio = 70,
}

local function cwd(ctx)
  local r = rex.block.call(T, "pwd", { block_id = ctx.block_id })
  if r and r.pwd and r.pwd ~= "" then
    return r.pwd
  end
  local p = rex.block.call(T, "process", { block_id = ctx.block_id })
  if p then
    if p.foreground and p.foreground.cwd then
      return p.foreground.cwd
    end
    for _, a in ipairs(p.ancestors or {}) do
      if a.cwd then
        return a.cwd
      end
    end
  end
  return os.getenv("HOME")
end

function M.setup(opts)
  opts = opts or {}
  for k, v in pairs(defaults) do
    if opts[k] == nil then
      opts[k] = v
    end
  end

  rex.action{
    name = "sidecar_open",
    title = "Sidecar: File Explorer",
    category = "Sidecar",
    keywords = "file explorer tree yazi sidebar viewer",
    run = function(ctx)
      return rex.session.new_split{
        anchor_block_id = ctx.block_id,
        direction = "horizontal",
        side = "before",
        ratio = opts.sidebar_ratio,
        focus = true,
        layout = rex.layout.block{
          flavor = T .. ".shell",
          options = {
            cwd = cwd(ctx),
            command = {
              "env",
              "YAZI_CONFIG_HOME=" .. ROOT .. "/yazi",
              "REX_SIDECAR_BIN=" .. ROOT .. "/bin/rex-sidecar-open",
              "REX_SIDECAR_MAIN_BLOCK=" .. (ctx.block_id or ""),
              "REX_SIDECAR_VIEWER_RATIO=" .. tostring(opts.viewer_ratio),
              "yazi",
            },
          },
        },
      }
    end,
  }

  if opts.key then
    rex.bind(opts.key, "sidecar_open")
  end
end

return M
