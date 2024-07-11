-- local log = require 'vim.lsp.log'

-- local function debug_print(message)
--   vim.notify('[NEOTEST-DEBUG] ' .. message, vim.log.levels.INFO)
-- end

local log_file = io.open(vim.fn.stdpath 'cache' .. '/neotest_debug.log', 'a')

local function debug_print(message)
  if log_file then
    log_file:write(os.date '%Y-%m-%d %H:%M:%S ' .. message .. '\n')
    log_file:flush()
  end
  vim.notify('[NEOTEST-DEBUG] ' .. message, vim.log.levels.INFO)
end

local function read_package_json(path)
  if vim.fn.filereadable(path) == 1 then
    local content = vim.fn.readfile(path)
    return vim.fn.json_decode(table.concat(content, '\n'))
  end
  return nil
end

local function create_vitest_adapter()
  return require 'neotest-vitest' {
    vitestCommand = 'pnpm vitest',
    env = {
      CI = nil,
    },
    cwd = function(path)
      -- Find the closest package.json
      local package_json = vim.fn.findfile('package.json', path .. ';')
      if package_json ~= '' then
        return vim.fn.fnamemodify(package_json, ':h')
      end
      return vim.fn.getcwd()
    end,
    filter_dir = function(name, rel_path, root)
      -- Exclude common directories we don't want to search
      if name == 'node_modules' or name == 'dist' or name == '.git' then
        return false
      end

      -- Check if we're in the packages directory
      if vim.fn.fnamemodify(rel_path, ':h') == 'packages' then
        -- Only allow directories that are direct children of 'packages'
        return vim.fn.isdirectory(root .. '/' .. rel_path) == 1
      end

      -- Allow searching in 'src' and '__tests__' directories within packages
      local in_package = string.match(rel_path, '^packages/[^/]+/')
      if in_package then
        return name == 'src' or name == '__tests__'
      end

      -- For other cases, allow the directory
      return true
    end,
    -- Add any other Vitest-specific options here
  }
end

local function create_jest_adapter()
  return require 'neotest-jest' {
    jestCommand = 'pnpm test --',
    jestConfigFile = function(file)
      debug_print('Looking for Jest config for file: ' .. file)
      local package_root = string.match(file, '(.-/packages/[^/]+/)')
      if package_root then
        local config_path = package_root .. 'jest.config.ts'
        debug_print('Checking for Jest config at: ' .. config_path)
        if vim.fn.filereadable(config_path) == 1 then
          debug_print('Found Jest config at: ' .. config_path)
          return config_path
        end
      end
      debug_print 'No Jest config found'
    end,
    cwd = function(file)
      debug_print('Determining CWD for file: ' .. file)
      if string.find(file, '/packages/') then
        local cwd = string.match(file, '(.-/packages/[^/]+/)')
        if cwd then
          debug_print('CWD set to: ' .. cwd)
          return cwd
        end
      end
      local default_cwd = vim.fn.getcwd()
      debug_print('Falling back to default CWD: ' .. default_cwd)
      return default_cwd
    end,
  }
end

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-jest',
    'mrcjkb/rustaceanvim',
    'marilari88/neotest-vitest',
  },
  config = function()
    local status_neotest, neotest = pcall(require, 'neotest')
    if not status_neotest then
      vim.notify('Failed to load neotest', vim.log.levels.ERROR)
      return
    end

    local adapters = { create_vitest_adapter() }

    -- Safely try to add Rustaceanvim adapter
    local status_rust, rust_adapter = pcall(require, 'rustaceanvim.neotest')
    if status_rust then
      table.insert(adapters, rust_adapter)
    else
      vim.notify('Failed to load Rustaceanvim neotest adapter', vim.log.levels.WARN)
    end

    neotest.setup {
      adapters = adapters,
      status = { virtual_text = true },
      output = { open_on_run = true },
      -- Enable verbose logging
      log_level = vim.log.levels.DEBUG,
      on_error = function(error)
        debug_print('NEOTEST ERROR', tostring(error))
      end,
    }

    -- Key mappings
    vim.keymap.set('n', '<leader>to', function()
      neotest.output_panel.toggle()
    end)
    vim.keymap.set('n', '<leader>tf', function()
      neotest.run.run(vim.fn.expand '%')
    end)
    vim.keymap.set('n', '<leader>ts', function()
      neotest.summary.toggle()
    end)
    -- Modify the F3 keybinding to use our custom function
    vim.keymap.set('n', '<F3>', function()
      print 'Starting debug session...'
      neotest.run.run { strategy = 'dap' }
    end, { desc = 'Debug Nearest test' })
  end,
}
