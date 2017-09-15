GoaHud_EmojiSupport = { isMenu = true, initialize = function() end, draw = function() end }
registerWidget("GoaHud_EmojiSupport");

GoaHud_EmojiPath = ({string.match(({pcall(function() error("") end)})[2],"^%[string \"base/(.*)/.-%.lua\"%]:%d+: $")})[1]