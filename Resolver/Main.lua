--[[
    Resolver Recode
    Author: titaniummachine1 (https://github.com/titaniummachine1)
    Credits:
    LNX (github.com/lnx00) for libries
]]

--[[ Annotations ]]
---@alias PlayerData { Angle: EulerAngles[], Position: Vector3[], SimTime: number[] }

--[[ Imports ]]
local Common = require("Resolver.Common")
local G = require("Resolver.Globals")
require("Resolver.Config")
require("Resolver.Visuals")
require("Resolver.Menu")

local function OnCreateMove(cmd)
    -- Update local player data
    G.pLocal.entity = entities.GetLocalPlayer() -- Update local player entity
    local pLocal = G.pLocal.entity
    if not pLocal or not pLocal:IsAlive() then return end -- If local player is not valid, returns

    G.Players = entities.FindByClass("CTFPlayer")
    G.pLocal.flags = pLocal:GetPropInt("m_fFlags")

    -- World properties
    G.World.Gravity = client.GetConVar("sv_gravity")
    G.World.StepHeight = pLocal:GetPropFloat("localdata", "m_flStepSize")
    G.World.Lerp = client.GetConVar("cl_interp") or 0
    G.World.latOut = clientstate.GetLatencyOut()
    G.World.latIn = clientstate.GetLatencyIn()
    G.World.Latency = Conversion.Time_to_Ticks((G.World.latOut + G.World.latIn) * (globals.TickInterval() * 66.67)) -- Converts time to ticks

    -- Player properties
    G.pLocal.Class = pLocal:GetPropInt("m_iClass") or 1
    G.pLocal.index = pLocal:GetIndex() or 1
    G.pLocal.team = pLocal:GetTeamNumber() or 1
    G.pLocal.ViewAngles = engine.GetViewAngles() or EulerAngles(0, 0, 0)
    G.pLocal.OnGround = (G.pLocal.flags & FL_ONGROUND == 1) or false

    G.pLocal.GetAbsOrigin = pLocal:GetAbsOrigin() or Vector3(0, 0, 0)
    local pLocalOrigin = G.pLocal.GetAbsOrigin
    local viewOffset = pLocal:GetPropVector("localdata", "m_vecViewOffset[0]") or Vector3(0, 0, 75)
    local adjustedHeight = pLocalOrigin + viewOffset
    local viewheight = (adjustedHeight - pLocalOrigin):Length()
    G.pLocal.Viewheight = viewheight
    G.pLocal.VisPos = G.pLocal.GetAbsOrigin + Vector3(0, 0, G.pLocal.Viewheight)

    -- Weapon properties
    G.pLocal.WpData.CurrWeapon.Weapon = pLocal:GetPropEntity("m_hActiveWeapon") or nil
    local weapon = G.pLocal.WpData.CurrWeapon.Weapon
    if not weapon then return end
    if not Common.SetupWeaponData() then return end
    if not Common.isValidWeapon(weapon) then return end
    if not Common.Helpers.CanShoot(weapon) then return end

    G.pLocal.Actions.Attacked = Common.pLocalFired(cmd, pLocal)

    G.ShouldFindTarget = G.pLocal.Actions.Attacked

    for steamID, data in pairs(G.Resolver.awaitingConfirmation) do
		Common.processConfirmation(steamID, data)
	end

    --[-----Get best target-----]
    if G.ShouldFindTarget == true then
        -- Check if need to search for target
        G.Target.entity = Common.GetBestTarget()
        local Target = G.Target.entity
        if G.Target.entity then
            G.Target.index = G.Target.entity:GetIndex()
            G.Target.AbsOrigin = G.Target.entity:GetAbsOrigin()
            G.Target.flags = pLocal:GetPropInt("m_fFlags")

            local Target_Origin = G.Target.AbsOrigin
            viewOffset = G.Target.entity:GetPropVector("localdata", "m_vecViewOffset[0]") or Vector3(0, 0, 75)
            adjustedHeight = Target_Origin + viewOffset
            viewheight = (adjustedHeight - Target_Origin):Length()
            G.Target.Viewheight = viewheight or 75
            G.Target.ViewPos = Target_Origin + Vector3(0,0,viewheight)
        end
    else
        G.ResetTarget()
        return
    end
end


local function fireGameEvent(event)
	if event:GetName() == 'player_hurt' then
		local victim = entities.GetByUserID(event:GetInt("userid"))
		local attacker = entities.GetByUserID(event:GetInt("attacker"))
		local headshot = Common.getBool(event, "crit")
        local pLocal = entities.GetLocalPlayer()

		if (attacker ~= nil and pLocal:GetName() ~= attacker:GetName()) then
			local attackerSteamID = Common.GetSteamID(attacker)
			Common.checkForFakePitch(attacker, attackerSteamID)
		end

		local steamID = Common.GetSteamID(victim)

		if G.Resolver.awaitingConfirmation[steamID] then
			G.Resolver.awaitingConfirmation[steamID].wasHit = headshot
            G.Resolver.awaitingConfirmation[steamID].Angles = victim:GetEyeAngles()
		else
			G.Resolver.lastHits[steamID] = {wasHit = headshot, time = globals.TickCount()} -- could have fired before createmove
		end
	end
end

callbacks.Unregister("CreateMove", "Resolver.CreateMove")
callbacks.Unregister("FireGameEvent", "Resolver.FireGameEvent")
--callbacks.Unregister("PostPropUpdate", "Resolver.PostPropUpdate")

callbacks.Register("CreateMove", "Resolver.CreateMove",  OnCreateMove)
callbacks.Register("FireGameEvent", "Resolver.FireGameEvent", fireGameEvent)
--callbacks.Register("PostPropUpdate", "Resolver.PostPropUpdate", propUpdate)

--[[ Play sound when loaded ]]--
client.Command('play "ui/buttonclick"', true) -- Play the "buttonclick" sound when the script is loaded