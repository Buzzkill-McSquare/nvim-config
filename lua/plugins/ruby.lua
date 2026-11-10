-- nexia_home runs in Docker (gems live only in the home_gems volume, Ruby 2.7.8),
-- so the stock Ruby tooling can't use its bundle from the host.
local nexia_home = vim.fn.expand("~/Development/trane/nexia_home")

local function in_nexia_home(path)
  return path ~= nil and vim.startswith(vim.fn.resolve(path) .. "/", nexia_home .. "/")
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          -- In nexia_home: the lockfile's Bundler 2.2.21 crashes on Ruby 3.4, and the
          -- container's Ruby is too old for ruby-lsp, so use a standalone bundle on 3.4.6
          cmd = function(dispatchers, config)
            local root = config and config.root_dir
            local cmd, env = { "ruby-lsp" }, nil
            if in_nexia_home(root) then
              -- bundle exec is required: with BUNDLE_GEMFILE set, ruby-lsp skips its own bundle
              -- setup, leaving global gems (and RuboCop's add-on) visible
              cmd = { "mise", "exec", "ruby@3.4.6", "--", "bundle", "exec", "ruby-lsp" }
              env = { BUNDLE_GEMFILE = vim.fn.expand("~/.config/ruby-lsp/Gemfile") }
            end
            return vim.lsp.rpc.start(cmd, dispatchers, { cwd = config and (config.cmd_cwd or root), env = env })
          end,
        },
        rubocop = {
          -- In nexia_home: RuboCop plugins live only in the container, and its 1.36 has no
          -- --lsp mode; formatting goes through conform's rubocop_docker instead
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, { "Gemfile", ".git" })
            if root and not in_nexia_home(root) then
              on_dir(root)
            end
          end,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        rubocop_docker = {
          command = "docker",
          args = {
            "exec", "-i", "-w", "/app", "home_test", "bash", "-ic",
            'exec bundler exec rubocop -a --stderr --stdin "$1"', "_", "$RELATIVE_FILEPATH",
          },
          cwd = function()
            return nexia_home
          end,
          condition = function(_, ctx)
            return in_nexia_home(ctx.filename)
          end,
          exit_codes = { 0, 1 }, -- 1 = offenses remain that can't be autocorrected
        },
      },
      formatters_by_ft = {
        ruby = { "rubocop_docker", "rubocop", stop_after_first = true },
      },
    },
  },
}
