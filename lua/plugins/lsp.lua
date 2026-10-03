return {
    -- =====================================================================
    -- 1. mason.nvim : LSPサーバーを管理・ダウンロードするコアツール
    -- =====================================================================
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = { ui = { border = "rounded" } },
    },

    -- =====================================================================
    -- 2. mason-lspconfig.nvim : 自動インストールとセットアップハンドラ
    -- =====================================================================
    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        opts = {
            ensure_installed = {
                "lua_ls",
                "vtsls",
                "html",
                "cssls",
                "jsonls",
                "marksman",
                "pyright",
                "powershell_es",
                "bashls",
            },
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")

            require("mason-lspconfig").setup({
                ensure_installed = opts.ensure_installed,
                handlers = {
                    function(server_name)
                        local capabilities = {}
                        local pcall_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
                        if pcall_cmp then
                            capabilities = cmp_nvim_lsp.default_capabilities()
                        end

                        -- サーバー固有の設定
                        local server_opts = {
                            capabilities = capabilities,
                        }

                        -- lua_ls の特別設定
                        if server_name == "lua_ls" then
                            server_opts.root_dir = function(fname)
                                return lspconfig.util.root_pattern(".luarc.json", ".git")(fname) 
                                    or vim.fn.getcwd()
                            end
                            server_opts.settings = {
                                Lua = {
                                    runtime = { version = "LuaJIT" },
                                    diagnostics = { globals = { "vim" } },
                                    workspace = {
                                        library = vim.api.nvim_get_runtime_file("", true),
                                        checkThirdParty = false,
                                    },
                                    telemetry = { enable = false },
                                    signatureHelp = { enable = true },
                                },
                            }
                        end

                        lspconfig[server_name].setup(server_opts)
                    end,
                },
            })
        end,
    },

    -- =====================================================================
    -- 3. nvim-lspconfig : Neovim公式のLSP接続プラグイン本体（外観・キーマップ）
    -- =====================================================================
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            -- キーマップの設定：LSPが有効になったファイルでのみ有効にする
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }

                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "<Leader>r", vim.diagnostic.open_float, opts)

                    -- ⭕ 変更の核心: 0.11+仕様の vim.diagnostic.jump にキーマップを完全修正
                    -- [d : 前のエラー・警告にジャンプ
                    vim.keymap.set("n", "[d", function()
                        vim.diagnostic.jump({ count = -1, float = true })
                    end, opts)

                    -- ]d : 次のエラー・警告にジャンプ
                    vim.keymap.set("n", "]d", function()
                        vim.diagnostic.jump({ count = 1, float = true })
                    end, opts)

                    -- ⭕ シグネチャヘルプ (角丸枠付き)
                    vim.keymap.set("i", "<C-k>", function()
                        vim.lsp.buf.signature_help({ border = "rounded" })
                    end, opts)
                end,
            })

            -- ⭕ 左端の「W」や「E」の無骨なテキストを完璧なNerd Fontsアイコンへ強制同期
            vim.diagnostic.config({
                float = { border = "rounded" },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN]  = " ",
                        [vim.diagnostic.severity.HINT]  = "  ",
                        [vim.diagnostic.severity.INFO]  = " ",
                    },
                },
            })
        end,
    },
}
