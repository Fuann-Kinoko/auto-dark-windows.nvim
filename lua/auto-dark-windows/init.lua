local timer_id
---@type boolean
local is_currently_dark_mode

---@type fun()
local set_dark_mode, set_light_mode

---Every `update_interval` milliseconds a theme check will be performed.
---@type number
local update_interval

---@param callback fun(is_dark_mode: boolean)
local function check_is_dark_mode(callback)
		local handle = io.popen("reg query HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize /v SystemUsesLightTheme")
		local result = handle:read("*a")
		handle:close()
		local is_dark_mode = tonumber(string.sub(result, -3)) == 0
    callback(is_dark_mode)
end

---@param is_dark_mode boolean
local function change_theme_if_needed(is_dark_mode)
	-- local is_currently_dark_mode = (vim.api.nvim_get_option('background') == 'dark')
	if is_dark_mode == is_currently_dark_mode then
		return
	end

	is_currently_dark_mode = is_dark_mode
	if is_currently_dark_mode then
		set_dark_mode()
	else
		set_light_mode()
	end
end

local function start_check_timer()
	timer_id = vim.fn.timer_start(update_interval, function()
		check_is_dark_mode(change_theme_if_needed)
	end, { ["repeat"] = -1 })
end

local function init()
	if not set_dark_mode or not set_light_mode then
		error([[

        Call `setup` first:

        require('auto-dark-windows').setup({
            set_dark_mode=function()
                vim.api.nvim_set_option('background', 'dark')
                vim.cmd('colorscheme gruvbox')
            end,
            set_light_mode=function()
                vim.api.nvim_set_option('background', 'light')
            end,
        })
        ]])
	end

	-- a callback
	check_is_dark_mode(change_theme_if_needed)
	start_check_timer()
end

local function disable()
	vim.fn.timer_stop(timer_id)
end

---@param options table<string, fun()>
---`options` contains two function - `set_dark_mode` and `set_light_mode`
local function setup(options)
	options = options or {}

	---@param background string
	local function set_background(background)
		vim.api.nvim_set_option("background", background)
	end

	set_dark_mode = options.set_dark_mode or function()
		set_background("dark")
	end
	set_light_mode = options.set_light_mode or function()
		set_background("light")
	end
	update_interval = options.update_interval or 3000
end

return { setup = setup, init = init, disable = disable}
