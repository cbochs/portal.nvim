# Portal.nvim

> Look at you, sailing through the [jumplist] majestically, like an eagle... piloting a blimp.

---

![portal_jump mov](https://user-images.githubusercontent.com/2467016/199164298-1083fdae-4d9c-480c-9962-41a853127e80.gif)

_Theme: [catppuccin](https://github.com/catppuccin/nvim)_

## Introduction

Portal is a plugin that aims to build upon and enhance existing jumplist motions (i.e. `<c-o>` and `<c-i>`) by surfacing contextual information with the use of [portals](#portals), and providing multiple jump options by means of [queries](#queries).

To get started, [install](#installation) the plugin using your preferred package manager, setup the plugin, add the suggested keybindings for portals and tagging, and give it a go! You can find the default configuration for the plugin in the secion [below](#configuration).

## Features

* **Contextual** jumping with portals to view available jump locations
* **Customizable** jump queries to allow you to go anywhere you'd like in the jumplist
* **Persistent** jump tags to flag important file you want to be able to get back to
* **Integration** with [grapple.nvim](https://github.com/cbochs/grapple.nvim) and [harpoon](https://github.com/ThePrimeagen/harpoon) to provide additional queries

## Requirements

* [Neovim >= 0.5](https://github.com/neovim/neovim/releases/tag/v0.5.0)
* Neovim >= 0.9 - (Optional, for [floating window title](https://github.com/neovim/neovim/issues/17458))

## Installation

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "cbochs/portal.nvim",
    config = function()
        require("portal").setup({
            -- Your configuration goes here
            -- Leave empty to use the default configuration
            -- Please see the Configuration section below for more information
        })
    end,
    requires = {
        "cbochs/grapple.nvim",  -- Optional: provides the "grapple" query item
        "ThePrimeagen/harpoon", -- Optional: provides the "harpoon" query item
    },
}
```

### [Plug](https://github.com/junegunn/vim-plug)

```
Plug "cbochs/portal.nvim"
```

## Configuration

The following is the default configuration. All configuration options may be overridden during plugin setup.

```lua
require("portal").setup({
    ---The default queries used when searching the jumplist. An entry can
    ---be a name of a registered query item, an anonymous predicate, or
    ---a well-formed query item. See Queries section for more information.
    ---@type Portal.QueryLike[]
    query = { "modified", "different", "valid" },

    ---An ordered list of keys that will be used for labelling available jumps.
    ---Labels will be applied in same order as `query`.
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Keys used for exiting portal selection. To disable a key, set its value
    ---to `nil` or `false`.
    ---@type table<string, boolean | nil>
    escape = {
        ["<esc>"] = true,
    },

    ---The jumplist is fixed at 100 items, which has the possibility to impact
    ---portal performance. Set this to a value less than 100 to limit the number
    ---of jumps in the jumplist that will be queried.
    lookback = 100,

    portal = {
        title = {
            --- When a portal is empty, render an default portal title
            render_empty = true,

            --- The raw window options used for the portal title window
            options = {
                relative = "cursor",
                width = 80,
                height = 1,
                col = 2,
                style = "minimal",
                focusable = false,
                border = "single",
                noautocmd = true,
                zindex = 98,
            },
        },

        body = {
            -- When a portal is empty, render an empty buffer body
            render_empty = false,

            --- The raw window options used for the portal body window
            options = {
                relative = "cursor",
                width = 80,
                height = 3,
                col = 2,
                focusable = false,
                border = "single",
                noautocmd = true,
                zindex = 99,
            },
        },
    },

    integrations = {
        ---cbochs/grapple.nvim: registers the "grapple" query item
        grapple = false,

        ---ThePrimeagen/harpoon: registers the "harpoon" query item
        harpoon = false,
    }
})
```

## Portals

A **portal** is a window that displays the jump location, the label required to get to that jump location, and any addition contextual information (i.e. the jump's file name or matched query).

<img width="1774" alt="Screen Shot 2022-11-01 at 14 02 18" src="https://user-images.githubusercontent.com/2467016/199328505-ebd06a30-c931-4aa3-9828-d2970d811dfd.png">

### Suggested Keymaps

```lua
vim.keymap.set("n", "<leader>o", require("portal").jump_backward, {})
vim.keymap.set("n", "<leader>i", require("portal").jump_forward, {})
```

## Queries

A **query** is a list of **query items** which are used to identify specifc jump locations in the jumplist. Each **query item** will attempt to match with a jump location based on a given criteria.

For example, a query of `{ "modified", "different" }` will attempt to find two jump locations. The first is where a jump's buffer has been _modified_. The second is where a jump's buffer is _different_ than the current buffer.

```lua
local query = { "modified", "different" }

-- A query can be used in the context of jumping and passed in as an option
-- or through the configuration
require("portal").jump_forward({ query = query })

-- A list of query-like items must be resolved into proper Portal.QueryItem's
local resolved_query = require("portal.query").resolve(query)

-- A search can be explicitly searched for, returning a list of Portal.Jump.
-- Invalid jumps will have their direction field set to types.direction.none
local available_jumps = require("portal.jump").search(query)
```

### Available Query Items

All registered query items are available as table values from `query`. For example, the query item for `"valid"` would be:

```lua
require("portal.query").valid
```

#### `valid`

Matches jumps that have a valid buffer (see: `:h nvim_buf_is_valid`).

#### `different`

Matches jumps that have a buffer different than the current buffer.

#### `modified`

Matched jumps that are in a modified buffer (see `:h 'modified'`).

#### `custom`

See how to create your own [custom query items](#custom-query-items) and available [integrations](#integrations) for more information.

### Custom Query Items

A **query item** found in the configuration is in fact a "query-like" item. It may be either a `string`, `Portal.Predicate`, or `Portal.QueryItem`. A string may be used to specify a query item that has been _registered_. To register a query, use `query.register` and pass in a key, predicate, and optional `name` and `name_short`.

#### Registering query items

```lua
---Define the predicate
---@param jump Portal.Jump
---@return boolean
local function is_listed(jump)
    return require("portal.query").valid(jump)
        and vim.fn.buflisted(jump.buffer)
end

-- Register the predicate with an associated key
require("portal.query").register("listed", is_listed, {
    name = "Listed",
    name_short = "L",
})

-- Use the registered query item
require("portal").jump_backward({
    query = { "listed" }
})
```

#### Anonymous query items

Anonymous query items may also be used instead of explicitly registering a query item.

```lua
require("portal").jump_backward({
    query = {
        -- A query item may be an unnamed Portal.Predicate
        function(jump) ... end,

        -- A query item may be a well-formed, but unregistered, Portal.QueryItem
        {
            predicate = function(jump) ... end,
            type = "{type}" -- synomymous with a query item's "key"
            name = "{name}",
            name_short = "{name_short}"
        }
    }
})
```

## Previewer

**todo!(cbochs)**

## Highlight Groups

A number of highlight groups are available to let you style your portals:

### `PortalBorder`

The default window border placed around any open portal.

**Default**: `FloatBorder`

### `PortalBorderBackward`

The window border placed around an open portal when the jump direction is backward.

**Default**: `PortalBorder`

### `PortalBorderForward`

The window border placed around an open portal when the jump direction is forward.

**Default**: `PortalBorder`

### `PortalBorderNone`

The window border placed around an open portal when the jump direction is forward.

**Default**: `PortalBorder`

### `PortalLabel`

The label (extmark) placed next to a portal jump location.

**Default**: `{ bg = "#a6e3a1", fg = "#1e1e2e" }`

**Example**

```lua
-- Give window borders a "portal" feel
vim.api.nvim_set_hl(0, "PortalBorder", { fg = "#fab387" })
vim.api.nvim_set_hl(0, "PortalBorderNone", { fg = "#89b4fa" })
```

## Integrations

### [grapple.nvim](https://github.com/cbochs/grapple.nvim)

**Query item**: `"grapple"`

Matches jumps that are in a buffer tagged by [grapple.nvim](https://github.com/cbochs/grapple.nvim).

```lua
require("portal").setup({
    integrations = {
        grapple = true
    }
])
```

**Usage**

```lua
require("portal").setup({
    query = { "grapple", ... }
})
```

#### Jump to the first tagged buffer in the jumplist

Use Portal and Grapple to jump directly to the first tagged buffer navigating backwards in the jumplist, without opening any portals.

```lua
local query = require("portal.query").resolve({ "grapple" })
local jumps = require("portal.jump").search(query, "backward")
require("portal.jump").select(jumps[1])
```

### [harpoon](https://github.com/ThePrimeagen/harpoon)

**Query item**: `"harpoon"`

Matches jumps that are in a buffer marked by [harpoon](https://github.com/ThePrimeagen/harpoon).

```lua
require("portal").setup({
    integrations = {
        harpoon = true
    }
})
```

**Usage**

```lua
require("portal").setup({
    query = { "harpoon", ... }
})
```

## Inspiration

* tjdevries [vlog.nvim](https://github.com/tjdevries/vlog.nvim)
* ThePrimeagen's [harpoon](https://github.com/ThePrimeagen/harpoon)
* kwarlwang's [bufjump.nvim](https://github.com/kwkarlwang/bufjump.nvim)
