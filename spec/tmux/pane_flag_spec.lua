---@diagnostic disable: duplicate-set-field
describe("pane_flag", function()
    local pane_flag
    local options
    local tmux
    local autocmds
    local pane_options

    setup(function()
        require("spec.tmux.mocks.log_mock").setup()
        require("spec.tmux.mocks.tmux_mock").setup("3.2a")

        _G.vim = {
            api = {
                nvim_create_augroup = function() end,
                nvim_create_autocmd = function(events, opts)
                    for _, event in ipairs(type(events) == "table" and events or { events }) do
                        autocmds[event] = opts.callback
                    end
                end,
            },
        }

        options = require("tmux.configuration.options")
        tmux = require("tmux.wrapper.tmux")
        tmux.get_pane_option = function(name)
            return pane_options[name] or ""
        end
        tmux.set_pane_option = function(name, value)
            pane_options[name] = (value ~= "" and value) or nil
        end
    end)

    before_each(function()
        package.loaded["tmux.pane_flag"] = nil
        pane_flag = require("tmux.pane_flag")
        autocmds = {}
        pane_options = {}
        options.pane_flag.enable = true
    end)

    it("does nothing when disabled", function()
        options.pane_flag.enable = false
        pane_flag.setup()
        assert.is_nil(pane_options["@is_vim"])
        assert.are.same({}, autocmds)
    end)

    it("sets the flag on setup and clears it on exit", function()
        pane_flag.setup()
        assert.are.same("1", pane_options["@is_vim"])
        autocmds.VimLeavePre()
        assert.is_nil(pane_options["@is_vim"])
    end)

    it("restores a parent nvim's flag on exit", function()
        pane_options["@is_vim"] = "1"
        pane_flag.setup()
        autocmds.VimLeavePre()
        assert.are.same("1", pane_options["@is_vim"])
    end)

    it("clears on suspend and sets again on resume", function()
        pane_flag.setup()
        autocmds.VimSuspend()
        assert.is_nil(pane_options["@is_vim"])
        autocmds.VimResume()
        assert.are.same("1", pane_options["@is_vim"])
        autocmds.VimLeavePre()
        assert.is_nil(pane_options["@is_vim"])
    end)

    it("ignores repeated setup", function()
        pane_flag.setup()
        pane_flag.setup()
        autocmds.VimLeavePre()
        assert.is_nil(pane_options["@is_vim"])
    end)
end)
