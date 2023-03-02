# Portal.nvim

![portal_showcase](https://user-images.githubusercontent.com/2467016/222316702-cf85ad4a-c331-4148-a851-26c275ed60cd.gif)

_Theme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)_

## Introduction

> Look at you, sailing through [neovim] majestically, like an eagle... piloting a blimp.

Portal is a plugin that aims to build upon and enhance existing lists (e.g. jumplist and quickfix list) and their associated motions (e.g. `<c-o>` and `<c-i>`) by surfacing contextual information with the use of [portals](#portals).

See the [quickstart](#quickstart) section to get started.

## Features

* **Labelled** [portals](#portals) for immediate movement to a jump location
* **Customizable** [queries](#queries) and [filters](#filters) for surfacing exactly where you want to go
* **Extensible** to open portals for virtually any [list of items](#builtins)
* **Integration** with [grapple.nvim](https://github.com/cbochs/grapple.nvim) to provide additional queries

## Requirements

* [Neovim >= 0.8](https://github.com/neovim/neovim/releases/tag/v0.8.0)
* Neovim >= 0.9 - optional, for [floating window title](https://github.com/neovim/neovim/issues/17458)

## Quickstart

- [Install](#installation) Portal.nvim using your preferred package manager
- Add keybinds for opening portals, both forwards and backwards

```lua
vim.keymap.set("n", "<leader>o", "<cmd>Portal jumplist backward<cr>")
vim.keymap.set("n", "<leader>i", "<cmd>Portal jumplist forward<cr>")
```

**Next steps**

- Check out the [default settings](#settings)
- Build your own portal provider using [Portal API](#portal-api)

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
{
    "cbochs/portal.nvim",
    -- Ootional dependencies
    dependencies = { "cbochs/grapple.nvim" },
}
```

</details>

<details>
<summary>packer</summary>

```lua
use {
    "cbochs/portal.nvim",
    -- Optional dependencies
    requires = { "cbochs/grapple.nvim" },
}
```

</details>

<details>
<summary>vim-plug</summary>

```vim
Plug "cbochs/portal.nvim"
" Optional dependencies
Plug "cbochs/grapple.nvim"
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

    ---The default query used when searching some lists
    ---@type Portal.Predicate[]
    query = nil,

    ---The base filter that is applied to every search.
    ---@type Portal.Predicate
    filter = function(v) return vim.api.nvim_buf_is_valid(v.buffer) end,

    ---The maximum number of results that can be returned when no query is given.
    ---@type integer
    max_results = 4,

    ---The maximum number of items that can be searched.
    ---@type integer
    lookback = 100,

    ---An ordered list of keys for labelling portals.
    ---Labels will be applied in order, or to match queried results.
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Keys used for exiting portal selection. Disable with [{key}] = false
    ---to `false`.
    ---@type table<string, boolean>
    escape = {
        ["<esc>"] = true,
    },

    ---The raw window options used for the portal window
    window_options = {
        relative = "cursor",
        width = 80,
        height = 3,
        col = 2,
        focusable = false,
        border = "single",
        noautocmd = true,
    },
})
```

</details>

## Usage

### Builtins

<details open>
<summary>Builtin Lists and Examples</summary>

#### `jumplist`

Query, filter, and iterate over Neovim's [`:h jumplist`](https://neovim.io/doc/user/motion.html#jump-motions).

**Command**: `:Portal jumplist [direction]`

**API**:

- `require("portal.builtin").jumplist.tunnel(opts)`
- `require("portal.builtin").jumplist.tunnel_forward(opts)`
- `require("portal.builtin").jumplist.tunnel_backward(opts)`

**`opts?`**: [`Portal.SearchOptions`](#portalsearchoptions)

**Defaults**

- **`opts.start`**: current jump index
- **`opts.direction`**: `"backward"`
- **`opts.max_results`**: `math.min(settings.max_results, #settings.labels)`
- **`opts.query`**: `settings.query`

**Examples**

```lua
-- Open portals for the jumplist going backward (<c-o>)
require("portal.builtin").jumplist.tunnel_backward()

-- Open portals for the jumplist going forward (<c-i>)
require("portal.builtin").jumplist.tunnel_forward()
```

#### `quickfix`

Query, filter, and iterate over Neovim's [`:h quickfix`](http://neovim.io/doc/user/quickfix.html) list.

**Command**: `:Portal quickfix [direction]`

**API**:

- `require("portal.builtin").quickfix.tunnel(opts)`
- `require("portal.builtin").quickfix.tunnel_forward(opts)`
- `require("portal.builtin").quickfix.tunnel_backward(opts)`

**`opts?`**: [`Portal.SearchOptions`](#portalsearchoptions)

**Defaults**

- **`opts.start`**: `1`
- **`opts.direction`**: `"forward"`
- **`opts.max_results`**: `math.min(settings.max_results, #settings.labels)`
- **`opts.query`**: `nil`

**Example**

```lua
-- Open portals for the quickfix list (from the top)
require("portal.builtin").quickfix.tunnel()
```

</details>

### Portal API

<details open>
<summary>Portal API and Examples</summary>

#### `portal#tunnel`

**API**: `require("portal").tunnel(opts)`

**`opts?`**: [`Portal.PortalOptions`](#portalportaloptions)

**Example**

```lua
```

</details>

## Portals

A **portal** is a window that shows a snippet of a buffer, a labelled "hotkey" for immediate navigation to the portal location, and any other available contextual information (e.g. the file buffer's name).

<img width="1043" alt="portal_screenshot" src="https://user-images.githubusercontent.com/2467016/222313082-8ae51576-5497-40e8-88d9-466ca504e22d.png">

## Sources

Lists provided to Portal can be filtered and queried to help present useful jump locations.

### Iterators
### Filters
### Queries

### Example Predicates

The following predicates can be used as either a `filter` or as part of a `query`.

**Different buffer**

```lua
function(value) return value.buffer ~= vim.fn.bufnr() end
```

**Modified buffer**

```lua
function(value) return vim.api.nvim_buf_get_option(value.buffer, "modified") end
```

**Tagged by grapple.nvim**

```lua
function(value) return require("grapple").exists({ buffer = value.buffer }) end
```
## Portal Types

<details open>
<summary>Type Definitions</summary>

### `Portal.PortalOptions`
### `Portal.SearchOptions`
### `Portal.Direction`
### `Portal.Predicate`
### `Portal.Iterator`
### `Portal.GeneratorSpec`
### `Portal.Generator`
### `Portal.Tunnel`

</details>
