-- A test file's list of cases, in the order they are declared:
--   local cases, test = require("tests.cases")()
--   test("name", function(t, loaded) ... end)
--   return cases
return function()
	local cases = {}

	local function test(name, body)
		table.insert(cases, { name = name, body = body })
	end

	return cases, test
end
