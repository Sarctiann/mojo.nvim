local M = {}

function M.check()
	vim.health.start("mojo.nvim")

	local ok, config = pcall(require, "mojo.config")
	if ok then
		vim.health.ok("mojo.nvim is installed and loaded")
		vim.health.info("Config: " .. vim.inspect(config.options or {}))
	else
		vim.health.error("mojo.nvim is not loaded", config)
		return
	end

	local env_ok, env = pcall(require, "mojo.env")
	if env_ok then
		local mojo_bin = env.get_mojo_cmd()
		if mojo_bin then
			vim.health.ok("mojo binary found: " .. mojo_bin)
		else
			vim.health.warn("mojo binary not found in PATH or project environment")
		end

		local lsp_bin = env.get_lsp_cmd()
		if lsp_bin then
			vim.health.ok("mojo-lsp-server found: " .. lsp_bin[1])
		else
			vim.health.warn("mojo-lsp-server not found")
		end

		local dap_bin = env.get_dap_cmd()
		if dap_bin then
			vim.health.ok("mojo-lldb-dap found: " .. dap_bin[1])
		else
			vim.health.info("mojo-lldb-dap not found (DAP disabled)")
		end

		local version = env.get_version()
		if version then
			vim.health.ok("Mojo SDK version: " .. version)
		else
			vim.health.info("Could not detect Mojo SDK version")
		end
	else
		vim.health.warn("mojo.env module not available")
	end

	local ts_ok, ts = pcall(require, "mojo.treesitter")
	if ts_ok then
		local stale = ts.stale_parser()
		if stale then
			vim.health.warn("Tree-sitter parser is stale — run :Mojo rebuild")
		else
			vim.health.ok("Tree-sitter parser is up to date")
		end
	else
		vim.health.warn("mojo.treesitter module not available")
	end

	if vim.lsp.config and vim.lsp.enable then
		vim.health.ok("native LSP config API available (vim.lsp.config)")
	else
		vim.health.warn("Neovim 0.11+ required for LSP integration (vim.lsp.config missing)")
	end

	if pcall(require, "conform") then
		vim.health.ok("conform.nvim available")
	else
		vim.health.info("conform.nvim not installed (formatting integration disabled)")
	end

	if pcall(require, "dap") then
		vim.health.ok("nvim-dap available")
	else
		vim.health.info("nvim-dap not installed (debug integration disabled)")
	end
end

return M
