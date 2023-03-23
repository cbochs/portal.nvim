# Portal.nvim

![portal_showcase](https://user-images.githubusercontent.com/2467016/222644459-264e22e7-496a-4d4e-bfcb-e96efda0003d.gif)

_Theme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)_

## Introduction

> Look at you, sailing through [neovim] majestically, like an eagle... piloting a blimp.

Portal is a plugin that aims to build upon and enhance existing location lists (e.g. jumplist, changelist, quickfix list, etc.) and their associated motions (e.g. `<c-o>` and `<c-i>`) by presenting jump locations to the user in the form of [portals](#portals).

See the [quickstart](#quickstart) section to get started.

## Features

* **Labelled** [portals](#portals) for immediate movement to a portal location
* **Customizable** [filters](#filters) and [slots](#slots) for [well-known lists](#builtin-queries)
* **Composable** multiple location lists can be used in a single search
* **Extensible** able to search any list with custom queries

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
- Explore the available [builtin](#builtin-queries) queries
- Tune your search results with a custom [filter](#filters) or [slot list](#slots)
- Try combining multiple queries using the [Portal API](#portal-api)

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
{
    "cbochs/portal.nvim",
    -- Optional dependencies
    dependencies = {
        "cbochs/grapple.nvim",
        "ThePrimeagen/harpoon"
    },
}
```

</details>

<details>
<summary>packer</summary>

```lua
use {
    "cbochs/portal.nvim",
    -- Optional dependencies
    requires = {
        "cbochs/grapple.nvim",
        "ThePrimeagen/harpoon"
    },
}
```

</details>

<details>
<summary>vim-plug</summary>

```vim
Plug "cbochs/portal.nvim"
" Optional dependencies
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

    ---The base filter applied to every search.
    ---@type Portal.SearchPredicate | nil
    filter = nil,

    ---The maximum number of results for any search.
    ---@type integer | nil
    max_results = nil,

    ---The maximum number of items that can be searched.
    ---@type integer
    lookback = 100,

    ---An ordered list of keys for labelling portals.
    ---Labels will be applied in order, or to match slotted results.
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

### Builtin Queries


<details>
<summary>Builtin Queries and Examples</summary>

Builin queries have a standardized interface. Each builtin can be accessed via the `Portal` command or lua API.

**Overview**: the `tunnel` method provides the default entry point for using Portal for a location list; the `tunnel_forward` and `tunnel_backward` are convenience methods for easy keybinds; the `search` method returns the results of a query; and the `query` method builds a [query](#portalquery) for use in [`portal#tunnel`](#portaltunnel) or [`portal#search`](#portalsearch).

**Command**: `:Portal {builtin} [direction]`

**API**: `require("portal.builtin").{builtin}`

- `{builtin}.query(opts)`
- `{builtin}.search(opts)`
- `{builtin}.tunnel(opts)`
- `{builtin}.tunnel_backward(opts)`
- `{builtin}.tunnel_forward(opts)`

**`opts?`**: [`Portal.SearchOptions`](#portalsearchoptions)

---

#### `changelist`

Filter, match, and iterate over Neovim's [`:h changelist`](https://neovim.io/doc/user/motion.html#changelist).

**Defaults**

- **`opts.start`**: current change index
- **`opts.direction`**: `"backward"`
- **`opts.max_results`**: `#settings.labels`

**Content**

- **`type`**: `"changelist"`
- **`buffer`**: `0`
- **`cursor`**: the changelist `lnum` and `col`
- **`select`**: uses native `g;` and `g,` to preserve changelist ordering
- **`direction`**: the search [direction](#portaldirection)
- **`distance`**: the absolute distance between the start and current changelist entry

<details>
<summary><b>Examples</b></summary>

```lua
-- Open a default search for the changelist
require("portal.builtin").changelist.tunnel()
```

</details>

#### `grapple`

Filter, match, and iterate over tagged files from [grapple](https://github.com/cbochs/grapple.nvim).

**Defaults**

- **`opts.start`**: `1`
- **`opts.direction`**: `"forward"`
- **`opts.max_results`**: `#settings.labels`

**Content**

- **`type`**: `"grapple"`
- **`buffer`**: the file tags's `bufnr`
- **`cursor`**: the file tags's `row` and `col`
- **`select`**: uses `grapple#select`
- **`key`**: the file tags's key

<details>
<summary><b>Examples</b></summary>

```lua
-- Open a default search for grapples's tags
require("portal.builtin").grapple.tunnel()
```

</details>

#### `harpoon`

Filter, match, and iterate over marked files from [harpoon](https://github.com/ThePrimeagen/harpoon).

**Defaults**

- **`opts.start`**: `1`
- **`opts.direction`**: `"forward"`
- **`opts.max_results`**: `#settings.labels`

**Content**

- **`type`**: `"harpoon"`
- **`buffer`**: the file mark's `bufnr`
- **`cursor`**: the file mark's `row` and `col`
- **`select`**: uses `harpoon.ui#nav_file`
- **`index`**: the file mark's index

<details>
<summary><b>Examples</b></summary>

```lua
-- Open a default search for harpoon's marks
require("portal.builtin").harpoon.tunnel()
```

</details>

#### `jumplist`

Filter, match, and iterate over Neovim's [`:h jumplist`](https://neovim.io/doc/user/motion.html#jumplist).

**Defaults**

- **`opts.start`**: current jump index
- **`opts.direction`**: `"backward"`
- **`opts.max_results`**: `#settings.labels`

**Content**

- **`type`**: `"jumplist"`
- **`buffer`**: the jumplist `bufnr`
- **`cursor`**: the jumplist `lnum` and `col`
- **`select`**: uses native `<c-o>` and `<c-i>` to preserve jumplist ordering
- **`direction`**: the search [direction](#portaldirection)
- **`distance`**: the absolute distance between the start and current jumplist entry

<details>
<summary><b>Examples</b></summary>

```lua
-- Open a default search for the jumplist
require("portal.builtin").jumplist.tunnel()

-- Open a queried search for the jumplist going backwards (<c-o>)
-- Query for two jumps:
-- 1. A jump that is in the same buffer as the current buffer
-- 2. A jump that is in a buffer that has been modified
require("portal.builtin").jumplist.tunnel_backward({
    slots = {
        function(value) return value.buffer == vim.fn.bufnr() end,
        function(value) return vim.api.nvim_buf_get_option(value.buffer, "modified") end,
    }
})

-- Open a filtered search for the jumplist going forwards (<c-i>)
-- Filters the results based on whether the buffer has been tagged
-- by grapple.nvim or not. Return a maximum of two results.
require("portal.builtin").jumplist.tunnel_forward({
    max_results = 2,
    filter = function(value)
        return require("grapple").exists({ buffer = value.buffer })
    end,
})
```

</details>

#### `quickfix`

Filter, match, and iterate over Neovim's [`:h quickfix`](http://neovim.io/doc/user/quickfix.html) list.

**Defaults**

- **`opts.start`**: `1`
- **`opts.direction`**: `"forward"`
- **`opts.max_results`**: `#settings.labels`

**Content**

- **`type`**: `"quickfix"`
- **`buffer`**: the quickfix `bufnr`
- **`cursor`**: the quickfix `lnum` and `col`
- **`select`**: uses `nvim_win_set_cursor` for selection

<details>
<summary><b>Examples</b></summary>

```lua
-- Open portals for the quickfix list (from the top)
require("portal.builtin").quickfix.tunnel()
```

</details>

</details>

### Portal API

<details>
<summary>Portal API and Examples</summary>

#### `portal#search`

The top-level method used for searching a location list query.

**API**: `require("portal").search(queries)`

**`queries`**: [`Portal.Query[]`](#portalquery)

<details>
<summary><b>Examples</b></summary>

```lua
-- Return the results of a query over the jumplist and quickfix list
local search_results = require("portal").search({
    require("portal.builtin").jumplist.query()
    require("portal.builtin").quickfix.query(),
})

-- Select the first location from the list of results
local first_portal = search_results[1]
first_portal.select()
```

</details>

#### `portal#tunnel`

The top-level method used for searching, opening, and selecting portals.

**API**: `require("portal").tunnel(queries)`

**`queries`**: [`Portal.Query[]`](#portalquery)

<details>
<summary><b>Examples</b></summary>

```lua
-- Run a simple filtered search over the jumplist
local query = require("portal.builtin").jumplist.query()
require("portal").tunnel(query)


-- Search both the jumplist and quickfix list
require("portal").tunnel({
    require("portal.builtin").jumplist.query({ max_results = 1 })
    require("portal.builtin").quickfix.query({ max_results = 1 }),
})
```

</details>

</details>

## Portals

A **portal** is a labelled floating window showing a snippet of some buffer. The label indicates a key that can be used to navigate directly to the buffer location. A portal may also contain additional information, such as the buffer's name or the result's index.

<img width="1043" alt="portal_screenshot" src="https://user-images.githubusercontent.com/2467016/222313082-8ae51576-5497-40e8-88d9-466ca504e22d.png">

## Search

To begin a search, a [query](#portalquery) (or list of queries) must be provided to portal. Each query will contain a [filtered](#filters) location list [iterator](#iterators) and (optionally) one or more [slots](#slots) to match against.

### Filters

During a search, a **filter** may be applied to remove any unwanted results from being displayed. More specifically, a filter is a [predicate](#portalsearchpredicate) function which accepts some value and returns `true` or `false`, indicating whether that value should be kept or discarded.

<details>
<summary><b>Examples</b></summary>

```lua
-- Filter for results that are in the same buffer
require("portal.builtin").jumplist({
    filter = function(v) return v.buffer == vim.fn.bufnr() end
})

-- Filter for results that are in a modified buffer
require("portal.builtin").quickfix({
    filter = function(v) return vim.api.nvim_buf_get_option(v.buffer, "modified") end
})

-- Filter for buffers that have been tagged by grapple.nvim
require("portal.builtin").quickfix({
    filter = function(v) return require("grapple").exists({ buffer = v.buffer }) end
})

-- Filter for results that are in some "root" directory
require("portal.builtin").jumplist({
    filter = function(v)
        local root_files = vim.fs.find({ ".git" }, { upward = true })
        if #root_files > 0 then
            local root_dir = vim.fs.dirname(root_files[1])
            local file_path = vim.api.nvim_buf_get_name(v.buffer)
            return string.match(file_path, ("^%s"):format(root_dir)) ~= nil
        end
        return true
    end
})
```

</details>

### Slots

To search for an exact set of results, one or more **slots** may be provided to a query. Each slot will attempt to be matched with its exact order (and index) preserved.

<details>
<summary><b>Examples</b></summary>

```lua
-- Try to match one result where the buffer is different than the
-- current buffer
require("portal.builtin").jumplist({
    slots = function(v) return v.buffer ~= vim.fn.bufnr() end
})

-- Try to match two results where the buffer is different than the
-- current buffer
require("portal.builtin").jumplist({
    slots = {
        function(v) return v.buffer ~= vim.fn.bufnr() end,
        function(v) return v.buffer ~= vim.fn.bufnr() end,
    }
})
```

</details>

### Iterators

All searches are performed over an input location list. Portal uses declarative **iterators** to prepare (`map`), refine (`filter`), match (`reduce`), and `collect` list search results. Iterators can be used to create custom queries.

<details>
<summary><b>Available operations</b></summary>

**Iterable operations**

Operations which return a [lua-style](https://www.lua.org/pil/7.3.html) iterator.

- `Iterator.next(index?: number)`
- `Iterator.iter()`

**Chainable operations**

Operations which return an iterator.

- `Iterator.start_at(n: integer)`
- `Iterator.reverse()`
- `Iterator.rrepeat(value: any)`
- `Iterator.skip(n: integer)`
- `Iterator.step_by(n: integer)`
- `Iterator.take(n: integer)`
- `Iterator.filter(f: fun(v: any): boolean)`
- `Iterator.map(f: fun(v: any, i: any): any | nil`: filters `nil` values

**Collect operations**

Operations which return a collection (list or table) of values.

- `Iterator.collect(): T[]`
- `Iterator.collect_table(): table`
- `Iterator.reduce(reducer: fun(acc, val, i): any, initial_state: any)`
- `Iterator.flatten()`

</details>

<details>
<summary><b>Examples</b></summary>

```lua
local Iterator = require("portal.iterator")

-- Print all values in a list
local iter = Iterator:new({ 1, 2, 3})
for i, v in iter:iter() do
    print(v)
end

-- Create the list { 7, 8, 9 }
Iterator:new({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
    :start_at(7)
    :take(3)
    :collect()

-- Create the list { 2, 4, 6, 8, 10 }
Iterator:new({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
    :filter(function(v) return v % 2 == 0 end)
    :collect()

-- Create the table { a = 1, b = 2 }
Iterator:new({ "a", "b" })
    :map(function(v, i) return { v, i } end)
    :collect_table()

-- Create a filtered and mapped table { 4, 6 }
Iterator:new({ 1, 2, 3})
    :filter(function(v) return v > 1 end)
    :map(function(v) return v * 2 end)
    :collect()

-- Create the same filtered and mapped table { 4, 6 }
Iterator:new({ 1, 2, 3 })
    :map(function(v) if v > 1 then return v * 2 end end)
    :collect()

-- Create the repeated list { 1, 1, 1 }
Iterator:rrepeat(1)
    :take(3)
    :collect()
```

</details>

## Highlight Groups

A few highlight groups are available for customizing the look of Portal.

| Group          | Description                | Default       |
|----------------|----------------------------|---------------|
| `PortalLabel`  | Portal label (extmark)     | `Search`      |
| `PoralTitle`   | Floating window title      | `FloatTitle`  |
| `PortalBorder` | Floating window border     | `FloatBorder` |
| `PortalNormal` | Floating window background | `NormalFloat` |

## Portal Types

<details open>
<summary>Type Definitions</summary>

### `Portal.SearchOptions`

Options available for tuning a search query. See the [builtins](#builtin-queries) section for information regarding search option defaults.

**Type**: `table`

- **`start`**: `integer`
- **`direction`**: [`Portal.Direction`](#portaldirection)
- **`max_results`**: `integer`
- **`filter`**: [`Portal.SearchPredicate`](#portalsearchpredicate)
- **`slots`**: [`Portal.SearchPredicate[]`](#portalsearchpredicate) | `nil`

### `Portal.Direction`

Used for indicating whether a search should be performed forwards or backwards.

**Type**: `enum`

- **`"forward"`**
- **`"backward"`**

### `Portal.SearchPredicate`

A specialized [predicate](#portalpredicate) where the value argument provided is a [`Portal.Content`](#portalcontent) result.

**Type**: `fun(c: Portal.Content): boolean`

### `Portal.Query`

Named tuple of `(source, slots)`. Used as the input to [`portal#tunnel`](#portaltunnel). When no `slots` are present, the `source` iterator will be simply be collected and presented as the search results.

**Type**: `table`

- **`source`**: [`Portal.Iterator`](#iterators)
- **`slots`**: [`Portal.SearchPredicate[]`](#portalsearchpredicate) | `nil`

### `Portal.Content`

Named tuple of `(type, buffer, cursor, select)` used in opening and selecting a portal location. **May contain** any additional data to aide in filtering, querying, and selecting a portal. See the [builtins](#builtin-queries) section for information on which additional fields are present.

**Type**: `table`

- **`type`**: `string`
- **`buffer`**: `integer`
- **`cursor`**: `{ row: integer, col: integer }`
- **`select`**: `fun(c: Portal.Content)`
- **anything else**

### `Portal.Predicate`

Basic function type used for [filtering](#filters) and [matching](#slots) values produced from an [iterator](#iterators).

**Type**: `fun(v: any): boolean`

### `Portal.QueryGenerator`

Generating function which transforms an input set of [`Portal.SearchOptions`](#portalsearchoptions) into a proper [`Portal.Query`](#portalquery).

**Type**: `fun(o: Portal.SearchOptions, s: Portal.Settings): Portal.Query`

</details>
