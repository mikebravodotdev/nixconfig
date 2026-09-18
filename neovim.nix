# neovim.nix
# A LazyVim-inspired Neovim setup, built declaratively with nixvim instead of
# LazyVim's own lazy.nvim (git-based) plugin manager. Not a literal port of
# LazyVim's Lua config — same idea (LSP, treesitter, fuzzy-find, file tree,
# modern statusline/bufferline, formatting-on-save), reproduced through Nix
# so `darwin-rebuild switch` fully provisions it, no separate git clone step.

{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # Use the pkgs already instantiated for this system (which nixvim's own
    # flake input is set to follow) instead of nixvim's separately-pinned
    # nixpkgs default — silences its "affected by your flake input follows" warning.
    nixpkgs.source = pkgs.path;

    colorschemes.tokyonight.enable = true;

    globals.mapleader = " ";
    globals.maplocalleader = " ";

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;
      ignorecase = true;
      smartcase = true;
      termguicolors = true;
      signcolumn = "yes";
      scrolloff = 8;
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      cursorline = true;
      clipboard = "unnamedplus";
    };

    plugins = {
      web-devicons.enable = true;
      lualine.enable = true;
      bufferline.enable = true;
      gitsigns.enable = true;
      comment.enable = true;
      indent-blankline.enable = true;
      which-key.enable = true;
      trouble.enable = true;
      todo-comments.enable = true;
      nvim-autopairs.enable = true;

      neo-tree = {
        enable = true;
        settings.filesystem.follow_current_file.enabled = true;
      };

      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };

      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # LSP servers for the toolchains declared in packages.nix (go, rustc,
      # nodejs, python3, ruby, lua) plus lua/nix for editing this repo itself.
      lsp = {
        enable = true;
        servers = {
          lua_ls.enable = true;
          nixd.enable = true;
          gopls.enable = true;
          ts_ls.enable = true;
          pyright.enable = true;
          ruby_lsp.enable = true;
          bashls.enable = true;
          rust_analyzer = {
            enable = true;
            # cargo/rustc are already declared in packages.nix
            installCargo = false;
            installRustc = false;
          };
        };
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping.select_next_item()";
            "<S-Tab>" = "cmp.mapping.select_prev_item()";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
          };
        };
      };
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp-buffer.enable = true;

      # Formatting on save, LazyVim-style (nixfmt for this repo's own .nix files)
      none-ls = {
        enable = true;
        sources.formatting = {
          stylua.enable = true;
          nixfmt.enable = true;
          # Avoid double-formatting JS/TS: let prettier own it, not ts_ls's built-in formatter.
          prettier = {
            enable = true;
            disableTsServerFormatter = true;
          };
          black.enable = true;
        };
      };
    };

    keymaps = [
      { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<CR>"; options.desc = "Toggle file explorer"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Live grep"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Help tags"; }
      { mode = "n"; key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<CR>"; options.desc = "Diagnostics (Trouble)"; }
      { mode = "n"; key = "<leader>gg"; action = "<cmd>Neotree float git_status<CR>"; options.desc = "Git status"; }
    ];
  };
}
