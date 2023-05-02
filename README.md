# htmlgui.nvim

Create html + css + lua apps with neovim as 'browser'.

## So many possibilities

- inbuilt debugger
- hyperlinks with href
- element definitions and defaults
- highlights instead of background/foreground using treesitter
- help with ? per element, global
- tabbing with treesitter elements

## So many details

- debugger toggle
- no script / style case
- zoom is fucked when on floats, needs to be disabled/handled there
- css preference order

## Concepts

- dom - html
- style - css
- script - lua
- browser - neovim
- engine - htmlgui.app
- elements - htmlgui.html

## Core modules

### init

Calls `app.setup(config)`.

### app

Module to store state and transitions of htmlgui.

- `config`
- `info`
- `state.dom` - 
- `state.gui` - 
- `state.css` - 
- `state.lua` - 
- `state.data` - store of html elements in body in our format (data)
- `script` - reload on `set_keymaps`
- `style` - reload on rendesr

### layout

- `data`
- `element`

### ts_css

### ts_html

### html

### utils
