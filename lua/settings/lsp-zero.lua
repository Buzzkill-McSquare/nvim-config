local lsp_zero = require('lsp-zero')
local config = require('lspconfig')

lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })
end)

-- Tell the server the capability of foldingRange,
-- Neovim hasn't added foldingRange to default capabilities, users must add it manually
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
}
local language_servers = { 'tsserver', 'ruby_lsp', 'rubocop' } -- or list servers manually like {'gopls', 'clangd'}
for _, ls in ipairs(language_servers) do
    require('lspconfig')[ls].setup({
        -- capabilities = capabilities
        -- you can add other fields for setting up lsp server in this table
    })

    require('lspconfig')['ruby_lsp'].setup(
	     {
  default_config = {
    cmd = { 'ruby-lsp' },
    filetypes = { 'ruby' },
    root_dir = require("lspconfig.util").root_pattern('Gemfile', '.git'),
    init_options = {
      formatter = 'rubocop',
    },
    single_file_support = true,
  },
  docs = {
    description = [[
https://shopify.github.io/ruby-lsp/

This gem is an implementation of the language server protocol specification for
Ruby, used to improve editor features.

Install the gem. There's no need to require it, since the server is used as a
standalone executable.

```sh
group :development do
  gem "ruby-lsp", require: false
end
```
    ]],
    default_config = {
      root_dir = [[root_pattern("Gemfile", ".git")]],
    },
  },
})
end

require("mason").setup {
	log_level = vim.log.levels.DEBUG
}

-- textDocument/diagnostic support until 0.10.0 is released
_timers = {}
local function setup_diagnostics(client, buffer)
  if require("vim.lsp.diagnostic")._enable then
    return
  end

  local diagnostic_handler = function()
    local params = vim.lsp.util.make_text_document_params(buffer)
    client.request("textDocument/diagnostic", { textDocument = params }, function(err, result)
      if err then
        local err_msg = string.format("diagnostics error - %s", vim.inspect(err))
        vim.lsp.log.error(err_msg)
      end
      local diagnostic_items = {}
      if result then
        diagnostic_items = result.items
      end
      vim.lsp.diagnostic.on_publish_diagnostics(
        nil,
        vim.tbl_extend("keep", params, { diagnostics = diagnostic_items }),
        { client_id = client.id }
      )
    end)
  end

  diagnostic_handler() -- to request diagnostics on buffer when first attaching

  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function()
      if _timers[buffer] then
        vim.fn.timer_stop(_timers[buffer])
      end
      _timers[buffer] = vim.fn.timer_start(200, diagnostic_handler)
    end,
    on_detach = function()
      if _timers[buffer] then
        vim.fn.timer_stop(_timers[buffer])
      end
    end,
  })
end

-- adds ShowRubyDeps command to show dependencies in the quickfix list.
-- add the `all` argument to show indirect dependencies as well
local function add_ruby_deps_command(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps",
                                          function(opts)

        local params = vim.lsp.util.make_text_document_params()

        local showAll = opts.args == "all"

        client.request("rubyLsp/workspace/dependencies", params,
                        function(error, result)
            if error then
                print("Error showing deps: " .. error)
                return
            end

            local qf_list = {}
            for _, item in ipairs(result) do
                if showAll or item.dependency then
                    table.insert(qf_list, {
                        text = string.format("%s (%s) - %s",
                                              item.name,
                                              item.version,
                                              item.dependency),

                        filename = item.path
                    })
                end
            end

            vim.fn.setqflist(qf_list)
            vim.cmd('copen')
        end, bufnr)
    end, {nargs = "?", complete = function()
        return {"all"}
    end})
end


require("lspconfig").ruby_lsp.setup({
  on_attach = function(client, buffer)
    setup_diagnostics(client, buffer)
    add_ruby_deps_command(client, buffer)
  end,
})

require('ufo').setup()

