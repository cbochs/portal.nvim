# Portal.nvim

> Look at you, sailing through the [jumplist] majestically, like an eagle... piloting a blimp.

-----

<img width="1774" alt="Screen Shot 2022-10-31 at 20 53 10" src="https://user-images.githubusercontent.com/2467016/199148462-1eb28f75-16fa-4da3-9d8d-19f3d62ea51d.png">

_Theme: [catppuccin](https://github.com/catppuccin/nvim)_

## Features

* **Contextual** jumping with portals to view available jump locations
* **Customizable** jump queries to allow you to go anywhere you'd like in the jumplist
* **Persistent** jump markers to flag important file you want to be able to get back to
* [**Lualine**](#lualine) integration to indicate if a buffer has been marked

## Requirements

* [Neovim >= 0.5](https://github.com/neovim/neovim/releases/tag/v0.5.0)

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
    end
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
    mark = {
        save_path = vim.fn.stdpath("data") .. "/" .. "portal.json",
    },

    jump = {
        --- The default queries used when searching the jumplist. An entry can
        --- be a name of a registered query item, an anonymous predicate, or
        --- a well-formed query item. See Queries section for more information.
        --- @type Portal.QueryLike[]
        query = { "marked", "modified", "different", "valid" },

        labels = {
            --- An ordered list of keys that will be used for labelling
            --- available jumps. Labels will be applied in same order as
            --- `jump.query`
            select = { "j", "k", "h", "l" },

            --- Keys which will exit portal selection
            escape = {
                ["<esc>"] = true
            },
        },

        --- Keys used for jumping forward and backward
        keys = {
            forward = "<c-i>",
            backward = "<c-o>"
        }
    },

    window = {
        title = {
            --- When a portal is empty, render an default portal title
            render_empty = true,

            --- The raw window options used for the title window
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

        portal = {
            -- When a portal is empty, render an empty buffer body
            render_empty = false,

            --- The raw window options used for the portal window
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

})
```

## Portals

A **portal** is a window that displays the jump location, the label required to get to that jump location, and any addition contextual information (i.e. the jump's file name or matched query).

![portal_jump mov](https://user-images.githubusercontent.com/2467016/199164298-1083fdae-4d9c-480c-9962-41a853127e80.gif)

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
-- Invalid jumps will have their direction field set to types.Direction.NONE
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

#### `marked`

Matches jumps that are in a marked buffer (see [Marking](#marking)).

#### `modified`

Matched jumps that are in a modified buffer (see `:h 'modified'`).

### Custom Query Items

A **query item** found in the configuration is in fact a "query-like" item. It may be either a `string`, `Portal.Predicate`, or `Portal.QueryItem`. A string may be used to specify a query item that has been _registered_. To register a query, use `query.register` and pass in a key, predicate, and optional `name` and `name_short`.

#### Registered query items

```lua
--- Define the predicate
--- @param jump Portal.Jump
--- @return boolean
local function is_listed(jump)
    return require("portal.query").valid(jump)
        and vim.fn.buflisted(jump.buffer)
end

-- Register the predicate with an associated key
require("portal.query").register("listed", is_listed, {
    name = "Listed",
    name_short = "L",
})

--- Use the registered query item
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

## Marking

A `mark` is a persistent tag on a file or buffer. It is a means of indicating a file you want to return to. By itself, it has no function. It's use comes when `"marked"` is used in a query.

For example, the following will open a single portal to the first `marked` file, searching backwards in the jumplist:

```lua
require("portal").jump_backward({
    query = { "marked" }
})
```

[]()

### Suggested Keymaps

```lua
vim.keymap.set("n", "<leader>m", require("portal.mark").toggle, {})
```

### Removing Marks

Marks may be cleared individually or for an entire project scope.

#### Clear individual mark

```lua
require("portal.mark").unmark()
```

#### Clear all marks

```lua
require("portal.mark").reset()
```

## Previewer

**todo!(cbochs)**

## Lualine

A simple lualine component called `portal_status` is provided to show whether a buffer is marked or not.

**Mark inactive**

<img width="276" alt="Screen Shot 2022-11-01 at 07 02 09" src="https://user-images.githubusercontent.com/2467016/199238779-955bd8f3-f406-4a61-b027-ac64d049481a.png">

**Mark active**

<img width="276" alt="Screen Shot 2022-11-01 at 07 02 38" src="https://user-images.githubusercontent.com/2467016/199238764-96678f97-8603-45d9-ba2e-9a512ce93727.png">

**Usage**

```lua
require("lualine").setup({
    sections = {
        lualine_b = { grapple_status }
    }
})
```

## Inspiration

* ThePrimeagen's [harpoon](https://github.com/ThePrimeagen/harpoon)
* kwarlwang's [bufjump.nvim](https://github.com/kwkarlwang/bufjump.nvim)
