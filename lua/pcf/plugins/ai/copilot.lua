return {
	"github/copilot.vim",
	config = function()
		local on_outdated_work_computer = require("pcf.utils").is_windows_platform()

		if on_outdated_work_computer then
			vim.g.copilot_node_command = "C:/Users/PeterFields/AppData/Local/nvm/v24.4.0/node.exe"
		end
	end,
}
