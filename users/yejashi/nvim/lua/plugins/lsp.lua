return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        bashls = {
          mason = false,
        },
        clangd = {
          mason = false,
        },
        pyright = {
          mason = false,
        },
        lua_ls = {
          mason = false,
        },
        nil_ls = {
          mason = false,
        },
        jsonls = {
          mason = false,
        },
        yamlls = {
          mason = false,
        },
        marksman = {
          mason = false,
        },
      },
    },
  },
}
