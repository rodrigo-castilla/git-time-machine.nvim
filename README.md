# time-machine.nvim

A lightweight, asynchronous git time-machine plugin for Neovim powered by Snacks.picker. Inspect historical file snapshots and full diff context instantly in a dedicated read-only split window, without disrupting your active development workspace or locking your layout.

## Features

- **Asynchronous Workspaces:** Read the past on the right buffer while actively editing the present on the left buffer.
- **Context-Aware Mapping:** If the active file has modifications in the selected commit, it opens directly. If unchanged, it falls back to a picker listing all modified files in that commit.
- **Visual Isolation:** The historical snapshot features a dedicated background color alongside inline added/deleted diff color highlights.
- **Zero LSP/Linter Noise:** Automatically detaches LSPs and disables diagnostics on time-machine buffers to prevent syntax noise and error alerts.

## Requirements

- Neovim >= 0.10.0
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) (Specifically `Snacks.picker`)
- `git` CLI installed on your system path.

## Installation

### Using lazy.nvim

```lua
{
    "rodrigo-castilla/git-time-machine.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
        shortcut = "<leader>gt", -- Keymap to trigger the time-machine picker
        bg_color = "#064040",    -- Background hex color for the past buffer window
    },
}
```
