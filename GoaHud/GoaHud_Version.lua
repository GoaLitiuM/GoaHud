-- GoaHud_Version made by GoaLitiuM
--
-- Tracks changes to GoaHud.
--

local version = 30

function GoaHud_GetVersionPretty()
    return "r" .. GoaHud_Version.version
end

local changelog = {}
for i = 1, 29 do
    table.insert(changelog, "")
end

--
-- changelogs:
--

changelog[30] = "\z
- BetterGameplay: Added option to disable official item timers in casual duels\n\z
- Added support for extended chat color codes from CPMA (^9, ^a, ^z, etc.)\n\z
- Chat: Use Twitter emojis over Kimi's emojis\n\z
- Chat: Text is now colored in realtime while typing in chat with color codes\n\z
- Chat: Added options to disable emojis and colors\n\z
- Show current version of GoaHud in widget options\n\z
"







--
-- end of changelogs
--

GoaHud_Version =
{
    version = version,
    changelog = changelog,
}