---@class Common
local Common = {}
local G = require("Resolver.Globals")
local Menu = G.Menu

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 1.0, "LNXlib version is too old, please update it!")
Common.Lib = Lib

Common.Log = Lib.Utils.Logger.new("Resolver")

-- Import utility functions
Math = Lib.Utils.Math
Conversion = Lib.Utils.Conversion
Input = Lib.Utils.Input
Commands = Lib.Utils.Commands
Timer = Lib.Utils.Timer
Conversion = Lib.Utils.Conversion

-- Import TF2 related functions
WPlayer = Lib.TF2.WPlayer
WWeapon = Lib.TF2.WWeapon
Helpers = Lib.TF2.Helpers
Common.Helpers = Helpers
Prediction = Lib.TF2.Prediction

-- Import UI related functions
Notify = Lib.UI.Notify
Fonts = Lib.UI.Fonts
Log = Lib.Utils.Logger.new("AdvancedMelee")
Log.Level = 0

--[[Common Functions]]--

function Common.Normalize(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    return Vector3(vec.x / length, vec.y / length, vec.z / length)
end

local LastAttackTick = 0
local AttackHappened = false

function Common.GetSteamID(player)
	local playerInfo = client.GetPlayerInfo(player:GetIndex())
	return playerInfo.SteamID
end

function Common.GetLastAttackTime(cmd, weapon)
    local TickCount = globals.TickCount()
    local NextAttackTime = G.pLocal.Actions.NextAttackTime
    --return (nextPrimaryAttack <= G.CurTime()) and (nextAttack <= G.CurTime())
    if AttackHappened == false and NextAttackTime >= TickCount then
        LastAttackTick = TickCount
        --print(LastAttackTick)
        AttackHappened = true
        return LastAttackTick, AttackHappened
    elseif NextAttackTime < TickCount and AttackHappened == true then
        AttackHappened = false
    end
    return LastAttackTick, false
end

local hasAttacked = false
local lastAmmoCount = 0

-- Check if the local player has fired their weapon
function Common.pLocalFired(cmd, plocal)
	local weapon = plocal:GetPropEntity("m_hActiveWeapon")
    G.pLocal.Actions.NextAttackTime = Conversion.Time_to_Ticks(weapon:GetPropFloat("m_flLastFireTime") or 0)
	local ammoTable = plocal:GetPropDataTableInt("localdata", "m_iAmmo")
    G.pLocal.Actions.LastAttackTime, G.pLocal.Actions.Attacked = Common.GetLastAttackTime(cmd, weapon)

	if G.pLocal.Actions.Attacked then

        hasAttacked = false

		-- Check if ammo has decreased
		local currentAmmo = ammoTable[2]
		if currentAmmo < lastAmmoCount then
			hasAttacked = true
		end
        lastAmmoCount = currentAmmo

		-- Check if attack button was pressed
		if cmd:GetButtons() & IN_ATTACK == 1 then
			hasAttacked = true
		end

		-- Check if player has attacked
		if hasAttacked then
			return true
		end
	end
end

function Common.isUsingAntiAim(pitch)
	if pitch > 89.4 or pitch < -89.4 then
		return true
	end

	return false
end

function Common.checkForFakePitch(player, steamID)
	local angles = player:GetEyeAngles()

	if Common.isUsingAntiAim(angles.pitch) then
		if not usesAntiAim[steamID] then
			usesAntiAim[steamID] = true
		end

		setupPlayerAngleData(player)
	end
end

function Common.SetupWeaponData()
    local pLocal = G.pLocal.entity

--[[Primary Weapon Data]]--
    G.pLocal.WpData.PWeapon.Weapon =  pLocal:GetEntityForLoadoutSlot( LOADOUT_POSITION_PRIMARY )
    local weapon = G.pLocal.WpData.PWeapon.Weapon

    if not weapon then print("no Primary Weapon") else
        G.pLocal.WpData.PWeapon.WeaponData = weapon:GetWeaponData()
        G.pLocal.WpData.PWeapon.WeaponID = weapon:GetWeaponID()
        G.pLocal.WpData.PWeapon.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
        if G.pLocal.WpData.PWeapon.WeaponDefIndex then
            G.pLocal.WpData.PWeapon.WeaponDef = itemschema.GetItemDefinitionByID(G.pLocal.WpData.PWeapon.WeaponDefIndex)
            G.pLocal.WpData.PWeapon.WeaponName = G.pLocal.WpData.PWeapon.WeaponDef:GetName()
        end
    end

--[[Melee Weapon Data]]--
    G.pLocal.WpData.MWeapon.Weapon =  pLocal:GetEntityForLoadoutSlot( LOADOUT_POSITION_MELEE )
    weapon = G.pLocal.WpData.MWeapon.Weapon

    if not weapon then print("no Melee Weapon") return false end
    G.pLocal.WpData.MWeapon.WeaponData = weapon:GetWeaponData()
    G.pLocal.WpData.MWeapon.WeaponID = weapon:GetWeaponID()
    G.pLocal.WpData.MWeapon.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
    G.pLocal.WpData.MWeapon.WeaponDef = itemschema.GetItemDefinitionByID(G.pLocal.WpData.MWeapon.WeaponDefIndex)
    G.pLocal.WpData.MWeapon.WeaponName = G.pLocal.WpData.MWeapon.WeaponDef:GetName()

--[[Current Weapon Data]]--
    G.pLocal.WpData.UsingMargetGarden = false
    weapon = G.pLocal.WpData.CurrWeapon.Weapon
    if not weapon then print("no Current Weapon") return false end
        local currWeapon = G.pLocal.WpData.CurrWeapon
        currWeapon.WeaponData = weapon:GetWeaponData()
        currWeapon.WeaponID = weapon:GetWeaponID()
        currWeapon.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
        currWeapon.WeaponDef = itemschema.GetItemDefinitionByID(currWeapon.WeaponDefIndex)
        currWeapon.WeaponName = currWeapon.WeaponDef:GetName()

    --[[if weapon:IsMeleeWeapon() then
            local swingData = G.pLocal.WpData.SwingData 
            -- Swing properties
                swingData.SmackDelay = Conversion.Time_to_Ticks(currWeapon.WeaponData.smackDelay) or 13
                G.pLocal.UsingMargetGarden = currWeapon.WeaponDefIndex == MarketGardenIndex

            local swingRange = weapon:GetSwingRange() or G.Static.DefaultSwingRange
            local isDisciplinaryAction = (currWeapon.WeaponDef:GetName() == "The Disciplinary Action")
            local swingHullSize = isDisciplinaryAction and disciplinaryActionHullSize or G.Static.defaultHullSize
            local halfHullSize = G.Static.HalfHullSize
                swingData.SwingRange = swingRange
                swingData.SwingHullSize = swingHullSize
                swingData.TotalSwingRange = swingRange + halfHullSize
                swingData.SwingHull = {
                    Max = Vector3(halfHullSize, halfHullSize, halfHullSize),
                    Min = Vector3(-halfHullSize, -halfHullSize, -halfHullSize)
                }

                if G.StrafeData.inaccuracy then -- If we got inaccuracy in strafe calculations
                    local inaccuracy = math.abs(G.StrafeData.inaccuracy[G.pLocal.index] or 0)
                    swingData.TotalSwingRange = swingData.TotalSwingRange - inaccuracy
                end
            G.pLocal.WpData.SwingData = swingData --save values
        end]]
    G.pLocal.WpData.CurrWeapon = currWeapon --save values
    return true
end

function Common.isValidWeapon(weapon)
	if not weapon then return false end
	if not weapon:IsWeapon() then return false end
	if not weapon:IsShootingWeapon() then return false end
    if weapon:IsMeleeWeapon() then return false end

	return true
end

--local fFalse = function () return false end

-- [WIP] Predict the position of a player
---@param player WPlayer
---@param t integer
---@param d number?
---@param shouldHitEntity fun(entity: WEntity, contentsMask: integer): boolean?
---@return { pos : Vector3[], vel: Vector3[], onGround: boolean[] }?
function Common.PredictPlayer(player, t, d)
        if not G.World.Gravity or not G.World.StepHeight then return nil end
        local vUp = Vector3(0, 0, 1)
        local vStep = Vector3(0, 0, G.World.StepHeight)
        local shouldHitEntity = function(entity) return entity:GetName() ~= player:GetName() end --trace ignore simulated player 
        local pFlags = player:GetPropInt("m_fFlags")
        local OnGround = pFlags & FL_ONGROUND == 1
        local vHitbox
        if G.pLocal.vHitbox and player == G.pLocal.entity then
            vHitbox = G.pLocal.vHitbox
        elseif G.Target.vHitbox then
            vHitbox = G.Target.vHitbox
        else
            vHitbox = G.Defaults.vHitbox
        end
        local pLocal = G.pLocal.entity
        local pLocalIndex = G.pLocal.index

        -- Add the current record
        local _out = {
            pos = { [0] = player:GetAbsOrigin() },
            vel = { [0] = player:EstimateAbsVelocity() },
            onGround = { [0] = OnGround }
        }

        -- Perform the prediction
        for i = 1, t do
            local lastP, lastV, lastG = _out.pos[i - 1], _out.vel[i - 1], _out.onGround[i - 1]

            local pos = lastP + lastV * globals.TickInterval()
            local vel = lastV
            local onGround1 = lastG

            -- Apply deviation
            if d then
                local ang = vel:Angles()
                ang.y = ang.y + d
                vel = ang:Forward() * vel:Length()
            end

            --[[ Forward collision ]]

            local wallTrace = engine.TraceHull(lastP + vStep, pos + vStep, vHitbox.Min, vHitbox.Max, MASK_PLAYERSOLID_BRUSHONLY, shouldHitEntity)
            --DrawLine(last.p + vStep, pos + vStep)
            if wallTrace.fraction < 1 then
                -- We'll collide
                local normal = wallTrace.plane
                local angle = math.deg(math.acos(normal:Dot(vUp)))

                -- Check the wall angle
                if angle > 55 then
                    -- The wall is too steep, we'll collide
                    local dot = vel:Dot(normal)
                    vel = vel - normal * dot
                end

                pos.x, pos.y = wallTrace.endpos.x, wallTrace.endpos.y
            end

            --[[ Ground collision ]]

            -- Don't step down if we're in-air
            local downStep = vStep
            if not onGround1 then downStep = Vector3() end

            -- Ground collision
            local groundTrace = engine.TraceHull(pos + vStep, pos - downStep, vHitbox.Min, vHitbox.Max, MASK_PLAYERSOLID_BRUSHONLY, shouldHitEntity)
            if groundTrace.fraction < 1 then
                -- We'll hit the ground
                local normal = groundTrace.plane
                local angle = math.deg(math.acos(normal:Dot(vUp)))

                -- Check the ground angle
                if angle < 45 then
                    if onGround1 and player:GetIndex() == pLocalIndex and gui.GetValue("Bunny Hop") == 1 and input.IsButtonDown(KEY_SPACE) then
                        -- Jump
                        if gui.GetValue("Duck Jump") == 1 then
                            vel.z = 277
                            onGround1 = false
                        else
                            vel.z = 271
                            onGround1 = false
                        end
                    else
                        pos = groundTrace.endpos
                        onGround1 = true
                    end
                elseif angle < 55 then
                    vel.x, vel.y, vel.z = 0, 0, 0
                    onGround1 = false
                else
                    local dot = vel:Dot(normal)
                        vel = vel - normal * dot
                        onGround1 = true
                end
            else
                -- We're in the air
                onGround1 = false
            end

            -- Gravity
            --local isSwimming, isWalking = checkPlayerState(player) -- todo: fix this
            if not onGround1 then
                vel.z = vel.z - G.World.Gravity * globals.TickInterval()
            end

            -- Add the prediction record
            _out.pos[i], _out.vel[i], _out.onGround[i] = pos, vel, onGround1
        end

        return _out
end

function Common.GetBestTarget()
	local localPlayer = entities.GetLocalPlayer()
	local players = entities.FindByClass("CTFPlayer")
	local target = nil
	local lastFov = math.huge

	for _, entity in pairs(players) do
		if not entity then goto continue end
		if not entity:IsAlive() then goto continue end
		if entity:GetTeamNumber() == localPlayer:GetTeamNumber() then goto continue end

		local player = entity
		local aimPos = getHitboxPos(player, 1)
		local angles = positionAngles(getEyePos(localPlayer), aimPos)
		local fov = angleFov(angles, engine.GetViewAngles())
		if fov > (G.Menu.Main.cycleYawFOV or gui.GetValue("aim fov")) then goto continue end

		if fov < lastFov then
			lastFov = fov
			target = { entity = entity, pos = aimPos, angles = angles, factor = fov }
		end

		::continue::
	end

	return target
end

function Common.CalcStrafe()
    local autostrafe = gui.GetValue("Auto Strafe")
    local flags = G.pLocal.entity:GetPropInt("m_fFlags")
    local OnGround = flags & FL_ONGROUND == 1

    for idx, entity in ipairs(G.Players) do
        local entityIndex = entity:GetIndex()

        if not entity or not entity:IsValid() and entity:IsDormant() or not entity:IsAlive() then
            G.StrafeData.lastAngles[entityIndex] = nil
            G.StrafeData.lastDeltas[entityIndex] = nil
            G.StrafeData.avgDeltas[entityIndex] = nil
            G.StrafeData.strafeAngles[entityIndex] = nil
            G.StrafeData.inaccuracy[entityIndex] = nil
            goto continue
        end

        local v = entity:EstimateAbsVelocity()
        if entity == G.pLocal.entity then
            table.insert(G.StrafeData.pastPositions, 1, entity:GetAbsOrigin())
            if #G.StrafeData.pastPositions > G.StrafeData.maxPositions then
                table.remove(G.StrafeData.pastPositions)
            end

            if not onGround and autostrafe == 2 and #G.StrafeData.pastPositions >= G.StrafeData.maxPositions then
                v = Vector3(0, 0, 0)
                for i = 1, #G.StrafeData.pastPositions - 1 do
                    v = v + (G.StrafeData.pastPositions[i] - G.StrafeData.pastPositions[i + 1])
                end
                v = v / (G.StrafeData.maxPositions - 1)
            else
                v = entity:EstimateAbsVelocity()
            end
        end

        local angle = v:Angles()

        if G.StrafeData.lastAngles[entityIndex] == nil then
            G.StrafeData.lastAngles[entityIndex] = angle
            goto continue
        end

        local delta = angle.y - G.StrafeData.lastAngles[entityIndex].y

        -- Calculate the average delta using exponential smoothing
        local smoothingFactor = 0.2
        local avgDelta = (G.StrafeData.lastDeltas[entityIndex] or delta) * (1 - smoothingFactor) + delta * smoothingFactor

        -- Save the average delta
        G.StrafeData.avgDeltas[entityIndex] = avgDelta

        local vector1 = Vector3(1, 0, 0)
        local vector2 = Vector3(1, 0, 0)

        -- Apply deviation
        local ang1 = vector1:Angles()
        ang1.y = ang1.y + (G.StrafeData.lastDeltas[entityIndex] or delta)
        vector1 = ang1:Forward() * vector1:Length()

        local ang2 = vector2:Angles()
        ang2.y = ang2.y + avgDelta
        vector2 = ang2:Forward() * vector2:Length()

        -- Calculate the distance between the two vectors
        local distance = (vector1 - vector2):Length()

        -- Save the strafe angle
        G.StrafeData.strafeAngles[entityIndex] = avgDelta

        -- Calculate the inaccuracy as the distance between the two vectors
        G.StrafeData.inaccuracy[entityIndex] = distance

        -- Save the last delta
        G.StrafeData.lastDeltas[entityIndex] = delta

        G.StrafeData.lastAngles[entityIndex] = angle

        ::continue::
    end
end

--[[ Sphere cache and drawn edges cache
local sphere_cache = { vertices = {}, radius = 90, center = Vector3(0, 0, 0) }
local drawnEdges = {}

local function setup_sphere(center, radius, segments)
    sphere_cache.center = center
    sphere_cache.radius = radius
    sphere_cache.segments = segments
    sphere_cache.vertices = {}  -- Clear the old vertices

    local thetaStep = math.pi / segments
    local phiStep = 2 * math.pi / segments

    for i = 0, segments - 1 do
        local theta1 = thetaStep * i
        local theta2 = thetaStep * (i + 1)

        for j = 0, segments - 1 do
            local phi1 = phiStep * j
            local phi2 = phiStep * (j + 1)

            -- Generate a square for each segment
            table.insert(sphere_cache.vertices, {
                Vector3(math.sin(theta1) * math.cos(phi1), math.sin(theta1) * math.sin(phi1), math.cos(theta1)),
                Vector3(math.sin(theta1) * math.cos(phi2), math.sin(theta1) * math.sin(phi2), math.cos(theta1)),
                Vector3(math.sin(theta2) * math.cos(phi2), math.sin(theta2) * math.sin(phi2), math.cos(theta2)),
                Vector3(math.sin(theta2) * math.cos(phi1), math.sin(theta2) * math.sin(phi1), math.cos(theta2))
            })
        end
    end
end]]

function Common.L_line(start_pos, end_pos, secondary_line_size)
    if not (start_pos and end_pos) then
        return
    end
    local direction = end_pos - start_pos
    local direction_length = direction:Length()
    if direction_length == 0 then
        return
    end
    local normalized_direction = Normalize(direction)
    local perpendicular = Vector3(normalized_direction.y, -normalized_direction.x, 0) * secondary_line_size
    local w2s_start_pos = client.WorldToScreen(start_pos)
    local w2s_end_pos = client.WorldToScreen(end_pos)
    if not (w2s_start_pos and w2s_end_pos) then
        return
    end
    local secondary_line_end_pos = start_pos + perpendicular
    local w2s_secondary_line_end_pos = client.WorldToScreen(secondary_line_end_pos)
    if w2s_secondary_line_end_pos then
        draw.Line(w2s_start_pos[1], w2s_start_pos[2], w2s_end_pos[1], w2s_end_pos[2])
        draw.Line(w2s_start_pos[1], w2s_start_pos[2], w2s_secondary_line_end_pos[1], w2s_secondary_line_end_pos[2])
    end
end

function Common.arrowPathArrow2(startPos, endPos, width)
    if not (startPos and endPos) then return nil, nil end

    local direction = endPos - startPos
    local length = direction:Length()
    if length == 0 then return nil, nil end
    direction = NormalizeVector(direction)

    local perpDir = Vector3(-direction.y, direction.x, 0)
    local leftBase = startPos + perpDir * width
    local rightBase = startPos - perpDir * width

    local screenStartPos = client.WorldToScreen(startPos)
    local screenEndPos = client.WorldToScreen(endPos)
    local screenLeftBase = client.WorldToScreen(leftBase)
    local screenRightBase = client.WorldToScreen(rightBase)

    if screenStartPos and screenEndPos and screenLeftBase and screenRightBase then
        draw.Line(screenStartPos[1], screenStartPos[2], screenEndPos[1], screenEndPos[2])
        draw.Line(screenLeftBase[1], screenLeftBase[2], screenEndPos[1], screenEndPos[2])
        draw.Line(screenRightBase[1], screenRightBase[2], screenEndPos[1], screenEndPos[2])
    end

    return leftBase, rightBase
end

function Common.arrowPathArrow(startPos, endPos, arrowWidth)
    if not startPos or not endPos then return end

    local direction = endPos - startPos
    if direction:Length() == 0 then return end

    -- Normalize the direction vector and calculate perpendicular direction
    direction = NormalizeVector(direction)
    local perpendicular = Vector3(-direction.y, direction.x, 0) * arrowWidth

    -- Calculate points for arrow fins
    local finPoint1 = startPos + perpendicular
    local finPoint2 = startPos - perpendicular

    -- Convert world positions to screen positions
    local screenStartPos = client.WorldToScreen(startPos)
    local screenEndPos = client.WorldToScreen(endPos)
    local screenFinPoint1 = client.WorldToScreen(finPoint1)
    local screenFinPoint2 = client.WorldToScreen(finPoint2)

    -- Draw the arrow
    if screenStartPos and screenEndPos then
        draw.Line(screenEndPos[1], screenEndPos[2], screenFinPoint1[1], screenFinPoint1[2])
        draw.Line(screenEndPos[1], screenEndPos[2], screenFinPoint2[1], screenFinPoint2[2])
        draw.Line(screenFinPoint1[1], screenFinPoint1[2], screenFinPoint2[1], screenFinPoint2[2])
    end
end

function Common.drawPavement(startPos, endPos, width)
    if not (startPos and endPos) then return nil end

    local direction = endPos - startPos
    local length = direction:Length()
    if length == 0 then return nil end
    direction = NormalizeVector(direction)

    -- Calculate perpendicular direction for the width
    local perpDir = Vector3(-direction.y, direction.x, 0)

    -- Calculate left and right base points of the pavement
    local leftBase = startPos + perpDir * width
    local rightBase = startPos - perpDir * width

    -- Convert positions to screen coordinates
    local screenStartPos = client.WorldToScreen(startPos)
    local screenEndPos = client.WorldToScreen(endPos)
    local screenLeftBase = client.WorldToScreen(leftBase)
    local screenRightBase = client.WorldToScreen(rightBase)

    -- Draw the pavement
    if screenStartPos and screenEndPos and screenLeftBase and screenRightBase then
        draw.Line(screenStartPos[1], screenStartPos[2], screenEndPos[1], screenEndPos[2])
        draw.Line(screenStartPos[1], screenStartPos[2], screenLeftBase[1], screenLeftBase[2])
        draw.Line(screenStartPos[1], screenStartPos[2], screenRightBase[1], screenRightBase[2])
    end

    return leftBase, rightBase
end

local function setupPlayerAngleData(player)
	local steamID = getSteamID(player)

	if customAngleData[steamID] then
		return
	end

	customAngleData[steamID] = {
		plr = player,
		yawCycleIndex = 0,
		lastYaw = 0,
	}
end

local function getMinimumLatency(trueLatency)
	local latency = clientstate.GetLatencyIn() + clientstate.GetLatencyOut()
	if trueLatency == true then return latency end
	return latency <= 0.1 and 0.1 or latency
end

function Common.announceMiss(player)
	local name, steamID = client.GetPlayerInfo(player:GetIndex()).Name, getSteamID(player)
	client.ChatPrintf(string.format("\x073475c9[Resolver] \x01Missed player \x073475c9'%s'\x01. Shots remaining: \x07f22929%s", name, 4 - (misses[steamID] or 1)))
end

function Common.announceResolve(data)
	local name, yaw = client.GetPlayerInfo(data.plr:GetIndex()).Name, getYawText(data)
	if yaw == "" or data.lastYaw == yaw then return end

	data.lastYaw = yaw
	client.ChatPrintf(string.format("\x073475c9[Resolver] \x01Adjusted player \x073475c9'%s'\x01 yaw to \x07f22929%s", name, yaw))
end

function Common.getBool(event, name)
	local bool = event:GetInt(name)
	return bool == 1
end

local function cycleYaw(data, step)
	data.yawCycleIndex = data.yawCycleIndex + (step or .5)

	if data.yawCycleIndex > #G.Menu.Settings.yawCycle then
		data.yawCycleIndex = 1
	end

	Common.announceResolve(data)
end

function Common.processConfirmation(steamID, data)
	local enemy, hitTime, wasHit = data.enemy, data.hitTime, data.wasHit

	if wasHit then
		G.Resolver.awaitingConfirmation[steamID] = nil
		goto continue
	end

	if G.Resolver.lastHits[steamID] and G.Resolver.lastHits[steamID].wasHit then
		local diff = globals.TickCount() - G.Resolver.lastHits[steamID].time
		if diff < getMinimumLatency(true) * 2 then
			G.Resolver.awaitingConfirmation[steamID] = nil -- we hit the person but the event was fired before awaitingconfirmation was updated
			goto continue
		end
	end

	if globals.TickCount() >= hitTime then
		local usingAntiAim = G.Resolver.usesAntiAim[steamID]

		if not usingAntiAim then
			if not G.Resolver.misses[steamID] then
				G.Resolver.misses[steamID] = 0
			end

			if misses[steamID] < Menu.Settings.maxMisses then
				G.Resolver.misses[steamID] = G.Resolver.misses[steamID] + 1
				G.Resolver.awaitingConfirmation[steamID] = nil
				Common.announceMiss(enemy)
				goto continue
			end
		end

		if not G.Resolver.customAngleData[steamID] then
			setupPlayerAngleData(enemy)
		end

		cycleYaw(G.Resolver.customAngleData[steamID])
		G.Resolver.awaitingConfirmation[steamID] = nil
	end

	::continue::
end


-- Call setup_sphere once at the start of your program
--setup_sphere(Vector3(0, 0, 0), 90, 7)

local white_texture = draw.CreateTextureRGBA(string.char(
	0xff, 0xff, 0xff, 25,
	0xff, 0xff, 0xff, 25,
	0xff, 0xff, 0xff, 25,
	0xff, 0xff, 0xff, 25
), 2, 2);

--[[local drawPolygon = (function()
	local v1x, v1y = 0, 0;
	local function cross(a, b)
		return (b[1] - a[1]) * (v1y - a[2]) - (b[2] - a[2]) * (v1x - a[1])
	end

	local TexturedPolygon = draw.TexturedPolygon;

	return function(vertices)
		local cords, reverse_cords = {}, {};
		local sizeof = #vertices;
		local sum = 0;

		v1x, v1y = vertices[1][1], vertices[1][2];
		for i, pos in pairs(vertices) do
			local convertedTbl = {pos[1], pos[2], 0, 0};

			cords[i], reverse_cords[sizeof - i + 1] = convertedTbl, convertedTbl;

			sum = sum + cross(pos, vertices[(i % sizeof) + 1]);
		end


		TexturedPolygon(white_texture, (sum < 0) and reverse_cords or cords, true)
	end
end)();]]

return Common