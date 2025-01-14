--- Repository updating.
-- @module bliss.update
local utils = require "bliss.utils"
local unistd = require "posix.unistd"

--- The update action.
local function update(env, arg)
	-- arg is ignored.

	utils.log("Updating repositories")
	local repos = {}

	for _,repo in ipairs(env.PATH) do
		local subm = utils.capture("git -C '" .. repo .. "' rev-parse --show-superproject-working-tree 2>/dev/null")
		if not subm then goto continue end -- not a git repo
		local repo = utils.capture("git -C '" .. (subm[1] or repo) .. "' rev-parse --show-toplevel")
		if not repo then goto continue end
		local repo = repo[1]
		if not repos[repo] then
			utils.log(repo)
			unistd.chdir(repo)
			-- as_user?
			utils.run_quiet("git", {"pull"})
			repos[repo] = true
		end

		::continue::
	end

end

--- @export
local M = {
	update = update,
}
return M
