--[[debug commands
    client.SetConVar("cl_vWeapon_sway_interp",              0)             -- Set cl_vWeapon_sway_interp to 0
    client.SetConVar("cl_jiggle_bone_framerate_cutoff", 0)             -- Set cl_jiggle_bone_framerate_cutoff to 0
    client.SetConVar("cl_bobcycle",                     10000)         -- Set cl_bobcycle to 10000
    client.SetConVar("sv_cheats", 1)                                    -- debug fast setup
    client.SetConVar("mp_disable_respawn_times", 1)
    client.SetConVar("mp_respawnwavetime", -1)
    client.SetConVar("mp_teams_unbalance_limit", 1000)

    -- debug command: ent_fire !picker Addoutput "health 99999" --superbot
]]
local MenuModule = {}

--[[ Imports ]]
local G = require("Resolver.Globals")

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local lastToggleTime = 0
local Lbox_Menu_Open = true
local toggleCooldown = 0.1  -- 200 milliseconds

function MenuModule.toggleMenu()
    local currentTime = globals.RealTime()
    if currentTime - lastToggleTime >= toggleCooldown then
        Lbox_Menu_Open = not Lbox_Menu_Open  -- Toggle the state
        G.Gui.IsVisible = Lbox_Menu_Open
        lastToggleTime = currentTime  -- Reset the last toggle time
    end
end

function MenuModule.GetPressedkey()
    local pressedKey = Input.GetPressedKey()
        if not pressedKey then
            -- Check for standard mouse buttons
            if input.IsButtonDown(MOUSE_LEFT) then return MOUSE_LEFT end
            if input.IsButtonDown(MOUSE_RIGHT) then return MOUSE_RIGHT end
            if input.IsButtonDown(MOUSE_MIDDLE) then return MOUSE_MIDDLE end

            -- Check for additional mouse buttons
            for i = 1, 10 do
                if input.IsButtonDown(MOUSE_FIRST + i - 1) then return MOUSE_FIRST + i - 1 end
            end
        end
        return pressedKey
end


local bindTimer = 0
local bindDelay = 0.25  -- Delay of 0.25 seconds

local function handleKeybind(noKeyText, keybind, keybindName)
    if KeybindName ~= "Press The Key" and ImMenu.Button(KeybindName or noKeyText) then
        bindTimer = os.clock() + bindDelay
        KeybindName = "Press The Key"
    elseif KeybindName == "Press The Key" then
        ImMenu.Text("Press the key")
    end

    if KeybindName == "Press The Key" then
        if os.clock() >= bindTimer then
            local pressedKey = MenuModule.GetPressedkey()
            if pressedKey then
                if pressedKey == KEY_ESCAPE then
                    -- Reset keybind if the Escape key is pressed
                    keybind = 0
                    KeybindName = "Always On"
                    Notify.Simple("Keybind Success", "Bound Key: " .. KeybindName, 2)
                else
                    -- Update keybind with the pressed key
                    keybind = pressedKey
                    KeybindName = Input.GetKeyName(pressedKey)
                    Notify.Simple("Keybind Success", "Bound Key: " .. KeybindName, 2)
                end
            end
        end
    end
    return keybind, keybindName
end

function OnDrawMenu()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)
    local Menu = G.Menu
    local Main = Menu.Main

    -- Inside your OnCreateMove or similar function where you check for input
    if input.IsButtonDown(KEY_INSERT) then  -- Replace 72 with the actual key code for the button you want to use
        MenuModule.toggleMenu()
    end

    if Lbox_Menu_Open == true and ImMenu and ImMenu.Begin("Resolver", true) then
            local Tabs = Menu.Tabs
            local TabsOrder = { "Main", "Settings", "Visuals"}

            ImMenu.BeginFrame(1)
            for _, tab in ipairs(TabsOrder) do
                if ImMenu.Button(tab) then
                    for otherTab, _ in pairs(Tabs) do
                        Tabs[otherTab] = (otherTab == tab)
                    end
                end
            end
            ImMenu.EndFrame()

            if Tabs.Main then
                ImMenu.BeginFrame(1)
                    Menu.Main.minPriority = ImMenu.Slider("Min Priority", Menu.Main.minPriority, 0, 10)
                ImMenu.EndFrame()

                ImMenu.BeginFrame(1)
                    Menu.Main.cycleYawFOV = ImMenu.Slider("Roll Fov", Menu.Main.cycleYawFOV, 1, 360)
                ImMenu.EndFrame()

                --[[ImMenu.BeginFrame(1)
                    ImMenu.Text("Keybind: ")
                    Menu.Aimbot.Keybind, Menu.Aimbot.KeybindName = handleKeybind("Always On", Menu.Aimbot.Keybind,  Menu.Aimbot.KeybindName)
                ImMenu.EndFrame()]]
            end

            if Tabs.Settings then
                ImMenu.BeginFrame(1)
                    Menu.Settings.onlyHeadshots = ImMenu.Checkbox("Headshots Only", Menu.Settings.onlyHeadshots)
                ImMenu.EndFrame()

                ImMenu.BeginFrame(1)
                    Menu.Settings.maxMisses = ImMenu.Slider("Max Misses", Menu.Settings.maxMisses, 1, 10)
                ImMenu.EndFrame()
            end

            if Tabs.Visuals then
                ImMenu.BeginFrame(1)
                Menu.Visuals.Enable = ImMenu.Checkbox("Enable", Menu.Visuals.Enable)
                ImMenu.EndFrame()
            end
        ImMenu.End()
    end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "OnDrawMenu")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "OnDrawMenu", OnDrawMenu)                              -- Register the "Draw" callback 

return MenuModule