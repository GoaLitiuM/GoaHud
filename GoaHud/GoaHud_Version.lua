-- GoaHud_Version made by GoaLitiuM
--
-- Tracks changes to GoaHud.
--

local version = 39

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

changelog[33] = "\z
- Zoom: Added new sensitivity rescaling option based on viewspeed algorithms\n\z
- Zoom: Zoom FOV is reset back to default value when invalid value is detecteds\n\z
- Fixed frag messages display time while playing replays in various speedss\n\z
- Fixed console sometimes getting spammed with list of player names after deaths\n\z
- Fixed wrong player name position with colored names while spectating other playerss\n\z
- Chat: Ignore color codes when shortening namess\n\z
"

changelog[34] = "\z
- EmojiSupport is no longer required to display custom emojis\n\z
- Fixed buggy Chat with player names containing emojis\n\z
- Fixed color code shadows with uppercase code letters\n\z
- Module settings are now hidden when module is not enabled\n\z
- Chat: Added new font Oswald\n\z
- Added new emojis ?\n\z
"

changelog[35] = "\z
"

changelog[36] = "\z
- Crosshair: added option to specify minimum time for mode shapes to show up\n\z
"

changelog[37] = "\z
- Added new Scores widget for spectators, works in duels and team modes (experimental, disabled by default)\n\z
+ Very simple and minimalistic looking score widget, will be expanded in future updates\n\z
+ Customizable health/armor bar animation speed (disable by setting the Tick Speed to 0)\n\z
+ Supports custom fonts and font sizes for both names and scores\n\z
+ Colors, center offset, bar sizes and propotional sizes are also customizable\n\z
- Chat: Added custom font support (experimental, use font filename without the extension, place your custom fonts under addons folder)\n\z
- Chat: Added chat scrolling support (use mouse wheel), and a new setting to display more lines when chat is active\n\z
- Chat: Display player ready messages (enabled by default)\n\z
- Messages: Show current ruleset after game mode, supports RMC, sushi and legacy (pre-1.1.4) rulesets\n\z
- BetterGameplay: Added option to strip/ignore color codes from all widgets (^1n^2i^3c^4 ^5o^6n^7e)\n\z
- BetterGameplay: Global color code mode now enables emoji support as well (still quite buggy)\n\z
- TimerBig: Added option to hide it while spectating (enabled by default)\n\z
- Fixed messages and frag messages overlapping with scoreboard\n\z
- Added Options button to movable sub-elements in Brandon's Hud Editor\n\z
- Fixed some emoji codes\n\z
- Chat: Added chat preview box to options\n\z
- Fixed reset settings not working with some options\n\z
"

changelog[38] = "\z
- Fixed error caused by old Chat font not getting applied correctly\n\z
"

changelog[39] = "\z
- Added customizable font options to following widgets:\n\z
- PerfMeter, Timer, TimerBig, RaceTimer, Ammo, Armor, Health, Messages, FragMessages, WeaponRack\n\z
- Added missing 'Lato Heavy' and 'Open Sans Condensed' fonts to list of available fonts\n\z
- Removed following features which could give a competitive advantage to players:\n\z
+ Removed GrenadeTimer widget\n\z
+ Removed base-25 timer options from Timer and BigTimer widgets\n\z
- Chat: Added option to change size of emojis\n\z
- Chat: Added customizable background color for chat input\n\z
- Chat: Fixed wrong cursor offset after emojis\n\z
- Chat: Fixed color codes itself not getting colorized in input line\n\z
- Chat: Fixed color code leakage from player names\n\z
- Chat: Fixed player not ready messages showing up at match start\n\z
- Scores: Fixed missing flag shadow on right side\n\z
- PerfMeter: Fixed font alignment not following widget anchoring\n\z
"





--
-- end of changelogs
--

GoaHud_Version =
{
    version = version,
    changelog = changelog,
}