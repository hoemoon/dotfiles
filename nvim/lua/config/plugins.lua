-- 플러그인 — 내장 vim.pack (Neovim 0.12)
--
-- vim.pack.add() = "똑똑한 :packadd". 없으면 설치하고, 바로 로드한다.
-- 잠금은 ~/.local/share/nvim/site/pack/core/nvim-pack-lock.json 에 자동 기록.
-- 업데이트: :lua vim.pack.update()  → 변경사항 검토 후 :w 로 확정, :q 로 취소
-- 제거    : :lua vim.pack.del({ "이름" })   (디렉터리 수동 삭제 금지 — 락파일이 어긋난다)

local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  -- 외형 — Ghostty 의 `theme = Flexoki Light` 와 같은 팔레트를 쓴다
  { src = gh("kepano/flexoki-neovim"), name = "flexoki" },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("nvim-tree/nvim-web-devicons") },

  -- ★ 마크다운 인라인 렌더링 — 이 설정의 핵심
  { src = gh("MeanderingProgrammer/render-markdown.nvim") },

  -- 집중 글쓰기
  { src = gh("folke/zen-mode.nvim") },

  -- 포매팅
  { src = gh("stevearc/conform.nvim") },

  -- 파일/내용 검색
  { src = gh("ibhagwan/fzf-lua") },

  -- 텍스트 감싸기 — 마크다운에서 **굵게** · [링크]() 를 만드는 핵심 동작
  { src = gh("kylechui/nvim-surround") },

  -- git 여백 표시 · hunk 조작
  { src = gh("lewis6991/gitsigns.nvim") },
})

-- ---------------------------------------------------------------- 외형
-- 터미널(Ghostty)과 같은 테마를 쓴다. ~/.config/ghostty/config 의
-- `theme = Flexoki Light` 와 팔레트가 동일해서 배경·전경이 이어진다.
-- 어두운 쪽으로 갈 땐 Ghostty 를 "Flexoki Dark" 로 바꾸고 여기를 flexoki-moon 으로.
vim.o.background = "light"
vim.cmd.colorscheme("flexoki-light")

require("nvim-web-devicons").setup({})

require("lualine").setup({
  options = {
    theme = "auto",
    section_separators = "",
    component_separators = "|",
  },
  sections = {
    lualine_x = {
      -- 마크다운에서 단어 수를 보여준다 (한글 포함)
      function()
        if vim.bo.filetype ~= "markdown" then
          return ""
        end
        local wc = vim.fn.wordcount()
        return (wc.visual_words or wc.words) .. " words"
      end,
      "filetype",
    },
  },
})

-- ------------------------------------------------- ★ 마크다운 렌더링
-- extmark 기반이라 편집 중에도 스타일이 유지된다.
-- (경쟁 플러그인 markview.nvim 은 커서가 닿으면 렌더가 풀려 글 흐름이 끊긴다)
require("render-markdown").setup({
  -- 체크박스·콜아웃 완성. in-process LSP 방식이라 내장 자동완성과 그대로 맞물린다.
  completions = { lsp = { enabled = true } },
  heading = {
    sign = false,
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    width = "block",
    left_pad = 0,
    right_pad = 2,
  },
  code = {
    sign = false,
    width = "block",
    right_pad = 2,
    left_pad = 1,
  },
  bullet = { icons = { "•", "◦", "▸", "▹" } },
  checkbox = {
    unchecked = { icon = "󰄱 " },
    checked = { icon = "󰱒 ", scope_highlight = "@markup.strikethrough" },
  },
  quote = { icon = "▍" },
  pipe_table = { preset = "round" },
  link = { wiki = { icon = "󰌷 ", highlight = "RenderMarkdownWikiLink" } },
})

-- ------------------------------------------------------------ 포매팅
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    markdown = { "prettier" },
    -- swift-format 은 Xcode 툴체인 번들이라 따로 설치할 게 없다. conform 의
    -- "swift" 포매터가 `swift format`(Swift 6+) 을 부르므로 PATH 문제도 없다
    -- ("swift_format" 쪽은 PATH 의 swift-format 을 찾아 이 머신에선 실패한다).
    -- 스타일은 워크스페이스 루트 .swift-format — 실측으로 4칸/120자.
    swift = { "swift" },
  },
  -- 저장 시 자동 포맷은 Lua 만. 마크다운·Swift 는 <leader>cf 로 수동.
  --
  -- prettier 의 한글 처리는 실측으로 확인했다 — 표는 글자 폭을 정확히 계산해
  -- 정렬하고(:---: 지시자도 존중), proseWrap=preserve 라 문단을 재배치하지 않는다.
  -- 다만 저장할 때마다 리스트 마커(`*`/`-`)·중첩 들여쓰기(4→2칸)·`1)`→`1.` 을
  -- 정규화하므로, 남이 쓴 문서나 캡처된 노트를 열었다 저장만 해도 diff 가 생긴다.
  -- 그게 싫어서 수동으로 둔다. 자동이 편하면 아래 filetype 조건을 지우면 된다.
  --
  -- Swift 도 같은 이유로 수동이다. swift-format 은 린터가 아니라 AST 에서
  -- 파일을 다시 찍어내는 재포매터라, 기존 코드에 돌리면 실측 46.5% 가 바뀐다
  -- (production/ 소스 1,630줄 표본. 규칙을 최소로 줄여도 33%). 세미콜론으로
  -- 한 줄에 붙여 쓴 본문을 펼치는 식의 구조 변경이 대부분이라 설정으로는 못 막는다.
  -- 지금은 새로 쓰는 파일과 손대는 파일에만 <leader>cf 로 적용한다. 저장소
  -- 전체를 한 번에 정리할지는 별도 결정 사항 — git blame 이 통째로 끊긴다.
  format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype ~= "lua" then
      return nil
    end
    return { timeout_ms = 1500, lsp_format = "fallback" }
  end,
})

-- -------------------------------------------------------------- 검색
-- fzf-lua — 목록을 Lua 가 들고 있지 않고 fzf 프로세스가 처리한다.
-- telescope + plenary(2개, 5.6MB) 를 1개로 줄이면서 큰 저장소에서 더 빠르다.
-- 외부 의존: fzf(brew) · fd · rg · bat(미리보기 문법 강조)
require("fzf-lua").setup({
  "default-title", -- 각 창에 제목 표시
  winopts = {
    height = 0.85,
    width = 0.85,
    preview = {
      layout = "flex", -- 창이 좁으면 자동으로 위아래 배치
      scrollbar = false,
    },
  },
  keymap = {
    builtin = {
      ["<C-u>"] = "preview-page-up",
      ["<C-d>"] = "preview-page-down",
    },
    fzf = {
      -- telescope 에서 쓰던 이동 키를 그대로 유지
      ["ctrl-j"] = "down",
      ["ctrl-k"] = "up",
      ["ctrl-q"] = "select-all+accept", -- 전체를 quickfix 로
    },
  },
  files = {
    cmd = "fd --type f --strip-cwd-prefix --hidden --exclude .git",
  },
  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden -g '!.git'",
  },
  -- 노트 검색에서 Obsidian 설정 폴더가 섞이지 않게
  file_ignore_patterns = { "%.obsidian/", "node_modules/", "/build/", "/dist/" },
})

-- --------------------------------------------------------- 감싸기
-- ysiw** → **단어**  ·  cs*_ → 기호 교체  ·  ds* → 제거
-- 비주얼 선택 후 S** 도 된다. 마크다운 산문에서 가장 자주 쓰는 동작.
-- 마크다운 전용 대상(b 굵게 · i 기울임 · c 코드 · l 링크)은
-- after/ftplugin/markdown.lua 에서 buffer_setup 으로 더한다.
-- 전역에 넣으면 Lua 편집에서 b=() 같은 기본 대상을 덮어써 버린다.
require("nvim-surround").setup({})

-- ------------------------------------------------------------- git
-- 여백에 변경 표시 + hunk 단위 조작. 커밋·로그는 fzf-lua 픽커와 셸이 담당한다
-- (fugitive/neogit/lazygit 은 넣지 않는다 — 커밋 워크플로와 겹친다).
require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "▁" },
    topdelete = { text = "▔" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  -- 산문에선 문단을 통째로 고치면 온 줄이 표시돼 시끄럽다. 필요할 때만 켠다.
  current_line_blame = false,
  current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },

  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local map = function(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = "git: " .. desc })
    end

    -- hunk 이동 — 진단(]d)과 짝이 맞게 ]c/[c
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, "다음 변경")
    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, "이전 변경")

    map("n", "<leader>hp", gs.preview_hunk, "변경 미리보기")
    map("n", "<leader>hs", gs.stage_hunk, "hunk stage/취소")
    map("v", "<leader>hs", function()
      gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "선택 영역 stage")
    map("n", "<leader>hr", gs.reset_hunk, "hunk 되돌리기")
    map("n", "<leader>hd", gs.diffthis, "이 파일 diff")
    map("n", "<leader>hb", function()
      gs.blame_line({ full = true })
    end, "이 줄 blame")
    -- 토글은 <leader>t 축으로 모은다(keymaps.lua 참고). h 밑은 hunk 조작만.
    -- hb = 한 번 띄워 보기 · tb = 계속 켜두기
    map("n", "<leader>tb", gs.toggle_current_line_blame, "줄 blame 상시표시 토글")
  end,
})

-- ------------------------------------------------------- 집중 글쓰기
require("zen-mode").setup({
  window = {
    width = 88, -- 한 줄에 들어갈 글자 수. 한글 기준 44자 남짓
    options = {
      number = false,
      relativenumber = false,
      cursorline = false,
      signcolumn = "no",
    },
  },
  plugins = {
    options = { laststatus = 0 },
  },
})
