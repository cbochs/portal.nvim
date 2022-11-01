# Portal.nvim

> Look at you, sailing through the [jumplist] majestically, like an eagle... piloting a blimp.

## Features

**portal.nvim** is a lua plugin for Neovim which creates "portal" for you to jump through.

* **Contextual** jumping with portals to view available jump locations
* **Customizable** jump queries to allow you to go anywhere you'd like in the jumplist
* **Persistent** jump markers to flag important file you want to be able to get back to

## Requirements
## Installation

### [packer]()

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

## Configuration

The following is the default configuration. All configuration options may be overridden during plugin setup.

```lua
require("portal").setup({
	mark = {
        ---
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

            --- Keycodes that will exit portal selection
            escape = {
                ["<esc>"] = true
            },
        },

        --- The keys used for jumping forward and backward
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

A **portal** is a window that displays the jump location, the label required to get to that jump location, and any addition contextual information regarding the jump location (i.e. the jump's file name or matched query).

[]()

### Suggested Keymaps

```lua
vim.keymap.set("n", "<leader>o", require("portal").jump_backward, {})
vim.keymap.set("n", "<leader>i", require("portal").jump_forward, {})
```

## Queries

A **query** is a list of **query items** which are used to identify specifc jump locations. Each **query item** will attempt to match with a jump location based on a given criteria about the jump's buffer.

For example, a query of `{ "modified", "different" }` will attempt to find two jump locations. The first is where a jump's buffer has been _modified_. The second is where a jump's buffer is _different_ than the current buffer.

### Available Query Items

All query items are available from `portal.query` as `require("portal.query").{query_item}`.

#### `valid`

Matches jumps that have a valid buffer (see: `:h nvim_buf_is_valid`).

#### `different`

Matches jumps that have a buffer different than the current buffer.

#### `marked`

Matches jumps that are in a marked buffer (see [Marking](marking)).

#### `modified`

Matched jumpst that are in a modified buffer (see `:h 'modified'`).

### Custom Query Items

A **query item** is in fact a "query-like" item. It may be either a `string`, `Portal.Predicate`, or `Portal.QueryItem`. A string may be used to specify a query item that has been _registered_. To register a query, use `query.register` and pass in a key, predicate, and optional `name` and `name_short`.

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

A `mark` is a persistent tag on a file or buffer. It is a means of indicating a file you want to return to. By itself, it has no function. It's use comes when the `"marked"` query item is used in a query. For example, the following will open a single portal to the first `marked` file, searching backwards in the jumplist:

```lua
require("portal").jump_backward({
    query = { "marked" }
})
```

[]()

### Suggested Keymaps

```lua
vim.keymap.set("n", "<leader>m", require("portal.mark").mark, {})
```

## Previewer
