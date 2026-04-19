local icons = require("pcf.utils.icons")

vim.diagnostic.config({
	signs = {
		active = true,
		text = {
			[vim.diagnostic.severity.ERROR] = icons.diagnostics.BoldError,
			[vim.diagnostic.severity.WARN] = icons.diagnostics.BoldWarning,
			[vim.diagnostic.severity.HINT] = icons.diagnostics.BoldHint,
			[vim.diagnostic.severity.INFO] = icons.diagnostics.BoldInformation,
		},
	},
	virtual_text = false,
	float = {
		border = "rounded",
		source = true,
	},
})
