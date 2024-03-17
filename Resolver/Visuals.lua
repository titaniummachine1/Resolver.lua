--[[ Imports ]]
local Common = require("Resolver.Common")
local G = require("Resolver.Globals")
local Visuals = {}

local tahoma_bold = draw.CreateFont("Tahoma", 12, 800, FONTFLAG_OUTLINE)

--[[ Functions ]]
local function doDraw()
    --if true then return end
    local Menu = G.Menu
    if (engine.Con_IsVisible() or engine.IsGameUIVisible() or G.Gui.IsVisible) or not Menu.Visuals.EnableVisuals then return end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "AMVisuals_Draw")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "AMVisuals_Draw", doDraw)                              -- Register the "Draw" callback 

return Visuals