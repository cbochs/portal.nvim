# Portal.nvim

> Look at you, sailing through [neovim] majestically, like an eagle... piloting a blimp.

---

<!-- TODO: update showcase -->
![portal_showcase](https://user-images.githubusercontent.com/2467016/199164298-1083fdae-4d9c-480c-9962-41a853127e80.gif)

_Theme: [catppuccin](https://github.com/catppuccin/nvim)_

## Introduction

Portal is a plugin that aims to build upon and enhance existing jump lists (e.g. jumplist, taglist) and their assocaited motions (i.e. `<c-o>` and `<c-i>`) by surfacing contextual information with the use of [portals](#portals).

See the [quickstart](#quickstart) section to get started.

## Features

<!-- TODO: update links to sections -->
* **Labelled** [portals](#portals) for immediate movement to a jump location
* **Customizable** [queries and filters](#portal-results) for surfacing exactly where you want to go
* **Extensible** to open portals for virtually any list of items
* **Integration** with [grapple.nvim](https://github.com/cbochs/grapple.nvim) and [harpoon](https://github.com/ThePrimeagen/harpoon) to provide additional queries

## Requirements

* [Neovim >= 0.8](https://github.com/neovim/neovim/releases/tag/v0.8.0)
* Neovim >= 0.9 - optional, for [floating window title](https://github.com/neovim/neovim/issues/17458)

## Quickstart

- [Install](#installation) Portal.nvim using your preferred package manager
- Add a simple keybind for opening portals, both forwards and backwards

```lua
vim.keymap.set("n", "<leader>o", "<cmd>Portal jumplist backward<cr>")
vim.keymap.set("n", "<leader>i", "<cmd>Portal jumplist forward<cr>")
```

**Next steps**

- Check out the [default settings](#settings)
- Try jumping with a different [builtin](#builtin) list
- Build your own portal provider using [Portal API](#portal-api)

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
{
    "cbochs/portal.nvim",
    dependencies = {
        "cbochs/grapple.nvim",  -- (optional)
        "ThePrimeagen/harpoon", -- (optional)
    },
}
```

</details>

<details>
<summary>packer</summary>

```lua
use {
    "cbochs/portal.nvim",
    requires = {
        "cbochs/grapple.nvim",  -- (optional)
        "ThePrimeagen/harpoon", -- (optional)
    },
}
```

</details>

<details>
<summary>vim-plug</summary>

```vim
Plug "cbochs/portal.nvim"

" Optional
Plug "cbochs/grapple.nvim"
Plug "ThePrimeagen/harpoon"
```

</details>

## Settings

The following are the default settings for Portal. **Setup is not required**, but settings may be overridden by passing them as table arguments to the `portal#setup` function.

<details>
<summary>Default Settings</summary>

```lua
require("portal").setup({
    ---@type "debug" | "info" | "warn" | "error"
    log_level = "warn",

    ---The default queries used when searching the jumplist. An entry can
    ---be a name of a registered query item, an anonymous predicate, or
    ---a well-formed query item. See Queries section for more information.
    ---@type Portal.Predicate[]
    query = nil,

    -- stylua: ignore
    --- TODO: document base filter
    ---@type Portal.Predicate
    filter = function(v) return vim.api.nvim_buf_is_valid(v.buffer) end,

    --- TODO: document lookback behaviour
    ---@type integer
    lookback = 100,

    ---An ordered list of keys that will be used for labelling available jumps.
    ---Labels will be applied in same order as `query`.
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Keys used for exiting portal selection. To disable a key, set its value
    ---to `false`.
    ---@type table<string, boolean>
    escape = {
        ["<esc>"] = true,
    },

    ---The raw window options used for the portal window
    window_options = {
        relative = "cursor",
        width = 80, -- implement as "min/max width",
        height = 3, -- implement as "context lines"
        col = 2, -- implement as "offset"
        focusable = false,
        border = "single",
        noautocmd = true,
    },
})
```

</details>

## Usage

### Builtin

<details>
<summary>Builtin Lists and Examples</summary>
</details>

### Portal API

<details>
<summary>Portal API and Examples</summary>
</details>

## Portals

A **portal** is a window that shows a snippet of some cursor location, a label "hotkey" for immediate navigation to the portal location, and any other available contextual information (e.g. the file buffer's name).

<!-- TODO: update portal screenshot -->
<img width="1774" alt="Screen Shot 2022-11-01 at 14 02 18" src="https://user-images.githubusercontent.com/2467016/199328505-ebd06a30-c931-4aa3-9828-d2970d811dfd.png">

## List Sources

Lists provided to Portal can be filtered and queried to help present useful jump locations.

### Filters
### Queries

#### Available Queries

* `different`: matches when the buffer is not the current buffer
* `modified`: matches when the buffer has been modified

A few

* `grapple`: matches when the buffer has been tagged by [grapple.nvim](https://github.com/cbochs/grapple.nvim)
* `harpoon`: matches when the buffer has been marked by [harpoon](https://github.com/ThePrimeagen/harpoon)
