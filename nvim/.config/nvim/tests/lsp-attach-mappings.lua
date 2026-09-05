local normal_mappings = {
  "<leader>rn",
  "<leader>ra",
  "<leader>jd",
  "<leader>ji",
  "<leader>jt",
  "<leader>jr",
  "<leader>os",
  "<leader>oh",
  "<leader>uh",
}

local visual_mappings = {
  "<leader>jd",
  "<leader>ji",
  "<leader>jt",
  "<leader>jr",
  "<leader>os",
  "<leader>oh",
}

local function mapping(buffer, mode, lhs)
  vim.api.nvim_set_current_buf(buffer)
  return vim.fn.maparg(lhs, mode, false, true)
end

local attached_buffer = vim.api.nvim_create_buf(true, true)
local plain_buffer = vim.api.nvim_create_buf(true, true)

for _, lhs in ipairs(normal_mappings) do
  assert(vim.tbl_isempty(mapping(plain_buffer, "n", lhs)), lhs .. " must not be mapped globally")
end

for _, lhs in ipairs(visual_mappings) do
  assert(vim.tbl_isempty(mapping(plain_buffer, "v", lhs)), lhs .. " must not be mapped globally")
end

vim.api.nvim_exec_autocmds("LspAttach", { buffer = attached_buffer, data = { client_id = 0 } })

for _, lhs in ipairs(normal_mappings) do
  assert(mapping(attached_buffer, "n", lhs).buffer == 1, lhs .. " must be local to the attached buffer")
  assert(vim.tbl_isempty(mapping(plain_buffer, "n", lhs)), lhs .. " must remain absent from other buffers")
end

for _, lhs in ipairs(visual_mappings) do
  assert(mapping(attached_buffer, "v", lhs).buffer == 1, lhs .. " must be local to the attached buffer")
  assert(vim.tbl_isempty(mapping(plain_buffer, "v", lhs)), lhs .. " must remain absent from other buffers")
end

vim.api.nvim_buf_delete(attached_buffer, { force = true })
vim.api.nvim_buf_delete(plain_buffer, { force = true })
