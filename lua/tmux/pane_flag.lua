local options = require("tmux.configuration.options")
local tmux = require("tmux.wrapper.tmux")

local M = {}

-- value of the option before this nvim set it, restored on exit so a nested
-- nvim (e.g. in a :terminal of another) does not clear its parent's flag
local previous
local active = false

local function set()
    if active then
        return
    end
    active = true
    previous = tmux.get_pane_option(options.pane_flag.name)
    tmux.set_pane_option(options.pane_flag.name, "1")
end

local function restore()
    if not active then
        return
    end
    active = false
    tmux.set_pane_option(options.pane_flag.name, previous)
end

function M.setup()
    if not tmux.is_tmux or not options.pane_flag.enable then
        return
    end

    set()

    local group = vim.api.nvim_create_augroup("tmux_pane_flag", {})
    vim.api.nvim_create_autocmd("VimResume", { group = group, callback = set })
    vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { group = group, callback = restore })
end

return M
