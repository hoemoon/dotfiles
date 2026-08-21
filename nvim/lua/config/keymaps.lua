local map = vim.keymap.set

-- ------------------------------------------------------------- 기본
map("n", "<leader>w", "<cmd>write<CR>", { desc = "저장" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "닫기" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "검색 강조 끄기" })

-- 검색 결과가 항상 화면 중앙에 오게
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- 비주얼 모드에서 블록 이동
map("x", "J", ":m '>+1<CR>gv=gv", { desc = "선택 영역 아래로", silent = true })
map("x", "K", ":m '<-2<CR>gv=gv", { desc = "선택 영역 위로", silent = true })

-- ------------------------------------------------------------- 토글
-- 표시 상태를 뒤집는 것은 전부 여기로 모은다.
--
-- 다른 접두사(f=찾기 · h=git hunk · p=플러그인)는 "무엇에 대한" 명사 축인데
-- 토글만 동사 축이다. 섞어두면 "blame 토글은 h 인가 t 인가" 를 매번 다시 묻게
-- 돼서, 동사 축 하나를 따로 판다. gitsigns 의 blame 토글도 여기 규약을 따라
-- <leader>tb 로 두었다(정의는 plugins.lua 의 on_attach — 버퍼 로컬이라 옮길 수 없다).
--
-- 산문(마크다운)과 코드를 같은 설정으로 쓰다 보니 conceallevel · wrap ·
-- 진단 virtual_text · inlay hint 가 앞으로 이 축에 붙을 후보다.

-- 절대 번호가 기본(options.lua). 세어 움직여야 할 때만 상대로 뒤집는다.
map("n", "<leader>tl", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "상대/절대 줄 번호" })

-- ----------------------------------------------------------- 찾기
local t = require("fzf-lua")
map("n", "<leader>ff", t.files, { desc = "파일 찾기" })
map("n", "<leader>fg", t.live_grep, { desc = "내용 검색" })
map("n", "<leader>fb", t.buffers, { desc = "버퍼" })
map("n", "<leader>fr", t.oldfiles, { desc = "최근 파일" })
map("n", "<leader>fh", t.helptags, { desc = "도움말" })
map("n", "<leader>fs", t.grep_cword, { desc = "커서 아래 단어 검색" })
map("n", "<leader>fd", t.diagnostics_document, { desc = "진단 목록" })
map("n", "<leader>fk", t.keymaps, { desc = "키맵 찾기" })
map("n", "<leader>fz", t.resume, { desc = "직전 검색 이어서" })
-- 현재 파일 안에서 찾기 (긴 노트에서 유용)
map("n", "<leader>/", t.blines, { desc = "이 문서 안에서 찾기" })

-- ------------------------------------------------------------- 노트
-- [[링크]] 완성 · 백링크 · 데일리 노트는 markdown_oxide LSP 가 제공한다.
-- 여기 있는 건 "노트 폴더로 가는 길" 뿐이다.
--
-- ★ 노트 워크플로를 잠시 꺼둔다 (2026-08-21). true 로 되돌리면 그대로 살아난다.
--   끄면 <leader>n* 다섯 자리가 통째로 빈다.
local NOTES_ENABLED = false

if NOTES_ENABLED then
  -- 노트 루트는 .moxide.toml 로 표시돼 있어 LSP 는 경로를 몰라도 되지만,
  -- 검색은 시작 지점이 필요해서 이 상수 하나만 둔다.
  local NOTES = vim.env.HOME .. "/workspace/notes"

  map("n", "<leader>nf", function()
    t.files({ cwd = NOTES, winopts = { title = " 노트 파일 " } })
  end, { desc = "노트 파일 찾기" })

  map("n", "<leader>ng", function()
    t.live_grep({ cwd = NOTES, winopts = { title = " 노트 검색 " } })
  end, { desc = "노트 내용 검색" })

  -- 새 노트: 이름만 받고 연다. 첫 저장 전까지 파일은 만들어지지 않는다.
  map("n", "<leader>nn", function()
    vim.ui.input({ prompt = "새 노트: " }, function(name)
      if not name or vim.trim(name) == "" then
        return
      end
      name = vim.trim(name):gsub("[/:]", "-")
      vim.cmd.edit(vim.fn.fnameescape(NOTES .. "/" .. name .. ".md"))
    end)
  end, { desc = "새 노트" })

  -- 데일리 노트 — markdown_oxide 가 버퍼에 등록하는 명령이라
  -- 마크다운 버퍼에서만 동작한다. 아무 데서나 쓰려면 노트를 먼저 연다.
  map("n", "<leader>nt", "<cmd>LspToday<CR>", { desc = "오늘 노트" })
  map("n", "<leader>ny", "<cmd>LspYesterday<CR>", { desc = "어제 노트" })
end

-- --------------------------------------------------------- 글쓰기
map("n", "<leader>z", "<cmd>ZenMode<CR>", { desc = "집중 모드" })
map("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "포맷" })

-- ------------------------------------------------------------ 관리
map("n", "<leader>pu", function()
  vim.pack.update()
end, { desc = "플러그인 업데이트" })
map("n", "<leader>ps", function()
  vim.pack.update(nil, { offline = true })
end, { desc = "플러그인 목록/상태" })
