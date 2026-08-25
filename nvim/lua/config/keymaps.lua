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
-- 진단 virtual_text 가 앞으로 이 축에 붙을 후보다.

-- 절대 번호가 기본(options.lua). 세어 움직여야 할 때만 상대로 뒤집는다.
map("n", "<leader>tl", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "상대/절대 줄 번호" })

-- 인레이 힌트. 마크다운에선 `![[링크]]` 임베드의 내용이 제자리에 펼쳐진다
-- (markdown_oxide 의 block_transclusion). 원문만 보고 싶을 때 끈다.
map("n", "<leader>ti", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "인레이 힌트" })

-- 개요 보기 — 최상위 구조만 남기고 접는다. 마크다운은 `##` 절 목록, Swift 는
-- 함수 시그니처 목록이 된다. foldlevel 은 창-로컬이라 분할 창마다 따로 논다.
--
-- 목표가 2 가 아니라 1 인 이유가 둘 있다. ① 레벨 1 이 양쪽 다 "개요"에 맞는다
-- (2 는 마크다운=코드블록 · Swift=함수 안 블록이라 훑기용이 아니다). ② 마크다운
-- 레벨 2 는 실제로 못 쓴다 — render-markdown 이 ``` 펜스를 conceal 해서 접힌
-- 코드블록이 **빈 줄**로 보이고 여백의 + 마커도 안 뜬다(실측). 코드블록을 접고
-- 싶으면 <leader>tr 로 렌더를 끈 뒤 :set foldlevel=2 를 쓴다.
map("n", "<leader>tf", function()
  vim.wo.foldlevel = vim.wo.foldlevel > 1 and 1 or 99
end, { desc = "개요 보기 (접기 토글)" })

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
-- 여기 남긴 셋은 **코어에도 LSP 에도 대응물이 없는 것**뿐이다 — 찾기·검색·만들기.
--
-- 2026-08-21 에 <leader>n* 다섯을 통째로 껐다가, 그날의 기준("코어가 이미
-- 하는 걸 중복 정의하지 않는다")을 끝까지 적용해 셋만 되살린다.
--   · nt/ny 는 버렸다 — :LspToday 의 순수한 중복이고, 지금은 :Daily(자연어)와
--     셸의 zd 가 더 넓게 덮는다.
--   · nf/ng 는 중복이 아니다. <leader>ff·fg 는 cwd 기준이라 노트에 닿지 않고,
--     gW(워크스페이스 심볼)는 markdown_oxide 가 붙은 버퍼에서만 동작한다
--     (workspace_required). 노트 저장소 **밖에서 안으로 들어가는 유일한 문**이다.
local NOTES = vim.env.HOME .. "/workspace/notes"

map("n", "<leader>nf", function()
  t.files({ cwd = NOTES, winopts = { title = " 노트 파일 " } })
end, { desc = "노트 파일 찾기" })

map("n", "<leader>ng", function()
  t.live_grep({ cwd = NOTES, winopts = { title = " 노트 검색 " } })
end, { desc = "노트 내용 검색" })

-- 새 노트 — inbox 에 만들고, 오늘 데일리 노트에 [[이름]] 을 걸어 둔다.
--
-- inbox 인 이유 = .moxide.toml 의 new_file_folder_path 와 같은 규칙이다.
-- 루트에 만들면 저장하는 순간 launchd(com.paju.notes-site)가 감지해서 초안이
-- tailnet 위키(:8110)로 발행된다. gra 코드 액션은 이미 inbox 로 보내고 있어서,
-- 여기만 루트로 두면 같은 구멍이 옆에 하나 더 열린 셈이 된다.
--
-- 데일리에 먼저 거는 이유 = 고아 노트 방지. inbox 에 쌓이는데 아무 데서도
-- 도달할 수 없는 노트가 이 방식이 죽는 가장 흔한 경로다. 하루치 데일리가 그날
-- 만든 노트의 목차가 되면 grr·코드 렌즈가 셀 것이 생긴다. 파일보다 링크를
-- **먼저** 쓴다 — 생성이 실패해도 흔적은 남는 쪽이 낫다.
-- (이 설정에서 유일하게 다른 파일을 조용히 건드리는 동작이다. 거슬리면 아래
--  `if fresh then ... end` 블록만 지우면 나머지는 그대로 돈다.)
map("n", "<leader>nn", function()
  vim.ui.input({ prompt = "새 노트: " }, function(name)
    if not name or vim.trim(name) == "" then
      return
    end
    name = vim.trim(name):gsub("[/:]", "-")
    local path = ("%s/inbox/%s.md"):format(NOTES, name)
    -- 이미 있는 노트를 다시 열 때는 링크를 또 달지 않는다
    local fresh = vim.fn.filereadable(path) == 0

    if fresh then
      local daily = ("%s/daily/%s.md"):format(NOTES, os.date("%Y-%m-%d"))
      vim.fn.mkdir(vim.fs.dirname(daily), "p")
      local lines = vim.fn.filereadable(daily) == 1 and vim.fn.readfile(daily) or {}
      if #lines == 0 then
        lines = { "# " .. os.date("%Y-%m-%d"), "" }
      end
      table.insert(lines, ("[[%s]]"):format(name))
      vim.fn.writefile(lines, daily)
    end

    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.cmd.edit(vim.fn.fnameescape(path))
    if fresh then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. name, "" })
      vim.cmd("normal! G")
      vim.cmd.startinsert()
    end
  end)
end, { desc = "새 노트" })

-- --------------------------------------------------------- 글쓰기
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
