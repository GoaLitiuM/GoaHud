GoaHud_EmojiSupport = { isMenu = false }
registerWidget("GoaHud_EmojiSupport");

-- the path could be too long so the error message's filepath might not have .lua in the end
GoaHud_EmojiPath = ({string.match(({pcall(function() error("") end)})[2],"^%[string \"base/(.*)/.-%.lua\"%]:%d+: $")})[1] or ({string.match(({pcall(function() error("") end)})[2],"^%[string \"base/(.*)/.-%...\"%]:%d+: $")})[1]

function GoaHud_EmojiSupport:initialize()
end
function GoaHud_EmojiSupport:draw()
end

