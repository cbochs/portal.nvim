# Portal.nvim

![portal_showcase](https://user-images.githubusercontent.com/2467016/222644459-264e22e7-496a-4d4e-bfcb-e96efda0003d.gif)

Theme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)

## Introduction

> Look at you, sailing through [neovim] majestically, like an eagle... piloting a blimp.

Portal is a plugin that aims to build upon and enhance existing location lists (e.g. jumplist, changelist, quickfix list, etc.) and their associated motions (e.g. `<c-o>` and `<c-i>`) by presenting jump locations to the user in the form of [portals](#portals).

See the [quickstart](#quickstart) section to get started.

## Features

- **Labelled** [portals](#portals) for immediate movement to a portal location
- **Builtin** [queries](#builtin-queries) which can be filtered and refined
- **Composable** multiple lists can be used in a single search
- **Extensible** able to search any list with custom queries

## Requirements

- [Neovim >= 0.9](https://github.com/neovim/neovim/releases/tag/v0.9.0)

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
- Combine multiple queries using the [Portal API](#portal-api)

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
{ "cbochs/portal.nvim" }
```

</details>

<details>
<summary>packer</summary>

```lua
use { "cbochs/portal.nvim" }
```

</details>

<details>
<summary>vim-plug</summary>

```vim
Plug "cbochs/portal.nvim"
```

</details>

## Settings

The following are the default settings for Portal. **Setup is not required**, but settings may be overridden by passing them as table arguments to the `Portal.setup` function.

<details>
<summary>Default Settings</summary>

```lua
require("portal").setup({
    ---Ordered list of keys for labelling portals
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Select the first portal when there is only one result
    ---@type boolean
    select_first = false,

    ---The maximum number of results to return or a list of predicates to match
    ---or "fill". By default, uses the number of labels as a maximum number of
    ---results. See the Slots section for more information.
    ---@type Portal.Slots | nil
    slots = nil,

    ---The default filter to be applied to every search result.
    ---@type Portal.Predicate | nil
    filter = nil,

    ---The maximum number of results to consider when performing a Portal query
    ---@type integer
    lookback = 100,

    ---Window options for Portal windows
    ---@type vim.api.keyset.win_config
    win_opts = {
        width = 80,
        height = 3,

        relative = "cursor",
        col = 2,

        focusable = false,
        border = "single",
        style = "minimal",
        noautocmd = true,

        ---@type fun(c: Portal.Content): string | nil
        title = nil,

        title_pos = "center",
    },
})
```

</details>

## Usage

### Builtin Queries

<details>
<summary>Builtin Queries and Examples</summary>

Builin queries have a standard interface. Each builtin can be accessed via the `Portal` command or lua API.

**Overview**: the `tunnel` method provides the default entry point for using Portal for a location list; the `tunnel_forward` and `tunnel_backward` are convenience methods for easy keybinds; the `search` method returns the results of a query; and the `query` method builds a [query](#queries) for use in [`Portal.tunnel`](#portaltunnel) or [`Portal.search`](#portalsearch).

**Command**: `:Portal {builtin} [direction]`

**API**: `require("portal.builtin").{builtin}`

- `{builtin}.tunnel(opts)`: [`Portal.Options`](#portaloptions)
- `{builtin}.tunnel_backward(opts)`: [`Portal.Options`](#portaloptions)
- `{builtin}.tunnel_forward(opts)`: [`Portal.Options`](#portaloptions)
- `{builtin}.search(opts)`: [`Portal.SearchOptions`](#portalsearchoptions)
- `{builtin}.query(opts)`: [`Portal.QueryOptions`](#portalqueryoptions)
- `{builtin}.extension`: [`Portal.Extension`](#extensions)

---

#### `changelist`

Search Neovim's [`:h changelist`](https://neovim.io/doc/user/motion.html#changelist).

**Defaults**: [`Portal.QueryOptions`](#portalqueryoptions)

- **`start`**: current changelist index
- **`reverse`**: `true`

**Content**: [`Portal.Content`](#portalcontent)

- **`type`**: `"changelist"`
- **`buffer`**: `0`
- **`cursor`**: the changelist `{ lnum, col }`
- **`extra.reverse`**
- **`extra.dist`**
- **`:select()`**: uses `g;` or `g,`

<details>
<summary><b>Examples</b></summary>

```lua
-- Tunnel through the changelist
require("portal.builtin").changelist.tunnel()
```

</details>

#### `jumplist`

Search Neovim's [`:h jumplist`](https://neovim.io/doc/user/motion.html#jumplist).

**Defaults**: [`Portal.QueryOptions`](#portalqueryoptions)

- **`start`**: current jumplist index
- **`reverse`**: `true`

**Content**: [`Portal.Content`](#portalcontent)

- **`type`**: `"jumplist"`
- **`buffer`**: the jumplist `bufnr`
- **`cursor`**: the jumplist `{ lnum, col }`
- **`extra.reverse`**
- **`extra.dist`**
- **`:select()`**: uses `<c-o>` or `<c-i>`

<details>
<summary><b>Examples</b></summary>

```lua
-- Tunnel through the jumplist, skipping jumps in the current buffer
require("portal.builtin").jumplist.tunnel({
    filter = function(content)
        return content.buffer ~= vim.fn.bufnr()
    end
})
```

</details>

#### `quickfix`

Search Neovim's [`:h quickfix`](http://neovim.io/doc/user/quickfix.html) list.

**Defaults**: [`Portal.QueryOptions`](#portalqueryoptions)

- **`start`**: `1`
- **`reverse`**: `false`

**Content**: [`Portal.Content`](#portalcontent)

- **`type`**: `"quickfix"`
- **`buffer`**: the quickfix `bufnr`
- **`cursor`**: the quickfix `{ lnum, col }`
- **`:select()`**: uses `nvim_win_set_cursor`

<details>
<summary><b>Examples</b></summary>

```lua
-- Search the quickfix list
require("portal.builtin").quickfix.tunnel()
```

</details>

</details>

### Portal API

<details>
<summary>Portal API and Examples</summary>

#### `Portal.tunnel`

Search, open, and select a portal from a given query.

**API**: `require("portal").tunnel(queries, opts)`

**`queries`**: [`Portal.Query[]`](#queries)
**`opts`**: [`Portal.Options`](#portaloptions)

<details>
<summary><b>Examples</b></summary>

```lua
-- Use a builtin query
local query = require("portal.builtin").jumplist.query()
require("portal").tunnel(query)

-- Search the jumplist for one portal, search the quickfix list for the remaining
require("portal").tunnel({
    require("portal.builtin").jumplist.query({ limit = 1 })
    require("portal.builtin").quickfix.query(),
})
```

</details>

#### `Portal.search`

Complete a search for a given query and return the results.

**API**: `require("portal").search(queries, opts)`

**`queries`**: [`Portal.Query[]`](#queries)
**`opts?`**: [`Portal.SearchOptions`](#portalsearchoptions)

**`returns`**: [`portal.content[]`](#portalcontent)

<details>
<summary><b>Examples</b></summary>

```lua
-- Perform a search over both the jumplist and quickfix list
local results = require("portal").search({
    require("portal.builtin").jumplist.query()
    require("portal.builtin").quickfix.query(),
})

-- Select the first location from the list of results
results[1]:select()
```

</details>

#### `Portal.portals`

Create portals (windows) for a given set of search results. By default portals will not be open.

**API**: `require("portal").portals(queries, labels, win_opts)`

**`results`**: [`Portal.Content[]`](#portalcontent)
**`labels?`**: `string[]` (defaut: `settings.labels`)
**`win_opts?`**: [:h api-win_config](https://neovim.io/doc/user/api.html#api-win_config) (default: `settings.win_opts`)

**`returns`**: [`Portal.Window[]`](#portalwindow)

<details>
<summary><b>Examples</b></summary>

```lua
-- Return the results of a query over the jumplist and quickfix list
local query = require("portal.builtin").jumplist.query()
local results = require("portal").search(query)
local windows = require("portal").portals(results)

-- Open the portal windows
require("portal").open(windows)

-- Select the first location from the list of portal windows
windows[1]:select()

-- Close the portal windows
require("portal").close(windows)
```

</details>

#### `Portal.open`

Open a given list of portal (windows). Preferred over a for-loop as it forces a UI redraw.

**API**: `require("portal").open(windows)`

**`results`**: [`Portal.Window[]`](#portalwindow)

#### `Portal.close`

Close a given list of portal (windows). Preferred over a for-loop as it forces a UI redraw.

**API**: `require("portal").close(windows)`

**`results`**: [`Portal.Window[]`](#portalwindow)

</details>

## Portals

A **portal** is a labelled floating window showing a snippet of some buffer. The label indicates a key that can be used to navigate directly to the buffer location. A portal may also contain additional information, such as the buffer's name or the result's index.

<img width="1043" alt="portal_screenshot" src="https://user-images.githubusercontent.com/2467016/222313082-8ae51576-5497-40e8-88d9-466ca504e22d.png">

## Search

Each search begins with a [query](#queries) (or list of queries), and an optional set set of [search options](#portalsearchoptions) to use while performing the search. Once you h

The next stage after building a query is performing a search.

in building a query is specifying a set of options to refine your search results. This can be in the form of

During a search, a **filter** may be applied to remove any unwanted results from being displayed. More specifically, a filter is a [predicate](#portalpredicate) function which accepts some value and returns `true` or `false`, indicating whether that value should be kept or discarded.

<details>
<summary><b>Examples</b></summary>

```lua

-- Search for jumplist items in the same buffer
require("portal.builtin").jumplist.search({
    filter = function(v) return v.buffer == vim.fn.bufnr() end
})

-- Search for quickfix items which are in a modified buffer
require("portal.builtin").quickfix.search({
    filter = function(v) return vim.api.nvim_buf_get_option(v.buffer, "modified") end
})

-- Search
local queries = {
    require("portal.query").new(function() return { 1, 2, 3 } end),
    require("portal.query").new(function() return { 7, 8, 9 } end),
}
```

</details>

### Queries

A query is a relatively simple concept. It accepts a function that _generates_ results (some iterable) and returns an _iterator_ over those results. In fact, let's see just how that works:

```lua
local Query = require("portal.query")

Query.new(function() return { 0, 2, 4 })
    :prepare({ limit = 2 }) -- provide query options
    :search() -- create an iterator over the results
    :totable() -- collect the results
-- Returns { 0, 2 }
```

This can be extended to any kind of list, whether it be the [`:h jumplist`](https://neovim.io/doc/user/motion.html#jumplist) or some an external plugin (e.g. [grapple.nvim's](https://github.com/cbochs/grapple.nvim) tags). Every [builtin](#builtin-queries) provides the appropriate query which can be used in [`Portal.tunnel`](#portaltunnel) and [`Portal.search`](#portalsearch). In addition, all [extensions](#extensions) are expected to provide a generating function to build queries from.

**API**: `require("portal.query")`

- `Query.new(g: Portal.Generator, t?: Portal.Transformer): Portal.Query`
- `Query:prepare(opts?: Portal.QueryOptions): Portal.Query`
- `Query:search(): Portal.Iter`

Reference:

- [`Portal.Generator`](#portalgenerator)
- [`Portal.Transformer`](#portaltransformer)
- [`Portal.QueryOptions`](#portalqueryoptions)

<details>
<summary><b>Examples</b></summary>

```lua
-- Create a quickfix query
local query = require("portal.builtin").quickfix.query()

-- Search the jumplist for the last 4 jumps
require("portal.builtin").jumplist.query()
    :prepare({ limit = 4 })
    :search()
    :totable()
```

</details>

### Slots

<details>
<summary><b>Examples</b></summary>

```lua
-- Create search queries
local queries = {
    require("portal.query").new(function() return { 1, 2, 3 } end),
    require("portal.query").new(function() return { 7, 8, 9 } end),
}

-- Define slot
require("portal").search(queries, {
    slots = {
        function(v) return v > 1 end,
        function(v) return v > 5 end,
        function(v) return v > 8 end,
    }
})


-- Returns { 2, 7, 9 }
```

</details>

## Extensions

**API**: `require("portal.extension")`

- `Extension.register(e: Portal.Extension): Portal.Extension`

### `Portal.Extension`

**Type**: `table`

- **`name`**: `string`
- **`generate`**: [`Portal.Generator`](#portalgenerator)
- **`transform`**: [`Portal.Transformer`](#portaltransformer)
- **`select`**: `fun(c: Portal.Content)`

Reference:

- [`Portal.Content`](#portalcontent)

<details>
<summary><b>Examples</b></summary>

````lua
require("portal.extension").register({
    ---The name of the extension. Builtin methods will be created automatically
    ---when the extension is loaded by the user.
    ---
    ---```lua
    ---require("portal.builtin").buffers.tunnel()
    ---```
    ---
    ---@type string
    name = "buffers",

    ---Create a list of results and an (optional) set of default query options
    ---to apply.
    ---@return Portal.Result[], Portal.QueryOptions?
    generate = function()
        local buffers = vim.api.nvim_list_bufs()

        local defaults = {
            filter = function(content)
                return vim.api.nvim_buf_is_loaded(content.buffer)
            end
        }

        return buffers, defaults
    end,

    ---Transform a result into content which can be queries, previewed, and
    ---selected in Portal.
    ---@param index integer
    ---@param extended_result Portal.ExtendedResult
    ---@return Portal.Content?
    transform = function(index, extended_result)
        local buffer = extended_result.result
        local opts = extended_result.opts

        -- "type" is inferred from the extension's name
        return {
            buffer = buffer,
            cursor = vim.api.nvim_buf_get_mark(buffer, '"') or { 1, 0 }
        }
    end

    ---Given some content, it is up to the extension to provide the method of
    ---navigating to that content once selected by the user.
    ---@param content Portal.Content
    select = function(content)
        vim.api.nvim_win_set_buf(0, content.buffer)
    end
})
````

</details>

## Highlight Groups

A few highlight groups are available for customizing the look of Portal.

| Group          | Description                | Default       |
| -------------- | -------------------------- | ------------- |
| `PortalLabel`  | Portal label (extmark)     | `Search`      |
| `PoralTitle`   | Floating window title      | `FloatTitle`  |
| `PortalBorder` | Floating window border     | `FloatBorder` |
| `PortalNormal` | Floating window background | `NormalFloat` |

## Portal Types

<details open>
<summary>Type Definitions</summary>

### `Portal.Options`

<!-- TODO: explain -->

**Type**: `table`

- **`labels?`**: `string[]` (default: `settings.labels`)
- **`select_first?`**: `boolean` (default: `settings.select_first`)
- **`win_opts?`**: `boolean` (default: `settings.win_opts`)
- **`search?`**: [`Portal.SearchOptions`](#portalsearchoptions)

### `Portal.SearchOptions`

<!-- TODO: explain -->

**Type**: `table`

- **`slots?`**: [`Portal.Predicate[]`](#portalpredicate) (default: `#settings.slots`)
- Extends [`Portal.QueryOptions`](#portalqueryoptions)

### `Portal.QueryOptions`

<!-- TODO: explain -->

**Type**: `table`

- **`start?`**: `integer` the abolute starting position (default: `1`)
- **`skip?`**: `integer` (default: `0`)
- **`reverse?`**: `boolean` (default: `false`)
- **`lookback?`**: `integer` (default: `settings.lookback`)
- **`limit?`**: `integer` (default: `#settings.labels`)
- **`filter?`**: [`Portal.Predicate`](#portalpredicate) (default: `#settings.filter`)

### `Portal.Predicate`

<!-- TODO: explain -->

**Type**: `fun(c: Portal.Content): boolean`

Reference:

- [`Portal.Content`](#portalcontent)

### `Portal.Content`

<!-- TODO: explain -->

**Type**: `table`

- **`type`**: `string`
- **`buffer?`**: `integer`
- **`path?`**: `string`
- **`cursor`**: `{ row: integer, col: integer }`
- **`select`**: `fun(c: Portal.Content)`
- **`extra`**: `table`

### `Portal.Window`

A window for some [`Portal.Content`](#portalcontent).

**Type**: `object`

- **`:select()`**
- **`:open()`**
- **`:close()`**

### `Portal.Iterable`

**Type**: `table` | `function` | [`Portal.Iter`](#portaliter)

### `Portal.Generator`

Generates an iterable which can be consumed by a [`Portal.Query`](#queries). See the [Extensions](#extensions) section for more information.

**Type**: `fun(): Portal.Iterable, Portal.QueryOptions?`

Reference:

- [`Portal.Iterable`](#portaliterable)
- [`Portal.QueryOptions`](#portalqueryoptions)

### `Portal.Transformer`

Transforms an enumerated (and extended) result into a [`Portal.Content`](#portalcontent). See the [Extensions](#extensions) section for more information.

**Type**: `fun(i: integer, r: Portal.ExtendedResult): Portal.Content?`

Reference:

- `Portal.ExtendedResult`: [`Portal.ExtendedResult`](#portalextendedresult)
- [`Portal.Content`](#portalcontent)

### `Portal.ExtendedResult`

**Type**: `table`

- **`result`**: `Portal.Result`
- **`opts`**: [`Portal.QueryOptions`](#portalqueryoptions)

Reference:

- `Portal.Result`: `any`
- [`Portal.Content`](#portalcontent)

</details>
