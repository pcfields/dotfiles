local M = {}

local minimum = { major = 0, minor = 12, patch = 0 }

local function is_older(current)
	for _, component in ipairs({ "major", "minor", "patch" }) do
		if current[component] ~= minimum[component] then
			return current[component] < minimum[component]
		end
	end

	return false
end

function M.assert_supported(current)
	current = current or vim.version()

	if not is_older(current) then
		return
	end

	error(
		string.format(
			"This configuration requires Neovim %d.%d.%d or newer (found %d.%d.%d)",
			minimum.major,
			minimum.minor,
			minimum.patch,
			current.major,
			current.minor,
			current.patch
		),
		0
	)
end

return M
