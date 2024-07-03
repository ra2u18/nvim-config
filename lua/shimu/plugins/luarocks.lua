return {
  'vhyrro/luarocks.nvim',
  priority = 100,
  config = true,
  opts = {
    rocks = { 'lua-curl', 'nvim-nio', 'mimetypes', 'xml2lua' }, -- Specify LuaRocks packages to install
  },
}
