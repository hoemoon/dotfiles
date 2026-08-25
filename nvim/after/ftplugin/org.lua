-- org 는 할 일·일정 전용이다. 노트·산문은 마크다운에 있다(plugins.lua ★ org 참고).
--
-- `after/ftplugin` 에 있는 이유는 markdown.lua 와 같다 — orgmode 플러그인이
-- 자기 ftplugin/org.lua 를 먼저 로드하므로, 여기 쓴 값이 마지막에 이긴다.
--
-- ⚠ 헤드라인 이동은 건드리지 않는다. orgmode 가 org 버퍼에서 이미 쓴다:
--     }  다음 헤드라인   {  이전 헤드라인   g{ 상위로
--     ]] 같은 레벨 다음  [[ 같은 레벨 이전
--     <TAB> 접기 토글    <S-TAB> 전체 접기
--   markdown.lua 에서 ]]/[[ 를 검색으로 매핑한 것과 달리 여기선 덮으면 안 된다.
local o = vim.opt_local

-- 리스트·본문 들여쓰기 2칸 (org_startup_indented 가 화면 들여쓰기를 맡고,
-- 이건 실제로 넣는 공백 폭이다)
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true

-- 줄바꿈: 하드랩 금지, 화면에서만 접는다. 한글 어절이 길어 하드랩은 재편집이 괴롭다.
o.wrap = true
o.linebreak = true
o.breakindent = true -- 접힌 줄도 들여쓰기 유지 → 헤드라인 본문이 안 무너진다
o.showbreak = "↳ "
o.textwidth = 0
o.colorcolumn = ""

-- 할 일 목록에서는 줄번호가 방해된다 (이동은 헤드라인 점프로)
o.number = false
o.relativenumber = false

o.spelllang = "en_us" -- 한글 사전은 없다. <leader>ts 로 토글
o.spell = false

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
end

-- 접힌 줄 위에서 j/k 는 "보이는 줄" 단위. count 를 붙이면(3j) 실제 줄 단위 유지.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { buffer = true, expr = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { buffer = true, expr = true })
map({ "n", "x" }, "0", "g0", "줄 시작(보이는 줄)")
map({ "n", "x" }, "$", "g$", "줄 끝(보이는 줄)")

-- 맞춤법 토글 — markdown.lua 와 같은 키로 맞춘다
map("n", "<leader>ts", function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  vim.notify("Spell check: " .. (vim.opt_local.spell:get() and "on" or "off"))
end, "맞춤법 토글")
