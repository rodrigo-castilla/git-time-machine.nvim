-- =========== PLUGINS ============
local M = {}

-- Default config
M.config = {
	shortcut = "<leader>gt",
	bg_color = "#064040",
}

-- Main function for time-machine
function M.open()
	local current_file = vim.fn.expand("%:.")

	if not pcall(require, "snacks") then
		vim.notify("time-machine.nvim requires 'snacks.nvim'", vim.log.levels.ERROR)
		return
	end

	Snacks.picker.git_log({
		title = "Time Machine: Select Commit",
		confirm = function(picker, item)
			picker:close()

			local commit_hash = item.commit
			if not commit_hash then
				vim.notify("Could not retrieve commit hash", vim.log.levels.ERROR)
				return
			end

			local function view_full_past_file_with_diff(filepath)
				vim.cmd("rightbelow vsplit")
				vim.cmd("enew")
				local buf = vim.api.nvim_get_current_buf()
				local win = vim.api.nvim_get_current_win()

				local clean_filename = filepath:match("^.+/(.+)$") or filepath
				local temp_name = string.format("[Past %s] %s", commit_hash:sub(1, 7), clean_filename)
				vim.api.nvim_buf_set_name(buf, temp_name)

				-- Fetch full file diff with massive context
				local diff_cmd = string.format("git diff -U1000 %s~1..%s -- %s", commit_hash, commit_hash, filepath)
				local handle = io.popen(diff_cmd)

				local lines = {}
				if handle then
					local diff_result = handle:read("*a")
					handle:close()

					if diff_result == "" then
						vim.cmd("silent r !git show " .. commit_hash .. ":" .. filepath)
					else
						-- Parse diff content removing git metadata header
						for line in diff_result:gmatch("[^\r\n]+") do
							local prefix = line:sub(1, 2)
							if
								prefix ~= "---"
								and prefix ~= "+++"
								and prefix ~= "@@"
								and line:sub(1, 4) ~= "diff"
								and line:sub(1, 5) ~= "index"
							then
								table.insert(lines, line)
							end
						end
						vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

						-- Apply diff highlights via modern extmarks API
						local ns_id = vim.api.nvim_create_namespace("git_time_machine")
						vim.api.nvim_set_hl(0, "TimeMachineAddLine", { fg = "#A6E3A1", bg = "#2A3D30" })
						vim.api.nvim_set_hl(0, "TimeMachineDelLine", { fg = "#F38BA8", bg = "#3D2A2A" })

						for i, line in ipairs(lines) do
							local first_char = line:sub(1, 1)
							if first_char == "+" then
								vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, {
									hl_group = "TimeMachineAddLine",
									end_row = i - 1,
									end_col = #line,
									hl_eol = true,
								})
							elseif first_char == "-" then
								vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, {
									hl_group = "TimeMachineDelLine",
									end_row = i - 1,
									end_col = #line,
									hl_eol = true,
								})
							end
						end
					end
				else
					vim.cmd("silent r !git show " .. commit_hash .. ":" .. filepath)
				end

				-- Clean empty padding lines
				if vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
					vim.cmd("1delete _")
				end

				-- Disable diagnostics and LSP
				vim.diagnostic.enable(false, { bufnr = buf })
				vim.lsp.buf_detach_client(buf, 0)

				local ft = vim.filetype.match({ filename = filepath })
				if ft then
					vim.bo[buf].filetype = ft
				end

				-- Window aesthetics and buffer lock
				vim.api.nvim_set_hl(0, "TimeMachineWindowBg", { bg = M.config.bg_color })
				vim.wo[win].winhighlight = "Normal:TimeMachineWindowBg,NormalNC:TimeMachineWindowBg"

				vim.bo[buf].buftype = "nofile"
				vim.bo[buf].bufhidden = "wipe"
				vim.bo[buf].readonly = true
				vim.bo[buf].modifiable = false
			end

			-- Check modified files in selected commit
			local handle = io.popen("git show --name-only --pretty=format: " .. commit_hash)
			if not handle then
				return
			end
			local result = handle:read("*a")
			handle:close()

			local changed_files = {}
			local found_current = false
			for line in result:gmatch("[^\r\n]+") do
				if line ~= "" then
					table.insert(changed_files, line)
					if line == current_file then
						found_current = true
					end
				end
			end

			if found_current then
				view_full_past_file_with_diff(current_file)
			else
				Snacks.picker.lines({
					title = current_file .. " unchanged. Select other file:",
					lines = changed_files,
					confirm = function(file_picker, file_item)
						file_picker:close()
						local filepath = file_item.text
						if filepath and filepath ~= "" then
							view_full_past_file_with_diff(filepath)
						end
					end,
				})
			end
		end,
	})
end

-- Setup core configurations and keymaps
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if M.config.shortcut then
		vim.keymap.set("n", M.config.shortcut, M.open, { desc = "Git Time Machine" })
	end
end

return M
