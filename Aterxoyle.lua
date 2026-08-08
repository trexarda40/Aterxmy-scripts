repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HS = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ============================================================
-- HUB INFORMATION
-- ============================================================
local HUB_NAME = "Aterx Hub"

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

local setCarryVisual = nil
local setLaggerVisual = nil
local setAutoSwingVisual = nil
local setAntiRagVisual = nil
local setMedusaVisual = nil
local setMedusaResetVisual = nil
local setUnwalkVisual = nil
local setAntiLagVisual = nil
local setSaturationVisual = nil
local setVoidModeVisual = nil
local setStretchRezV2Visual = nil
local setTranspVisual = nil
local setLockVisual = nil
local setMobVisual = nil
local setCircleBtnsVisual = nil
local setShapeVisual = nil
local setRectVisual = nil
local setInstaGrab = nil
local setEspVisual = nil

local uiScaleValue = 0.6
local uiScaleObject = nil

local TOGGLE_ON_COLOR = Color3.fromRGB(160, 160, 160)

local mobBtnRefs = {
    tpLock = function() end,
    batV2 = function() end
}

local function stopAutoLeft() end
local function stopAutoRight() end

-- ============================================================
-- MOVEMENT & SPEED
-- ============================================================
local function getActiveMoveSpeed()
    if laggerCarryToggled then 
        return LAGGER_CARRY_SPEED
    elseif laggerToggled then 
        return LAGGER_SPEED
    elseif speedMode then
        return CS
    else
        return NS
    end
end

RunService.Stepped:Connect(function()
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = getActiveMoveSpeed()
        end
    end
end)

print(HUB_NAME .. " yuklendi!")
