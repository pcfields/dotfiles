local M = {}

-- Function to play a macro from a specified register
function M.play_macro()
	-- Prompt the user for a register
	local register_letter = vim.fn.input("Play macro from register: @")

	if register_letter ~= "" then
		vim.cmd("normal! @" .. register_letter) -- Play the macro in the specified register
	else
		print("No register specified")
	end
end

-- Function to play a macro from a specified register
function M.record_macro()
	-- Prompt the user for a register
	local register_letter = vim.fn.input("Record macro in register: @")

	if register_letter ~= "" then
		vim.cmd("normal! q" .. register_letter) -- Play the macro in the specified register
	else
		print("No register specified")
	end
end

function M.macro_recording_text()
	local reg = vim.fn.reg_recording()

	if reg == "" then
		return ""
	end

	return "Recording @" .. reg
end

return M
