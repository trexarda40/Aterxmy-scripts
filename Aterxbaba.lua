repeat task.wait() until game:IsLoaded()

local Players, RunService, UIS, TS, Lighting, HS = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("TweenService"), game:GetService("Lighting"), game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ============================================================
-- GLOBALS
-- ============================================================
local NS, CS = 60, 30
local LAGGER_SPEED = 15
local LAGGER_CARRY_SPEED = 24.5
local speedMode, antiRagdollEnabled, infJumpEnabled = false, false, false
local laggerToggled = false
local laggerCarryToggled = false
local laggerPhase = 0
local medusaCounterEnabled = false
local medusaResetEnabled = false
local batCounterEnabled = false
local unwalkEnabled = false
local medusaDebounce, medusaLastUsed, dropActive = false, 0, false
local autoLeftEnabled, autoRightEnabled = false, false
local autoLeftSetVisual, autoRightSetVisual = nil, nil
local tpLockEnabled = false
local tpLockSetVisual = nil
local batV2Enabled = false
local batV2SetVisual = nil
local setBatCounterVisual = nil
local startBatCounter, stopBatCounter
local antiLagEnabled = false
local removeAccessoriesEnabled = false
local antiLagDescConn = nil
local stretchRezEnabled = false
local stretchRezConn = nil
local setStretchRezVisual = nil

local unwalkSavedAnimate = nil
local _anyKeyListening = false
local _lastKbSet = 0
local autoTPEnabled = false
local autoTPHeight = 20
local autoTPConn = nil
local setAutoTPVisual = nil
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
local setInfJumpVisual = nil
local mainFrame = nil
local bgImage = nil
local progressFill = nil
local progressPct = nil
local stealBarFrame = nil
local _guiLocked = false

setCarryVisual = nil
setLaggerVisual = nil
setAutoSwingVisual = nil
setBatCounterVisual = nil
setAntiRagVisual = nil
setMedusaVisual = nil
setMedusaResetVisual = nil
setUnwalkVisual = nil
setAntiLagVisual = nil
setStretchRezVisual = nil
setAutoTPVisual = nil
setSaturationVisual = nil
setVoidModeVisual = nil
setStretchRezV2Visual = nil
setTranspVisual = nil
setLockVisual = nil
setMobVisual = nil
setCircleBtnsVisual = nil
setShapeVisual = nil
setRectVisual = nil
setInstaGrab = nil
setInfJumpVisual = nil
setEspVisual = nil

local uiScaleValue = 0.6
local uiScaleObject = nil

local TOGGLE_ON_COLOR = Color3.fromRGB(160, 160, 160)

-- ============================================================
-- TP LOCK LOGIC (replaces Auto Bat)
-- ============================================================
local tpLockConn = nil
local tpLockPrevAutoRotate = nil
local tpLockHitCD = false
local TP_LOCK_SWING_CD = 0.08

local function findBat()
    local char = LP.Character
    if not char then return nil end
    for _, name in ipairs({"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}) do
        local t = char:FindFirstChild(name)
        if t and t:IsA("Tool") then return t end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, name in ipairs({"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}) do
            local t = bp:FindFirstChild(name)
            if t and t:IsA("Tool") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(t) end) end
                return t
            end
        end
    end
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
            return ch
        end
    end
    return nil
end

local function getClosestPlayer()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local d = (tRoot.Position - root.Position).Magnitude
                if d < minDist then minDist = d; closest = plr end
            end
        end
    end
    return closest, minDist
end

local function tpLockTryHit()
    if tpLockHitCD then return end
    tpLockHitCD = true
    pcall(function()
        local char = LP.Character
        if char then
            local bat = findBat()
            if bat then
                if bat.Parent ~= char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:EquipTool(bat) end) end
                end
                pcall(function() bat:Activate() end)
                local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
                if ev then pcall(function() ev:FireServer() end) end
            end
        end
    end)
    task.delay(TP_LOCK_SWING_CD, function() tpLockHitCD = false end)
end

local function startTPLock()
    if tpLockConn then tpLockConn:Disconnect() end
    if autoLeftEnabled then autoLeftEnabled = false; stopAutoLeft(); if autoLeftSetVisual then autoLeftSetVisual(false) end end
    if autoRightEnabled then autoRightEnabled = false; stopAutoRight(); if autoRightSetVisual then autoRightSetVisual(false) end end
    if batV2Enabled then toggleBatV2() end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if tpLockPrevAutoRotate == nil then tpLockPrevAutoRotate = hum.AutoRotate end
        hum.AutoRotate = false
    end
    tpLockConn = RunService.Heartbeat:Connect(function()
        if not tpLockEnabled then return end
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if not char:FindFirstChildOfClass("Tool") then
            local bat = findBat()
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end
        local target, targetDist = getClosestPlayer()
        if not target then return end
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if not tRoot then return end

        -- TP Lock logic
        if sethiddenproperty then
            pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tRoot) end)
        end
        local targetPos = tRoot.Position + Vector3.new(0, 0.9, 0)
        if (root.Position - targetPos).Magnitude > 8 then
            root.CFrame = CFrame.new(targetPos)
        end
        workspace.CurrentCamera.CFrame = CFrame.new(
            workspace.CurrentCamera.CFrame.Position, tRoot.Position
        )
        tpLockTryHit()
    end)
end

local function stopTPLock()
    if tpLockConn then tpLockConn:Disconnect(); tpLockConn = nil end
    tpLockHitCD = false
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if sethiddenproperty then pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", nil) end) end
    end
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = (tpLockPrevAutoRotate == nil) and true or tpLockPrevAutoRotate
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    tpLockPrevAutoRotate = nil
end

local function toggleTPLock()
    tpLockEnabled = not tpLockEnabled
    if tpLockEnabled then
        startTPLock()
        if tpLockSetVisual then tpLockSetVisual(true) end
        if mobBtnRefs.tpLock then mobBtnRefs.tpLock(true) end
    else
        stopTPLock()
        if tpLockSetVisual then tpLockSetVisual(false) end
        if mobBtnRefs.tpLock then mobBtnRefs.tpLock(false) end
    end
    return tpLockEnabled
end

-- ============================================================
-- BAT V2 (AIMBOT) – Settings exactly as specified:
-- Chase Speed 58, Hit Distance 8, Swing Cooldown 0.35,
-- Height Offset 3.7, Y Velocity Range -70..110.
-- NO PREDICTION – chases current position directly.
-- ============================================================
local batV2Conn = nil
local batV2PrevAutoRotate = nil
local batV2HitCD = false
local BAT_V2_SWING_CD = 0.35
local BAT_V2_HIT_DIST = 8
local BAT_V2_CHASE_SPEED = 58
local BAT_V2_VERTICAL_SPEED = 20
local BAT_V2_HEIGHT_OFFSET = 3.7
local BAT_V2_TURN_SPEED = 44
local BAT_V2_LERP_FACTOR = 0.8

local BAT_V2_SLAP_LIST = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local function _v2FindBat()
    local char = LP.Character; if not char then return nil end
    for _, name in ipairs(BAT_V2_SLAP_LIST) do
        local t = char:FindFirstChild(name)
        if t and t:IsA("Tool") then return t end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, name in ipairs(BAT_V2_SLAP_LIST) do
            local t = bp:FindFirstChild(name)
            if t and t:IsA("Tool") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(t) end) end
                return t
            end
        end
    end
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then return ch end
    end
    return nil
end

local function _v2TrySwing()
    if batV2HitCD then return end
    batV2HitCD = true
    pcall(function()
        local char = LP.Character; if not char then return end
        local bat = _v2FindBat()
        if bat then
            if bat.Parent ~= char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(bat) end) end
            end
            pcall(function() bat:Activate() end)
        end
    end)
    task.delay(BAT_V2_SWING_CD, function() batV2HitCD = false end)
end

local function _v2GetClosest()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then minDist = dist; closest = tRoot end
            end
        end
    end
    return closest, minDist
end

local function startBatV2()
    if batV2Conn then batV2Conn:Disconnect() end
    if autoLeftEnabled then autoLeftEnabled = false; stopAutoLeft(); if autoLeftSetVisual then autoLeftSetVisual(false) end end
    if autoRightEnabled then autoRightEnabled = false; stopAutoRight(); if autoRightSetVisual then autoRightSetVisual(false) end end
    if tpLockEnabled then toggleTPLock() end

    local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum0 then
        if batV2PrevAutoRotate == nil then batV2PrevAutoRotate = hum0.AutoRotate end
        hum0.AutoRotate = false
    end

    batV2Conn = RunService.RenderStepped:Connect(function()
        if not batV2Enabled then return end
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

        if not char:FindFirstChildOfClass("Tool") then
            local bat = _v2FindBat()
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end

        local target, targetDist = _v2GetClosest()
        if not target then return end

        local myPos = root.Position
        local targetPos = target.Position

        -- No prediction: aim directly at the target's current position
        local direction = targetPos - myPos
        local flatDir = Vector3.new(direction.X, 0, direction.Z)
        if flatDir.Magnitude > 0 then flatDir = flatDir.Unit else flatDir = Vector3.zero end

        local desiredHeight = targetPos.Y + BAT_V2_HEIGHT_OFFSET
        local yVel = (desiredHeight - myPos.Y) * BAT_V2_VERTICAL_SPEED
        if hum.FloorMaterial ~= Enum.Material.Air then
            yVel = math.max(yVel, 13)
        end
        yVel = math.clamp(yVel, -70, 110)   -- Y velocity range -70 to 110

        local desiredVel = Vector3.new(flatDir.X * BAT_V2_CHASE_SPEED, yVel, flatDir.Z * BAT_V2_CHASE_SPEED)
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, BAT_V2_LERP_FACTOR)

        -- Turn towards the current target position
        local toTarget = targetPos - myPos
        if toTarget.Magnitude > 0.1 then
            local goalCF = CFrame.lookAt(myPos, targetPos)
            local diffCF = root.CFrame:Inverse() * goalCF
            local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
            rx = math.clamp(rx, -2.5, 2.5)
            ry = math.clamp(ry, -2.5, 2.5)
            rz = math.clamp(rz, -2.5, 2.5)
            root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(
                Vector3.new(rx * BAT_V2_TURN_SPEED, ry * BAT_V2_TURN_SPEED, rz * BAT_V2_TURN_SPEED)
            )
        end

        if targetDist <= BAT_V2_HIT_DIST then _v2TrySwing() end
    end)
end

local function stopBatV2()
    if batV2Conn then batV2Conn:Disconnect(); batV2Conn = nil end
    batV2HitCD = false
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = (batV2PrevAutoRotate == nil) and true or batV2PrevAutoRotate
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    batV2PrevAutoRotate = nil
end

local function toggleBatV2()
    batV2Enabled = not batV2Enabled
    if batV2Enabled then
        startBatV2()
        if batV2SetVisual then batV2SetVisual(true) end
        if mobBtnRefs.batV2 then mobBtnRefs.batV2(true) end
    else
        stopBatV2()
        if batV2SetVisual then batV2SetVisual(false) end
        if mobBtnRefs.batV2 then mobBtnRefs.batV2(false) end
    end
    return batV2Enabled
end

-- ============================================================
-- MOBILE BUTTONS STATE
-- ============================================================
local guiTransparencyEnabled = false
local mobileButtonsEnabled = true
local mobileButtonsSize = 80
local circleButtonsEnabled = false
local shapeButtonsEnabled = false
local rectangularButtonsEnabled = false
local mobBtnRefs = {}
local mobGuiRef = nil
local antiKickEnabled = false
local antiKickSetVisual = nil
local infJumpMode = "manual"
local holdInfJumpConn = nil
local uiLocked = false
local perButtonDragEnabled = true
local autoSwitchSpeedEnabled = false

local BTN_OFF = Color3.fromRGB(0, 0, 0)
local BTN_ON = Color3.fromRGB(160, 160, 160)
local TEXT_OFF = Color3.fromRGB(255, 255, 255)
local TEXT_ON = Color3.fromRGB(255, 255, 255)

-- ============================================================
-- KEYBINDS
-- ============================================================
local KB = {
    DropBrainrot  = {kb = Enum.KeyCode.X,           gp = nil},
    AutoLeft      = {kb = Enum.KeyCode.Z,           gp = nil},
    AutoRight     = {kb = Enum.KeyCode.C,           gp = nil},
    TPLock        = {kb = Enum.KeyCode.E,           gp = nil},
    TPFloor       = {kb = Enum.KeyCode.F,           gp = nil},
    GuiHide       = {kb = Enum.KeyCode.LeftControl, gp = nil},
    SpeedToggle   = {kb = Enum.KeyCode.Q,           gp = nil},
    LaggerToggle  = {kb = Enum.KeyCode.R,           gp = nil},
    InstaReset    = {kb = Enum.KeyCode.G,           gp = nil},
    BatV2Toggle   = {kb = Enum.KeyCode.V,           gp = nil}
}

local function isGamepadInput(inp)
    if not inp then return false end
    if inp.UserInputType and inp.UserInputType.Name:match("^Gamepad") then return true end
    return false
end

local function isBindableInput(inp)
    if not inp or inp.KeyCode == Enum.KeyCode.Unknown then return false end
    if inp.UserInputType == Enum.UserInputType.Keyboard then return true end
    return isGamepadInput(inp)
end

local CONTROLLER_BUTTONS = {
    [Enum.KeyCode.ButtonA]      = "A",       [Enum.KeyCode.ButtonB]      = "B",
    [Enum.KeyCode.ButtonX]      = "X",       [Enum.KeyCode.ButtonY]      = "Y",
    [Enum.KeyCode.ButtonL1]     = "LB",      [Enum.KeyCode.ButtonR1]     = "RB",
    [Enum.KeyCode.ButtonL2]     = "LT",      [Enum.KeyCode.ButtonR2]     = "RT",
    [Enum.KeyCode.ButtonL3]     = "LS",      [Enum.KeyCode.ButtonR3]     = "RS",
    [Enum.KeyCode.ButtonStart]  = "START",   [Enum.KeyCode.ButtonSelect] = "SELECT",
    [Enum.KeyCode.DPadUp]       = "DPAD_UP", [Enum.KeyCode.DPadLeft]     = "DPAD_LEFT",
    [Enum.KeyCode.DPadRight]    = "DPAD_RIGHT"
}

local function getKeyDisplayName(key, isGp)
    if isGp and CONTROLLER_BUTTONS[key] then return CONTROLLER_BUTTONS[key] end
    return key and key.Name or "None"
end

local function kbMatch(entry, kc)
    return kc and (kc == entry.kb or (entry.gp and kc == entry.gp))
end

-- ============================================================
-- LAGGER ENGINE (unchanged)
-- ============================================================
local laggerState = {enabled = false, thread = nil, waitTime = 0.25, intensity = 270}
local isTouchEnabled = UIS.TouchEnabled
if isTouchEnabled then laggerState.waitTime = 5.8 end
local _laggerActive = false

local function createNestedTable(amount)
    local nested = {{}}; local current = nested[1]
    for i = 1, amount do local t = {}; table.insert(current, t); current = t end
    return nested
end

local function sendLagSpam()
    local nested = createNestedTable(laggerState.intensity)
    local payload = {}
    local maxCopies = math.min(499999 / (laggerState.intensity + 2), 1500)
    for i = 1, maxCopies do table.insert(payload, nested) end
    pcall(function()
        local r = game:GetService("RobloxReplicatedStorage"):FindFirstChild("SetPlayerBlockList")
        if r then r:FireServer(payload) end
    end)
end

local function removeNetworkLimit()
    pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
end

local function startLaggerEngine()
    if laggerState.thread then task.cancel(laggerState.thread); laggerState.thread = nil end
    laggerState.enabled = true
    laggerState.thread = task.spawn(function()
        while laggerState.enabled do removeNetworkLimit(); sendLagSpam(); task.wait(laggerState.waitTime) end
    end)
end

local function stopLaggerEngine()
    laggerState.enabled = false
    if laggerState.thread then task.cancel(laggerState.thread); laggerState.thread = nil end
end

-- ============================================================
-- MOVEMENT & SPEED
-- ============================================================
local AP_L1, AP_L2 = Vector3.new(-476.47,-6.28,92.73), Vector3.new(-483.12,-4.95,94.81)
local AP_R1, AP_R2 = Vector3.new(-476.16,-6.52,25.62), Vector3.new(-483.06,-5.03,25.48)

local function getActiveMoveSpeed()
    if laggerCarryToggled then return LAGGER_CARRY_SPEED
    elseif laggerToggled then return LAGGER_SPEED
  
