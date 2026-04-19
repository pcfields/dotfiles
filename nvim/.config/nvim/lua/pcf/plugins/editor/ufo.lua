-- Code Folding------------------------------
-- https://github.com/kevinhwang91/nvim-ufo#table-of-contents

-- Option 3: treesitter as a main provider instead
-- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`

return { -- Improved code folding
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	config = function()
		local map = require("pcf.utils").map

		local virtual_text_handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText = {}
			local suffix = (" 󰁂 %d "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			local curWidth = 0
			for _, chunk in ipairs(virtText) do
				local chunkText = chunk[1]
				local chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if targetWidth > curWidth + chunkWidth then
					table.insert(newVirtText, chunk)
				else
					chunkText = truncate(chunkText, targetWidth - curWidth)
					local hlGroup = chunk[2]
					table.insert(newVirtText, { chunkText, hlGroup })
					chunkWidth = vim.fn.strdisplaywidth(chunkText)
					-- str width returned from truncate() may less than 2nd argument, need padding
					if curWidth + chunkWidth < targetWidth then
						suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
					end
					break
				end
				curWidth = curWidth + chunkWidth
			end
			table.insert(newVirtText, { suffix, "MoreMsg" })
			return newVirtText
		end

		require("ufo").setup({
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" }
			end,
			fold_virt_text_handler = virtual_text_handler,
		})

		map({ "n" }, "<leader>ko", require("ufo").openAllFolds, { desc = "Open all folds" })
		map({ "n" }, "<leader>kc", require("ufo").closeAllFolds, { desc = "Close all folds" })

		map({ "n" }, "<leader>k1", function()
			require("ufo").closeFoldsWith(1)
		end, { desc = "Close folds up to level 1" })

		map({ "n" }, "<leader>k2", function()
			require("ufo").closeFoldsWith(2)
		end, { desc = "Close folds up to level 2" })

		map({ "n" }, "<leader>k3", function()
			require("ufo").closeFoldsWith(3)
		end, { desc = "Close folds up to level 3" })

		map({ "n" }, "<leader>kp", function()
			local winid = require("ufo").peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek folded lines under cursor" })
	end,
}
