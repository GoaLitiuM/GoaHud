-- GoaHud_Version made by GoaLitiuM
--
-- Tracks changes to GoaHud.
--

local version = 32

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

changelog[31] = "\z
- Moved Emoji support to separate addon (GoaHud_EmojiSupport)\n\z
- GoaHud addon update progress is now shown in the main menu\n\z
- Auto updater now automatically updates EmojiSupport too when enabled\n\z
"

changelog[32] = "\z
- BetterGameplay: Added experimental option to enable color code support globally\n\z
- Chat: Fixed color codes leaking from player names\n\z
- Fix colored names not working in FragMessages anymore\n\z
- Fix text transparency with color codes\n\z
"






--
-- end of changelogs
--

GoaHud_Version =
{
    version = version,
    changelog = changelog,
}