return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-jest',
  },
  config = function()
    local neotest = require 'neotest'
    local neotest_jest = require 'neotest-jest'

    neotest.setup {
      adapters = {
        neotest_jest {
          jestCommand = function(file)
            local package_root = string.match(file, '(.-/packages/[^/]+/)')
            if package_root then
              local package_json_path = package_root .. 'package.json'
              if vim.fn.filereadable(package_json_path) == 1 then
                local package_json_content = vim.fn.readfile(package_json_path)
                local package_json = vim.fn.json_decode(table.concat(package_json_content, '\n'))
                if package_json and package_json.scripts and package_json.scripts.test then
                  return 'pnpm --filter ' .. vim.fn.fnamemodify(package_root, ':h:t') .. ' test --'
                end
              end
            end
            return 'pnpm test --'
          end,
          jestConfigFile = function(file)
            local package_root = string.match(file, '(.-/packages/[^/]+/)')
            if package_root then
              local config_path = package_root .. 'jest.config.ts'
              if vim.fn.filereadable(config_path) == 1 then
                return config_path
              end
            end
            return vim.fn.getcwd() .. '/jest.config.ts'
          end,
          cwd = function(file)
            if string.find(file, '/packages/') then
              return string.match(file, '(.-/[^/]+/)src')
            end
            return vim.fn.getcwd()
          end,
        },
      },
      -- Minimal required fields
      log_level = vim.log.levels.WARN,
      status = { virtual_text = true },
      output = { open_on_run = true },
    }

    vim.keymap.set('n', '<leader>to', function()
      neotest.output_panel.toggle()
    end)
    vim.keymap.set('n', '<leader>tf', function()
      neotest.run.run(vim.fn.expand '%')
    end)
    vim.keymap.set('n', '<leader>tc', function()
      neotest.run.run()
    end)
    vim.keymap.set('n', '<leader>ts', function()
      neotest.summary.toggle()
    end)

    -- NEOTEST + DAP
    vim.keymap.set('n', '<leader>tdc', function()
      neotest.run.run { strategy = 'dap' }
    end)
    vim.keymap.set('n', '<leader>tdf', function()
      neotest.run.run { vim.fn.expand '%', strategy = 'dap' }
    end)
  end,
  opts = function(_, opts)
    opts.adapters = opts.adapters or {}
    table.insert(opts.adapters, require 'rustaceanvim.neotest')
  end,
}
