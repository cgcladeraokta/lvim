local dap_ok, dap = pcall(require, "dap")
local dap_vscode_js_ok = pcall(require, "dap-vscode-js")

if not dap_ok then
  return
end

local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")

if dap_vscode_js_ok then
  require("dap-vscode-js").setup {
    debugger_path = mason_path .. "packages/js-debug-adapter",                                   -- Path to vscode-js-debug installation.
    adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
  }

  local function resolve_nx_jest_config()
    return vim.fn.findfile("jest.config.ts", ".;")
  end

  local function resolve_nx_jest_args()
    return { "${fileBasenameNoExtension}", '--config', resolve_nx_jest_config(), "--runInBand" }
  end

  local function resolve_jest_program()
    return vim.fn.getcwd() .. "/node_modules/.bin/jest"
  end

  local function resolve_mocha_config()
    return vim.fn.findfile(".mocharc.js", ".;")
  end

  local function get_mocha_grep()
    local grep = nil
    local node = vim.treesitter.get_node()
    local maxAppends = 4

    while node do
      if node:type() == "call_expression" then
        local fn = vim.treesitter.get_node_text(node:child(0), 0)
        if fn == "it" or fn == "describe" then
          local arguments = node:child(1)
          local spec = vim.treesitter.get_node_text(arguments:child(1):child(1), 0)
          if grep == nil then
            grep = spec
          else
            grep = spec .. " " .. grep
          end
          maxAppends = maxAppends - 1
          if maxAppends == 0 then
            break
          end
        end
      end
      node = node:parent()
    end
    return grep
  end

  local function resolve_mocha_args()
    local args = { "--config", resolve_mocha_config(), "--timeouts", "9999999" }
    local grep = get_mocha_grep()

    if grep ~= nil then
      table.insert(args, "--grep")
      table.insert(args, "\"" .. grep .. "\"")
    end
    return args
  end

  local function resolve_mocha_program()
    return vim.fn.getcwd() .. "/node_modules/.bin/_mocha"
  end


  for _, language in ipairs { "typescript", "javascript", "typescriptreact" } do
    require("dap").configurations[language] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Mocha Current Tests",
        runtimeExecutable = resolve_mocha_program,
        runtimeArgs = resolve_mocha_args,
        rootPath = "${workspaceFolder}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Jest Tests",
        -- trace = true, -- include debugger info
        runtimeExecutable = "node",
        runtimeArgs = {
          "./node_modules/jest/bin/jest.js",
          "--runInBand",
        },
        rootPath = "${workspaceFolder}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "NX: Jest current file",
        runtimeExecutable = resolve_jest_program,
        runtimeArgs = resolve_nx_jest_args,
        rootPath = "${workspaceFolder}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Node.js Attach (5860)",
        processId = require 'dap.utils'.pick_process,
        port = 5860,
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Node.js Attach (5858)",
        processId = require 'dap.utils'.pick_process,
        port = 5858,
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Node.js Attach (9229)",
        processId = require 'dap.utils'.pick_process,
        port = 9229,
        cwd = "${workspaceFolder}",
      },
    }
  end
end

-- if mason_ok and mason.is_installed("node-debug2-adapter") then
--   dap.adapters.node2 = {
--     type = 'executable',
--     command = 'node',
--     args = { vim.fn.stdpath("data") .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
--   }

--   local function resolve_nx_jest_config()
--     local currentBufferPath = vim.fn.fnamemodify(vim.fn.expand("%"), ":h")
--     local sourcePathPos = vim.fn.stridx(currentBufferPath, "/src")
--     if sourcePathPos < 0 then
--       sourcePathPos = vim.fn.stridx(currentBufferPath, "/tests")
--     end
--     local projectRoot = vim.fn.strpart(currentBufferPath, 0, sourcePathPos)

--     return projectRoot .. "/jest.config.ts"
--   end

--   local function resolve_nx_jest_args()
--     return { "${fileBasenameNoExtension}", '--config', resolve_nx_jest_config() }
--   end

--   local function resolve_jest_program()
--     return vim.fn.getcwd() .. "/node_modules/.bin/jest"
--   end

--   dap.configurations.typescript = {
--     {
--       type = "node2",
--       name = "NX: Jest current file",
--       request = "launch",
--       program = resolve_jest_program,
--       args = resolve_nx_jest_args,
--       cwd = vim.fn.getcwd,
--       console = 'integratedTerminal'
--     }
--   }

--   dap.configurations.typescriptreact = {
--     {
--       type = "node2",
--       name = "NX: Jest current file",
--       request = "launch",
--       program = resolve_jest_program,
--       args = resolve_nx_jest_args,
--       cwd = vim.fn.getcwd,
--       console = 'integratedTerminal'
--     }
--   }
-- end

function resolve_main_class()
  local currentBuffer = vim.fn.fnamemodify(vim.fn.expand("%"), ":r")
  local packageAnchor = "main/java/"
  local packageStart = vim.fn.strridx(currentBuffer, packageAnchor) + vim.fn.strlen(packageAnchor)
  local packagePath = vim.fn.strpart(currentBuffer, packageStart)

  return string.gsub(packagePath, "/", ".")
end

local jdtls_ok, jdtls = pcall(require, "jdtls")

if jdtls_ok and jdtls.dap_ok then
  jdtls.dap.setup_dap_main_class_configs();
end

dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Java Attach",
    hostName = "localhost",
    port = 5005,
  },
  {
    type = "java",
    request = "launch",
    name = "Java: Dropwizard Server",
    mainClass = resolve_main_class,
    args = "server"
  },
  {
    type = "java",
    request = "launch",
    name = "Java: Spring",
    mainClass = resolve_main_class,
  },
}

-- require('dap.ext.vscode').load_launchjs(vim.fn.getcwd() .. "/.vscode/launch.json", {
--   node2 = { 'javascript', 'typescript', 'typescriptreact' }
-- })


-- Go --
local dapgo_ok, dapgo = pcall(require, "dap-go")

if dapgo_ok then
  dapgo.setup()
end
