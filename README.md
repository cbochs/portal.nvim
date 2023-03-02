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
* **Integration** with [grapple.nvim](https://github.com/cbochs/grapple.nvim) for additional query options

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
- Explore the available [builtin](#builtins) lists
- Add a custom [filter](#filters) or [query](#queries)
- Build a custom portal provider

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

<details>
<summary>Builtin Lists and Examples</summary>

#### `jumplist`

Query, filter, and iterate over Neovim's [`:h jumplist`](https://neovim.io/doc/user/motion.html#jump-motions).

**Command**: `:Portal jumplist [direction]`

**API**:

- `require("portal.builtin").jumplist.tunnel(opts)`
- `require("portal.builtin").jumplist.tunnel_forward(opts)`
- `require("portal.builtin").jumplist.tunnel_backward(opts)`
- `require("portal.builtin").jumplist.query(opts)`

**`opts?`**: [`Portal.SearchOptions`](#portalsearchoptions)

**Defaults**

- **`opts.start`**: current jump index
- **`opts.direction`**: `"backward"`
- **`opts.max_results`**: `math.min(settings.max_results, #settings.labels)`
- **`opts.query`**: `settings.query`


<details>
<summary><b>Example</b></summary>

```lua
-- Open portals for the jumplist (default: search backward)
require("portal.builtin").jumplist.tunnel()

-- Open portals for the jumplist going backward (<c-o>)
-- Query for two jumps:
-- 1. A jump that is in a different buffer than the current buffer
-- 2. A jump that is in a buffer that has been modified
require("portal.builtin").jumplist.tunnel_backward({
    query = {
        function(value) return value.buffer ~= vim.fn.bufnr() end,
        function(value) return vim.api.nvim_buf_get_option(value.buffer, "modified") end,
    }
})

-- Open portals for the jumplist going forward (<c-i>)
-- Filters the results based on whether the buffer has been tagged
-- by grapple.nvim or not. Return a maximum of two results.
local filter = function(value) return require("grapple").exists({ buffer = value.buffer }) end
require("portal.builtin").jumplist.tunnel_forward({
    filter = filter,
    max_results = 2,
})
```

</details>

#### `quickfix`

Query, filter, and iterate over Neovim's [`:h quickfix`](http://neovim.io/doc/user/quickfix.html) list.

**Command**: `:Portal quickfix [direction]`

**API**:

- `require("portal.builtin").quickfix.tunnel(opts)`
- `require("portal.builtin").quickfix.tunnel_forward(opts)`
- `require("portal.builtin").quickfix.tunnel_backward(opts)`
- `require("portal.builtin").quickfix.query(opts)`

**`opts?`**: [`Portal.SearchOptions`](#portalsearchoptions)

**Defaults**

- **`opts.start`**: `1`
- **`opts.direction`**: `"forward"`
- **`opts.max_results`**: `math.min(settings.max_results, #settings.labels)`
- **`opts.query`**: `nil`


<details>
<summary><b>Example</b></summary>

```lua
-- Open portals for the quickfix list (from the top)
require("portal.builtin").quickfix.tunnel()
```

</details>

</details>

### Portal API

<details>
<summary>Portal API and Examples</summary>


#### `portal#tunnel`

The top-level method used for searching, opening, and selecting a portal location.

**API**: `require("portal").tunnel(queries)`

**`queries`**: [`Portal.Query[]`](#portalquery)

<details>
<summary><b>Example</b></summary>

```lua
-- Run a simple filtered search over the jumplist
local query = require("portal.builtin").jumplist.query()
require("portal").tunnel(query)


-- Search both the jumplist and quickfix list
local jumplist = require("portal.builtin").jumplist
local jumplist_query = jumplist.query({ max_results = 1 })

local quickfix = require("portal.builtin").quickfix
local quickfix_query = quickfix.query({ max_results = 1 })

require("portal").tunnel({ jumplist_query, quickfix_query })

```

#### `portal.search#search`

A general-purpose method for collecting and (optionally) [querying](#queries) a Portal **[iterator](#iteration)**.

#### `portal.search#query`

A reduce-like method that attempts to match a list of [predicates](#filters) against items from an **[iterator](#iteration)**.

</details>


</details>

## Portals

A **portal** is a window that shows a labelled snippet of a buffer. The label indicates a key that can be used to navigate directly to the buffer location. A portal may also contain additional information, such as the buffer's name or the result's index.

<img width="1043" alt="portal_screenshot" src="https://user-images.githubusercontent.com/2467016/222313082-8ae51576-5497-40e8-88d9-466ca504e22d.png">

## Portal Search

Lists are searched in Portal using a construct known as an [iterator](#iteration), in this case a functional-style iterator. Iterators support map and [filter](#filters) operations and a host of other [convenience methods](#iteration).

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
```

</details>

### Queries

To begin a search, list of (one or more) **[queries](#portalquery)** must be provided.
To specify _exactly_ what portals appear, users may create **queries** to pick and choose

### Iteration

**Iterable operations**

Operations which return a [lua-style](https://www.lua.org/pil/7.3.html) iterator.

- `Iterator.next(index?: number)`: stateless iterator
- `Iterator.iter()`: used in `for` loops, similar to `ipairs`

**Chainable operations**

Operations which return an iterator.

- `Iterator.start_at(n: integer)`
- `Iterator.reverse()`
- `Iterator.rrepeat(value: any)`
- `Iterator.skip(n: integer)`
- `Iterator.step_by(n: integer)`
- `Iterator.take(n: integer)`
- `Iterator.filter(f: fun(v: any): boolean)`
- `Iterator.map(f: fun(v: any, i: any): any | nil`: `nil` values are skipped

**Collect operations**

Operations which return a collection (list) of values.

- `Iterator.collect(): T[]`
- `Iterator.collect_table(): table`
- `Iterator.reduce(reducer: fun(acc, val, i): any, initial_state: any)`

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

## Portal Types

<details open>
<summary>Type Definitions</summary>

### `Portal.SearchOptions`

Options available for tuning a search query. See the [builtins](#builtins) section for information regarding search option defaults.

**Type**: `table`

- **`start`**: `integer`
- **`direction`**: [`Portal.Direction`](#portaldirection)
- **`max_results`**: `integer`
- **`filter`**: [`Portal.SearchPredicate`](#portalsearchpredicate)
- **`query`**: [`Portal.Query[]`](#portalsearchpredicate)

### `Portal.Direction`

Used for indicating whether a search should be performed forwards or backwards.

**Type**: `enum`

- **`"forward"`**
- **`"backward"`**

### `Portal.SearchPredicate`

Specialized [predicate](#portalpredicate) where the argument provided is a [`Portal.WindowContent`](#portalwindowcontent) result.

**Type**: `fun(c: Portal.WindowContent): boolean`

### `Portal.Query`

Named tuple of `(source, predicates)`.

**Type**: `table`

- **`source`**: [`Portal.Iterator`](#iteration)
- **`predicates`**: [`Portal.SearchPredicate[]`](#portalsearchpredicate) | `nil`


### `Portal.WindowContent`

Named tuple of `(buffer, cursor, select)` used in opening and selecting a portal location. **May contain** any additional data to aide in filtering, querying, and selecting a portal. See the [builtins](#builtins) section for information on which additional fields are present.

**Type**: `table`

- **`buffer`**: `integer`
- **`cursor`**: `{ row: integer, col: integer }`
- **`select`**: `fun(c: Portal.WindowContent)`
- **anything else**

### `Portal.Predicate`

Basic function type used for [filtering](#filters) and [querying](#queries) an iterator.

**Type**: `fun(v: any): boolean`

### `Portal.QueryGenerator`

**Type**: `fun(o: Portal.SearchOptions, s: Portal.Settings): Portal.Query`

### `Portal.Tunnel`

**Type**: `fun(o: Portal.SearchOptions)`

</details>
