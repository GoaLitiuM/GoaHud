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
- BetterGameplay: Added option to disable official item timers during casual duels\n\z
\z
"







--
-- end of changelogs
--

GoaHud_Version =
{
    version = version,
    changelog = changelog,
}