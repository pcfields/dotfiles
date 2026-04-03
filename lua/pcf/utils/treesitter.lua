local M = {}

local function get_first_char_of_node(treesitter_node)
	local CURRENT_BUFFER = 0

	local start_row, start_col, _, _ = treesitter_node:range()
	local ending_row = start_row + 1
	local is_newline_included = false

	local current_node_line = vim.api.nvim_buf_get_lines(CURRENT_BUFFER, start_row, ending_row, is_newline_included)[1]
	if not current_node_line then
		return nil
	end
	local first_char_of_line = current_node_line:sub(start_col + 1, start_col + 1)

	return first_char_of_line
end

local function get_last_char_of_node(treesitter_node)
	local CURRENT_BUFFER = 0

	local _, _, end_row, end_col = treesitter_node:range()
	local ending_row = end_row + 1
	local is_newline_included = false

	local current_node_line = vim.api.nvim_buf_get_lines(CURRENT_BUFFER, end_row, ending_row, is_newline_included)[1]
	if not current_node_line then
		return nil
	end
	local last_char_of_line = current_node_line:sub(end_col, end_col)

	return last_char_of_line
end

-- Map of opening delimiters to their pairs
local delimiter_pairs = {
	["("] = ")",
	["{"] = "}",
	["["] = "]",
	["<"] = ">",
	['"'] = '"',
	["'"] = "'",
	["`"] = "`",
}

-- Get command suffix by checking if node starts/ends with delimiter pairs
local function get_command_suffix(treesitter_node)
	local first_char = get_first_char_of_node(treesitter_node)
	local last_char = get_last_char_of_node(treesitter_node)

	if not first_char or not last_char then
		return nil
	end

	-- Check if the node starts and ends with matching delimiters
	if delimiter_pairs[first_char] == last_char then
		return first_char
	end

	return nil
end

local function get_treesitter_node_at_cursor()
	return vim.treesitter.get_node()
end

function M.execute_command_on_enclosing_node(command)
	local treesitter_node = get_treesitter_node_at_cursor()

	while treesitter_node do
		local command_suffix = get_command_suffix(treesitter_node)

		if command_suffix then
			-- Execute the command with the suffix .e.g `di{` or `yi{`
			vim.cmd("normal! " .. command .. command_suffix)
			return
		end

		treesitter_node = treesitter_node:parent()
	end
end

return M
