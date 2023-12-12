return {
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "j-hui/fidget.nvim",
      "folke/neodev.nvim",
      "ray-x/lsp_signature.nvim",
    },
    opts = {
      diagnostics = {
        float = {
          source = "always",
        },
        virtual_text = false,
      },
      servers = {
        ruff_lsp = {},
        lua_ls = {
          Lua = {
            format = { enable = false },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
        html = {},
        cssls = {},
        tailwindcss = {},
      },
    },
    config = function(_, opts)
      local on_attach = function(client, bufnr)
        -- Attach the server to Navbuddy only if server is not ruff_lsp.
        -- ruff_lsp does not support documentSymbols.
        if client.name ~= "ruff_lsp" and client.name ~= "tailwindcss" then
          require("nvim-navbuddy").attach(client, bufnr)
        end

        local nmap = function(keys, func, desc)
          if desc then
            desc = "LSP: " .. desc
          end

          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<C-c>", vim.lsp.buf.code_action, "[C]ode [A]ction")

        nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
        nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
        nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature Help" })

        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "Format current buffer with LSP" })
        nmap("<leader>bf", "<cmd>Format<CR>", "[B]uffer [F]ormat")
      end

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

      require("neodev").setup()

      vim.diagnostic.config(opts.diagnostics)

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      local mason_lspconfig = require("mason-lspconfig")

      mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(opts.servers),
      })

      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = opts.servers[server_name],
          })
        end,
      })

      require("lspconfig").jedi_language_server.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        init_options = {
          diagnostics = { enable = false },
        },
      })

      capabilities.offsetEncoding = { "utf-16" }

      require("lspconfig").clangd.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        init_options = {
          diagnostics = { enable = false },
        },
      })

      -- Show line diagnostics automatically in the hover window
      vim.o.updatetime = 250
      vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]
    end,
  },

  {
    -- Mason Configuration
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    opts = {
      ensure_installed = {
        "black",
        "clang-format",
        "jedi-language-server",
        "prettierd",
        "sql-formatter",
        "stylua",
        "shfmt",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
}
