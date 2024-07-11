-- Define supported file types
local js_based_languages = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' }

-- Function to load launch.json configurations
local function load_launch_json()
  local launch_json_path = vim.fn.findfile('.vscode/launch.json', '.;')
  if launch_json_path ~= '' then
    require('dap.ext.vscode').load_launchjs(launch_json_path, {
      ['pwa-node'] = js_based_languages,
      ['node'] = js_based_languages,
      ['chrome'] = js_based_languages,
      ['pwa-chrome'] = js_based_languages,
    })
  end
end

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    {
      'microsoft/vscode-js-debug',
      build = 'npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out',
    },
    {
      'mxsdev/nvim-dap-vscode-js',
      config = function()
        require('dap-vscode-js').setup {
          debugger_path = vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug',
          adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
        }
      end,
    },
    'Joakker/lua-json5',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- DAP UI setup
    dapui.setup()

    -- Configure DAP for JavaScript/TypeScript
    for _, language in ipairs(js_based_languages) do
      dap.configurations[language] = {
        -- Node.js debug configuration
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          resolveSourceMapLocations = {
            '${workspaceFolder}/**',
            '!**/node_modules/**',
          },
          outFiles = { '${workspaceFolder}/**/dist/**/*.js' },
        },
        -- Attach to running Node.js process
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
        },
        -- Debug web applications (client-side)
        {
          type = 'pwa-chrome',
          request = 'launch',
          name = 'Launch Chrome',
          url = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({ prompt = 'Enter URL: ', default = 'http://localhost:3000' }, function(url)
                if url and url ~= '' then
                  coroutine.resume(co, url)
                end
              end)
            end)
          end,
          webRoot = '${workspaceFolder}',
          sourceMaps = true,
          userDataDir = false,
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Vitest Tests (Monorepo)',
          runtimeExecutable = 'pnpm',
          runtimeArgs = function()
            local current_file = vim.fn.expand '%:p'
            local package_root = vim.fn.finddir('packages', current_file .. ';')
            if package_root ~= '' then
              local package_name = vim.fn.fnamemodify(vim.fn.expand(package_root .. '/..'), ':t')
              return {
                'vitest',
                '--inspect-brk', -- This enables the inspector
                '--no-coverage',
                '--testTimeout=100000',
                '--root',
                vim.fn.fnamemodify(package_root, ':h'),
                '--config',
                'packages/' .. package_name .. '/vitest.config.ts',
              }
            else
              return {
                'vitest',
                '--inspect-brk', -- This enables the inspector
                '--no-coverage',
                '--testTimeout=100000',
              }
            end
          end,
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
          internalConsoleOptions = 'neverOpen',
          protocol = 'inspector',
          sourceMaps = true,
          resolveSourceMapLocations = {
            '${workspaceFolder}/**',
            '!**/node_modules/**',
          },
        },
      }
    end

    dap.configurations.rust = {
      {
        name = 'Launch',
        type = 'rt_lldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
    }

    -- Load launch.json before starting debugging
    dap.listeners.before.launch.load_launch_json = load_launch_json

    -- Keymappings
    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Continue' })
    vim.keymap.set('n', '<leader>dsi', dap.step_into, { desc = 'Step Into' })
    vim.keymap.set('n', '<leader>dso', dap.step_over, { desc = 'Step Over' })
    vim.keymap.set('n', '<leader>dsu', dap.step_out, { desc = 'Step Out' })

    -- Auto open/close DAP UI
    dap.listeners.after.event_initialized['dapui_config'] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
      dapui.close()
    end

    local function terminate_debug_session()
      print 'Terminating debug session...'
      dap.terminate()
      dapui.close()
      vim.fn.jobstart 'pkill -f "node.*vitest"'
      print 'Debug session terminated.'
    end

    vim.keymap.set('n', '<leader>dq', terminate_debug_session, { desc = 'Terminate and Close' })
  end,
}
