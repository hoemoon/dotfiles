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
  -- org 는 orgmode 플러그인이 in-process 로 띄운다(서버 정의 = 플러그인의 lsp/org.lua).
  -- 실측 capabilities: completion · documentSymbol · workspaceSymbol · references.
  -- 아래 LspAttach 가 그대로 걸려서 완성('complete' 에 o 추가)이 공짜로 붙는다.
  "org",
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

    -- 인레이 힌트. Lua = 타입 힌트. 마크다운 = **블록 트랜스클루전** —
    -- markdown_oxide 가 `![[링크]]` 자리에 그 블록의 실제 내용을 펼쳐 준다
    -- (서버 설정 block_transclusion, 기본 on). 예전엔 이 조건이 lua 로만
    -- 좁혀져 있어서 마크다운에선 한 번도 뜬 적이 없었다. 산문에서 시끄러우면
    -- .moxide.toml 에 block_transclusion_length = "Partial" 을 준다.
    if client:supports_method("textDocument/inlayHint") then
      local ft = vim.bo[ev.buf].filetype
      if ft == "lua" or ft == "markdown" then
        vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      end
    end

    -- 코드 렌즈. markdown_oxide 는 파일 제목 위에 "N references to file", 헤딩
    -- 마다 "N references" 를 띄운다 — 볼트에서 무엇이 실제로 중심인지가 편집
    -- 중에 그대로 보인다.
    --
    -- 갱신 autocmd 를 직접 걸지 않는다. 0.12 의 codelens.enable 은 inlay hint
    -- 와 같은 _capability 기구를 타서 문서 변경마다 알아서 다시 받아온다.
    -- (예전 관례인 codelens.refresh({bufnr=…}) 는 0.13 에서 없어진다.)
    if client:supports_method("textDocument/codeLens") then
      vim.lsp.codelens.enable(true, { bufnr = ev.buf })
    end

    -- 접기 — **파서가 없는 파일타입에서만** LSP 로 받는다.
    --
    -- :h vim.lsp.foldexpr 의 예시는 foldingRange 를 지원하는 모든 서버에 LSP 를
    -- 우선하라고 하지만, 그대로 쓰면 이 설정에선 Lua 접기가 죽는다. lua_ls 는
    -- foldingRangeProvider=true 라고 광고해 놓고 실제로는 범위를 0 개 준다
    -- (실측 2026-08-25, keymaps.lua 129줄: treesitter 13 개 vs lua_ls 0 개).
    -- 에러 없이 조용히 사라지는 종류의 퇴행이라 화이트리스트로 좁힌다.
    -- sourcekit 은 반대로 잘 준다 — 실측 324줄에서 48 개, struct/func/if 중첩까지.
    local FOLD_VIA_LSP = { swift = true, objc = true, objcpp = true }
    if FOLD_VIA_LSP[vim.bo[ev.buf].filetype] and client:supports_method("textDocument/foldingRange") then
      -- [win][0] = "이 창에서 이 버퍼일 때만". 그냥 vim.wo 면 같은 창에 연
      -- 다음 파일에도 남는다.
      local win = vim.api.nvim_get_current_win()
      -- foldmethod 도 같이 되돌린다. after/ftplugin/swift.lua 가 LSP 부착
      -- **전에** foldmethod=indent 폴백을 걸어두므로, foldexpr 만 바꾸면
      -- 그 식이 아예 평가되지 않는다(실측으로 밟았다 — 들여쓰기 fold 가
      -- LSP fold 인 척 보였다).
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      -- foldtext 는 건드리지 않는다. vim.lsp.foldtext() 는 서버가 준
      -- collapsedText 를 보여주는 게 값어치인데 sourcekit 은 그걸 안 준다
      -- (실측: 48 개 범위 전부 collapsedText 없음). 그러면 "첫 줄 표시"로
      -- 폴백하는데, 내용은 options.lua 의 foldtext="" 와 같으면서 문법
      -- 강조만 잃는다 — 순손실이다.
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
