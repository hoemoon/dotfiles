local o = vim.o

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- 화면
o.number = true
-- 절대 번호가 기본. LSP 진단·git blame·남이 알려준 "42번 줄" 이 화면과 그대로 맞는다.
-- d5j 처럼 세어 움직여야 할 때만 <leader>tl 로 상대 번호를 켠다(창 단위).
o.relativenumber = false
o.cursorline = true
o.signcolumn = "yes"
o.termguicolors = true
o.scrolloff = 5
o.splitright = true
o.splitbelow = true
o.winborder = "rounded" -- 0.12: 떠있는 창 전부에 테두리

-- 입력
o.mouse = "a"
o.clipboard = "unnamedplus"
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true

-- Objective-C 파일타입 교정 (Swift/ObjC 저장소를 열 때만 의미가 있다)
--
-- `.m` 은 Objective-C 와 MATLAB 이 확장자를 공유해서 Neovim 이 앞 100줄을 훑어
-- 추측한다. 배너 주석(`/**** ---- ****/`)이 첫 `#import` 보다 먼저 나오면
-- murphi/matlab 로 넘어가고, 그러면 sourcekit-lsp 가 그 파일에 아예 안 붙는다.
-- 이 변수는 detect 최상단에서 검사되므로 추측을 건너뛰는 하드 오버라이드다.
-- (MATLAB 을 쓴다면 이 줄을 빼야 한다)
vim.g.filetype_m = "objc"

-- `.h` 는 기본적으로 objcpp(`@interface` 가 있을 때) 또는 cpp 로 잡히고 objc/c 가
-- 되지 않는다. ObjC 저장소에서는 이쪽이 맞다.
vim.g.c_syntax_for_h = 1

-- CocoaPods 가 두는 prefix 헤더(.pch)는 파일타입이 아예 안 잡힌다.
vim.filetype.add({ extension = { pch = "objc" } })

-- 검색
o.ignorecase = true
o.smartcase = true
o.inccommand = "split" -- :s 결과 실시간 미리보기

-- 노트는 되돌리기가 생명. 영구 undo 로 어제 지운 문단도 복구된다.
o.undofile = true
o.swapfile = false
o.updatetime = 250

-- render-markdown 이 마크업 기호(**, #, - [ ])를 숨기려면 필요
o.conceallevel = 2
o.concealcursor = "" -- 커서가 있는 줄은 원문 노출 → 편집 가능

-- 0.12 내장 treesitter 파서로 하이라이팅.
-- markdown / markdown_inline / lua / vim / vimdoc / query / c 는 nvim 에 동봉돼 있어
-- nvim-treesitter 플러그인이 전혀 필요 없다.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ts_highlight", { clear = true }),
  pattern = { "markdown", "lua", "vim", "help", "query", "c" },
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- 밖에서 바뀐 파일을 다시 읽어온다.
--
-- 'autoread' 는 "감지하면 다시 읽어라"는 정책일 뿐, **언제 확인할지**는 별개다.
-- nvim 은 파일을 감시하지 않고 특정 시점에만 검사하는데 터미널에선 그 시점이
-- 거의 오지 않는다. 그래서 Claude Code 나 다른 터미널이 파일을 고쳐도 화면은
-- 옛 내용 그대로고, 그 상태로 저장하면 남의 변경을 덮어쓴다.
--
-- checktime 을 걸어 커서를 멈추거나(updatetime 250ms) 창에 포커스가 돌아올 때
-- 디스크를 확인시킨다. git checkout·iCloud 동기화도 같이 커버된다.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("auto_checktime", { clear = true }),
  callback = function()
    -- ★ :checktime 은 자동명령 실행 중이면 검사를 연기한다(버퍼를 중간에
    --   갈아끼우지 않으려고). vim.schedule 로 자동명령 밖에서 돌려야 즉시 반영된다.
    vim.schedule(function()
      -- 명령행 편집 중이거나 특수 버퍼(터미널·quickfix)면 건너뛴다
      if vim.fn.mode() ~= "c" and vim.bo.buftype == "" then
        vim.cmd.checktime()
      end
    end)
  end,
})

-- 버퍼를 손대지 않았는데 밖에서 바뀌면 조용히 갈아끼우지 말고 알려준다
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = vim.api.nvim_create_augroup("file_changed_notify", { clear = true }),
  callback = function(ev)
    vim.notify(("Reloaded: %s (changed on disk)"):format(vim.fn.fnamemodify(ev.file, ":t")), vim.log.levels.WARN)
  end,
})

-- 복사한 영역 잠깐 하이라이트
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- 파일을 다시 열면 마지막 커서 위치로 (긴 노트에서 유용)
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("last_position", { clear = true }),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
