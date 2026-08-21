-- LSP — Neovim 0.12 내장 방식
--
-- nvim-lspconfig 플러그인이 없다. 0.11 부터 `vim.lsp.config` / `vim.lsp.enable` 이
-- 코어에 들어왔고, 서버별 설정은 runtimepath 의 `lsp/<name>.lua` 에서 자동으로 읽힌다.
-- → 이 설정의 서버 정의는 ~/.config/nvim/lsp/*.lua 에 있다.

-- capabilities 는 손대지 않는다. 0.12 기본값이 이미 snippetSupport·resolveSupport 를
-- 포함하고, 완성은 vim.lsp.completion(내장)이 처리한다.

vim.lsp.enable({
  "lua_ls", -- Lua (Neovim 플러그인 작성)
  "markdown_oxide", -- 마크다운 PKM: [[링크]] 완성 · 백링크 · 데일리 노트 · 태그
  -- Swift / Objective-C. Xcode·Swift 툴체인이 없는 기기에서는 cmd 가 없어
  -- Neovim 이 알림 없이 건너뛴다(실측) — 그대로 둬도 다른 기기가 안 깨진다.
  "sourcekit",
  -- 비활성. 켜는 법은 lsp/harper_ls.lua 상단 참고.
  -- "harper_ls",   -- 영문 문법/맞춤법 (한국어 미지원)
})

-- 서버가 붙었을 때만 걸리는 키맵
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(ev)
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
    end

    -- grn(이름) · gra(코드액션) · K(호버) · gri · grt 는 0.12 코어 기본이라 여기 없다.
    -- 아래는 코어 기본을 fzf 픽커로 바꾸거나(grr·gO), 코어에 없는 것(gd·gW)뿐이다.
    local fzf = require("fzf-lua")
    map("grr", fzf.lsp_references, "참조 찾기(마크다운=백링크)")
    map("gd", fzf.lsp_definitions, "정의로 이동")
    map("gO", fzf.lsp_document_symbols, "문서 심볼(마크다운=목차)")
    -- 볼트 전체의 노트·헤딩·태그를 한 목록으로 (markdown_oxide 가 제공)
    map("gW", fzf.lsp_live_workspace_symbols, "워크스페이스 심볼")

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- 내장 자동완성에 LSP 를 소스로 물린다.
    -- enable() 이 omnifunc 를 설정하므로, 'complete' 에 "o" 를 더하면
    -- 버퍼 단어와 LSP 후보가 한 팝업에 섞인다.
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      vim.bo[ev.buf].complete = ".^5,w^5,b^5,o"
    end

    -- Lua 작성 중엔 인레이 힌트가 유용, 산문에선 방해
    if client:supports_method("textDocument/inlayHint") and vim.bo[ev.buf].filetype == "lua" then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})

vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})
