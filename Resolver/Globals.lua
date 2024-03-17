local G = {}

G.Menu = {
    Tabs = {
        Main = true,
        Visuals = false,
        Settings = false,
    },

    Main = {
        minPriority = 0,
        cycleYawFOV = 360, -- FOV to use when cycling the yaw through keybind
    },
    Settings = {
        onlyHeadshots = true,
        maxMisses = 3,
        yawCycle = {
            0,
            90, -90,
        }
    },
    Visuals = {
        Enable = true,
    }
}

G.Resolver = {
    lastHits = {},
    awaitingConfirmation = {},
    usesAntiAim = {},
    customAngleData = {},
    misses = {},
    cycleKeyState = false,
    plocal = entities.GetLocalPlayer(),
}


G.Defaults = {
    entity = nil,
    index = 1,
    team = 1,
    Class = 1,
    AbsOrigin = Vector3{0, 0, 0},
    flags = 0,
    OnGround = true,
    ViewAngles = EulerAngles{0, 0, 0},
    Viewheight = Vector3{0, 0, 75},
    VisPos = Vector3{0, 0, 75},
    PredTicks = {},
    vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)},
}

G.pLocal = {
    entity = nil,
    index = 1,
    flags = 0,
    team = 1,
    Class = 1,
    AbsOrigin = Vector3{0, 0, 0},
    OnGround = true,
    ViewAngles = EulerAngles{0, 0, 0},
    Viewheight = Vector3{0, 0, 75},
    VisPos = Vector3{0, 0, 75},
    PredTicks = {},
    NextAttackTime = 0,
    WpData = {
        UsingMargetGarden = false,
        PWeapon = {
            Weapon = nil,
            WeaponData = nil,
            WeaponID = nil,
            WeaponDefIndex = nil,
            WeaponDef = nil,
            WeaponName = nil,
        },
        MWeapon = {
            Weapon = nil,
            WeaponData = nil,
            WeaponID = nil,
            WeaponDefIndex = nil,
            WeaponDef = nil,
            WeaponName = nil,
        },
        CurrWeapon = {
            Weapon = nil,
            WeaponData = nil,
            WeaponID = nil,
            WeaponDefIndex = nil,
            WeaponDef = nil,
            WeaponName = nil, 
        },
        SwingData = {
            SmackDelay = 13,
            SwingRange = 48,
            SwingHullSize = 35.6,
            SwingHull = {Max = Vector3(17.8,17.8,17.8), Min = Vector3(-17.8,-17.8,-17.8)},
            TotalSwingRange = 48 + (35.6 / 2),
        },
    },
    Actions = {
        Can_Attack = false,
        Attacked = false,
        NextAttackTime = 0,
        NextAttackTime2 = 0,
        LastAttackTime = 0,
        TicksBeforeHit = 0,
    },
    vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
}

G.Target = {
    entity = nil,
    index = nil,
    AbsOrigin = Vector3(0,0,0),
    flags = 0,
    Viewheight = 75,
    ViewPos = Vector3(0,0,75),
    PredTicks = {},
    vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
}

G.Players = {}
G.ShouldFindTarget = false

function G.ResetTarget()
    G.Target = G.Defaults
end

function G.ResetLocal()
    G.pLocal = {
        entity = nil,
        Wentity = nil,
        index = 1,
        team = 1,
        Class = 1,
        AbsOrigin = Vector3{0, 0, 0},
        OnGround = true,
        ViewAngles = EulerAngles{0, 0, 0},
        Viewheight = Vector3{0, 0, 75},
        VisPos = Vector3{0, 0, 75},
        PredTicks = {},
        BacktrackTicks = {},
        AttackTicks = {},
        NextAttackTime = 0,
        WpData = {
            UsingMargetGarden = false,
            PWeapon = {
                Weapon = nil,
                WeaponData = nil,
                WeaponID = nil,
                WeaponDefIndex = nil,
                WeaponDef = nil,
                WeaponName = nil,
            },
            MWeapon = {
                Weapon = nil,
                WeaponData = nil,
                WeaponID = nil,
                WeaponDefIndex = nil,
                WeaponDef = nil,
                WeaponName = nil,
            },
            CurrWeapon = {
                Weapon = nil,
                WeaponData = nil,
                WeaponID = nil,
                WeaponDefIndex = nil,
                WeaponDef = nil,
                WeaponName = nil, 
            },
            SwingData = {
                SmackDelay = 13,
                SwingRange = 48,
                SwingHullSize = 35.6,
                SwingHull = {Max = Vector3(17.8,17.8,17.8), Min = Vector3(-17.8,-17.8,-17.8)},
                TotalSwingRange = 48 + (35.6 / 2),
            },
        },
        Actions = {
            CanSwing = false,
            Attacked = false,
            NextAttackTime = 0,
            NextAttackTime2 = 0,
            LastAttackTime = 0,
            TicksBeforeHit = 0,
            CanCharge = false,
        },
        BlastJump = false,
        ChargeLeft = 0,
        vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
    }
end

G.StrafeData = {
    Strafe = false,
    lastAngles = {}, ---@type table<number, Vector3>
    lastDeltas = {}, ---@type table<number, number>
    avgDeltas = {}, ---@type table<number, number>
    strafeAngles = {}, ---@type table<number, number>
    inaccuracy = {}, ---@type table<number, number>
    pastPositions = {}, -- Stores past positions of the local player
    maxPositions = 4, -- Number of past positions to consider
}

G.World = {
    Gravity = 800,
    StepHeight = 18,
    Lerp = 0,
    Latency = 0,
    LatIn = 0,
    Lat_out = 0,
}

G.Visuals = {
    SphereCache = {},
}

G.Gui = {
    IsVisible = false,
    FakeLatency = false,
    FakeLatencyAmount = 0,
    Backtrack = false,
    CritHackKey = gui.GetValue("Crit Hack Key")
}

return G