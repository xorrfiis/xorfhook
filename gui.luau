-- Global settings with safe initialization
getgenv().ESPEnabled = getgenv().ESPEnabled or false
getgenv().ESPColor = getgenv().ESPColor or Color3.fromRGB(255, 0, 0)
getgenv().ESPBox = getgenv().ESPBox or false
getgenv().ESPName = getgenv().ESPName or true
getgenv().ESPHealth = getgenv().ESPHealth or true
getgenv().ESPDistance = getgenv().ESPDistance or false
getgenv().SpeedEnabled = getgenv().SpeedEnabled or false

-- AIMBOT - NEW CLEAN NAMES
getgenv().AimbotEnabled = getgenv().AimbotEnabled or false
getgenv().AimbotSmoothness = getgenv().AimbotSmoothness or 1
getgenv().AimbotFOV = getgenv().AimbotFOV or 180
getgenv().AimbotTeamCheck = getgenv().AimbotTeamCheck ~= false
getgenv().AimbotWallCheck = getgenv().AimbotWallCheck ~= false
getgenv().AimbotHitPart = getgenv().AimbotHitPart or "Head"
getgenv().AimbotShowFOV = getgenv().AimbotShowFOV or false

-- TRIGGERBOT
getgenv().TriggerbotEnabled = getgenv().TriggerbotEnabled or false
getgenv().TriggerbotDelay = getgenv().TriggerbotDelay or 0

-- Crosshair settings
getgenv().CrosshairEnabled = getgenv().CrosshairEnabled or false
getgenv().CrosshairColor = getgenv().CrosshairColor or Color3.fromRGB(255, 255, 255)
getgenv().CrosshairSize = getgenv().CrosshairSize or 10
getgenv().CrosshairThickness = getgenv().CrosshairThickness or 2
getgenv().CrosshairGap = getgenv().CrosshairGap or 4
getgenv().CrosshairDot = getgenv().CrosshairDot or true
getgenv().CrosshairOutline = getgenv().CrosshairOutline or true

-- Fly settings
getgenv().FlyEnabled = getgenv().FlyEnabled or false
getgenv().FlySpeed = getgenv().FlySpeed or 50
getgenv().FlyKey = getgenv().FlyKey or "F"

-- ============================================
-- INTEGRATED SPOOFER FUNCTIONS
-- ============================================
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SetControls = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")

getgenv().SpoofFunctions = {
    spoofPC = function()
        SetControls:FireServer("MouseKeyboard")
    end,
    spoofController = function()
        SetControls:FireServer("Gamepad")
    end,
    spoofMobile = function()
        SetControls:FireServer("Touch")
    end,
    spoofVR = function()
        SetControls:FireServer("VR")
    end
}

-- ============================================
-- DEFERRED MODULE LOADER
-- ============================================
local function loadModule(url, name, delay)
    task.spawn(function()
        task.wait(delay or 0)
        
        local success, result = pcall(function()
            local content = game:HttpGet(url, true)
            if content and #content > 0 then
                local func, err = loadstring(content)
                if func then
                    return func
                else
                    error("Loadstring failed: " .. tostring(err))
                end
            end
        end)
        
        if success and result then
            local execSuccess, execErr = pcall(result)
            if execSuccess then
                print("[Xorfhook] " .. name .. " loaded successfully")
            else
                warn("[Xorfhook] " .. name .. " execution error: " .. tostring(execErr))
            end
        else
            warn("[Xorfhook] " .. name .. " failed to load: " .. tostring(result))
        end
    end)
end

-- Load modules with longer delays
loadModule("https://raw.githubusercontent.com/xorrfiis/xorfhook/main/aimbot.luau", "Aimbot", 2.0)
loadModule("https://raw.githubusercontent.com/xorrfiis/xorfhook/main/esp.luau", "ESP", 4.0)
loadModule("https://raw.githubusercontent.com/xorrfiis/xorfhook/main/crosshair.luau", "Crosshair", 6.0)

-- ============================================
-- LIBRARY LOADING
-- ============================================
local function loadLibrary(url, retries)
    retries = retries or 3
    for i = 1, retries do
        local success, result = pcall(function()
            return loadstring(game:HttpGet(url, true))()
        end)
        if success then
            return result
        end
        warn("[Xorfhook] Library load attempt " .. i .. "/" .. retries .. " failed")
        task.wait(0.1)
    end
    return nil
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadLibrary(repo .. 'Library.lua')
if not Library then
    error("[Xorfhook] Failed to load Linoria Library")
end

local ThemeManager = loadLibrary(repo .. 'addons/ThemeManager.lua')
local SaveManager = loadLibrary(repo .. 'addons/SaveManager.lua')

-- Create window
local Window = Library:CreateWindow({
    Title = 'Xorfhook | Rivals',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Aiming = Window:AddTab('Aiming'),
    Visual = Window:AddTab('Visual'),
    Misc = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings')
}

-- ============================================
-- AIMING TAB - LEFT SIDE (Aimbot Only)
-- ============================================
local AimbotBox = Tabs.Aiming:AddLeftGroupbox("Aimbot")

AimbotBox:AddToggle("AimbotEnabled", {
    Text = "Enable Aimbot",
    Default = getgenv().AimbotEnabled,
    Callback = function(Value)
        getgenv().AimbotEnabled = Value
    end
})

AimbotBox:AddToggle("AimbotTeamCheck", {
    Text = "Team Check",
    Default = getgenv().AimbotTeamCheck,
    Callback = function(Value)
        getgenv().AimbotTeamCheck = Value
    end
})

AimbotBox:AddToggle("AimbotWallCheck", {
    Text = "Wall Check",
    Default = getgenv().AimbotWallCheck,
    Callback = function(Value)
        getgenv().AimbotWallCheck = Value
    end
})

AimbotBox:AddToggle("AimbotShowFOV", {
    Text = "Show FOV Circle",
    Default = getgenv().AimbotShowFOV,
    Callback = function(Value)
        getgenv().AimbotShowFOV = Value
    end
})

AimbotBox:AddSlider("AimbotFOV", {
    Text = "FOV",
    Default = getgenv().AimbotFOV,
    Min = 50,
    Max = 800,
    Rounding = 0,
    Callback = function(Value)
        getgenv().AimbotFOV = Value
    end
})

AimbotBox:AddSlider("AimbotSmoothness", {
    Text = "Smoothness",
    Default = getgenv().AimbotSmoothness,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        getgenv().AimbotSmoothness = Value
    end
})

AimbotBox:AddDropdown("AimbotHitPart", {
    Text = "Target Part",
    Default = getgenv().AimbotHitPart,
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
    Callback = function(Value)
        getgenv().AimbotHitPart = Value
    end
})

-- ============================================
-- AIMING TAB - RIGHT SIDE (Triggerbot Only)
-- ============================================
local TriggerbotBox = Tabs.Aiming:AddRightGroupbox("Triggerbot")

TriggerbotBox:AddToggle("TriggerbotEnabled", {
    Text = "Enable Triggerbot",
    Default = getgenv().TriggerbotEnabled,
    Callback = function(Value)
        getgenv().TriggerbotEnabled = Value
    end
})

TriggerbotBox:AddSlider("TriggerbotDelay", {
    Text = "Delay (ms)",
    Default = getgenv().TriggerbotDelay,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        getgenv().TriggerbotDelay = Value
    end
})

TriggerbotBox:AddLabel("Auto-shoot when hovering")
TriggerbotBox:AddLabel("over enemy player.")

-- ============================================
-- VISUAL TAB
-- ============================================
local ESPSettingsBox = Tabs.Visual:AddLeftGroupbox("ESP Settings")

ESPSettingsBox:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = getgenv().ESPEnabled,
    Callback = function(v)
        getgenv().ESPEnabled = v
    end
})

ESPSettingsBox:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
    Default = getgenv().ESPColor,
    Callback = function(Value)
        getgenv().ESPColor = Value
    end
})

local ESPFeaturesBox = Tabs.Visual:AddRightGroupbox("ESP Features")

ESPFeaturesBox:AddToggle("ESPBoxToggle", {
    Text = "Box ESP",
    Default = getgenv().ESPBox,
    Callback = function(Value)
        getgenv().ESPBox = Value
    end
})

ESPFeaturesBox:AddToggle("ESPNameToggle", {
    Text = "Show Names",
    Default = getgenv().ESPName,
    Callback = function(Value)
        getgenv().ESPName = Value
    end
})

ESPFeaturesBox:AddToggle("ESPHealthToggle", {
    Text = "Show Health",
    Default = getgenv().ESPHealth,
    Callback = function(Value)
        getgenv().ESPHealth = Value
    end
})

ESPFeaturesBox:AddToggle("ESPDistanceToggle", {
    Text = "Show Distance",
    Default = getgenv().ESPDistance,
    Callback = function(Value)
        getgenv().ESPDistance = Value
    end
})

local CrosshairBox = Tabs.Visual:AddRightGroupbox("Custom Crosshair")

CrosshairBox:AddToggle("CrosshairEnabled", {
    Text = "Enable Crosshair",
    Default = getgenv().CrosshairEnabled,
    Callback = function(Value)
        getgenv().CrosshairEnabled = Value
    end
})

CrosshairBox:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColorPicker", {
    Default = getgenv().CrosshairColor,
    Callback = function(Value)
        getgenv().CrosshairColor = Value
    end
})

CrosshairBox:AddSlider("CrosshairSize", {
    Text = "Line Length",
    Default = getgenv().CrosshairSize,
    Min = 2,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairSize = Value
    end
})

CrosshairBox:AddSlider("CrosshairThickness", {
    Text = "Line Thickness",
    Default = getgenv().CrosshairThickness,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairThickness = Value
    end
})

CrosshairBox:AddSlider("CrosshairGap", {
    Text = "Center Gap",
    Default = getgenv().CrosshairGap,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CrosshairGap = Value
    end
})

CrosshairBox:AddToggle("CrosshairDot", {
    Text = "Show Center Dot",
    Default = getgenv().CrosshairDot,
    Callback = function(Value)
        getgenv().CrosshairDot = Value
    end
})

CrosshairBox:AddToggle("CrosshairOutline", {
    Text = "Black Outline",
    Default = getgenv().CrosshairOutline,
    Callback = function(Value)
        getgenv().CrosshairOutline = Value
    end
})

-- ============================================
-- MISC TAB
-- ============================================
local DeviceSpooferBox = Tabs.Misc:AddLeftGroupbox('Device Spoofer')

local function callSpoofer(funcName, displayName)
    if getgenv().SpoofFunctions and typeof(getgenv().SpoofFunctions[funcName]) == "function" then
        local success, err = pcall(getgenv().SpoofFunctions[funcName])
        if success then
            Library:Notify("Spoofed as " .. displayName .. "!", 2)
        else
            Library:Notify("Failed to spoof!", 3)
        end
    else
        Library:Notify("Spoofer not ready!", 3)
    end
end

DeviceSpooferBox:AddButton({
    Text = 'Spoof PC',
    Func = function()
        callSpoofer("spoofPC", "PC")
    end,
    DoubleClick = false
})

DeviceSpooferBox:AddButton({
    Text = 'Spoof Controller',
    Func = function()
        callSpoofer("spoofController", "Controller")
    end,
    DoubleClick = false
})

DeviceSpooferBox:AddButton({
    Text = 'Spoof Mobile',
    Func = function()
        callSpoofer("spoofMobile", "Mobile")
    end,
    DoubleClick = false
})

DeviceSpooferBox:AddButton({
    Text = 'Spoof VR',
    Func = function()
        callSpoofer("spoofVR", "VR")
    end,
    DoubleClick = false
})

local statusLabel = DeviceSpooferBox:AddLabel("Spoofer ready!")

local FlyBox = Tabs.Misc:AddRightGroupbox('Fly')

FlyBox:AddToggle("FlyToggle", {
    Text = "Enable Fly",
    Default = getgenv().FlyEnabled,
    Callback = function(Value)
        getgenv().FlyEnabled = Value
        if Value then
            Library:Notify("Fly enabled! Press " .. (getgenv().FlyKey or "F") .. " to toggle in-game.", 3)
        end
    end
})

FlyBox:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = getgenv().FlySpeed,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        getgenv().FlySpeed = Value
    end
})

FlyBox:AddInput("FlyKeybind", {
    Text = "Toggle Key",
    Default = getgenv().FlyKey or "F",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        getgenv().FlyKey = Value:upper()
    end
})

FlyBox:AddLabel("Controls: WASD to move,")
FlyBox:AddLabel("Space/Shift for up/down")
FlyBox:AddLabel("Press key to toggle fly mode")

-- ============================================
-- SETTINGS TAB
-- ============================================
if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder('Xorfhook')
    ThemeManager:ApplyToTab(Tabs.Settings)
end

if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetFolder('Xorfhook')
    SaveManager:BuildConfigSection(Tabs.Settings)
    SaveManager:LoadAutoloadConfig()
end

-- ============================================
-- UNLOAD BUTTON - FIXED!
-- ============================================
local UnloadBox = Tabs.Settings:AddRightGroupbox("Script Management")

UnloadBox:AddButton({
    Text = 'Unload Xorfhook',
    Func = function()
        -- Disable all features first
        getgenv().Aimbot = false
        getgenv().SilentAim = false
        getgenv().Triggerbot = false
        getgenv().ESPEnabled = false
        getgenv().CrosshairEnabled = false
        getgenv().FlyEnabled = false
        
        -- Wait a frame for features to stop
        task.wait()
        
        -- Call all cleanup functions
        local function safeCleanup(name, func)
            if func then
                local success, err = pcall(func)
                if not success then
                    warn("[Xorfhook Unload] " .. name .. " cleanup failed: " .. tostring(err))
                end
            end
        end
        
        safeCleanup("Aimbot Connection", function()
            if getgenv().XorfhookAimbotConnection then
                getgenv().XorfhookAimbotConnection:Disconnect()
                getgenv().XorfhookAimbotConnection = nil
            end
        end)
        
        safeCleanup("ESP Connection", function()
            if getgenv().XorfhookESPConnection then
                getgenv().XorfhookESPConnection:Disconnect()
                getgenv().XorfhookESPConnection = nil
            end
        end)
        
        safeCleanup("ESP Cleanup", getgenv().XorfhookESPCleanup)
        
        safeCleanup("Crosshair Connection", function()
            if getgenv().XorfhookCrosshairConnection then
                getgenv().XorfhookCrosshairConnection:Disconnect()
                getgenv().XorfhookCrosshairConnection = nil
            end
        end)
        
        safeCleanup("Crosshair Cleanup", getgenv().XorfhookCrosshairCleanup)
        
        safeCleanup("Fly", function()
            if getgenv().XorfhookFly and getgenv().XorfhookFly.Stop then
                getgenv().XorfhookFly.Stop()
            end
        end)
        
        -- Destroy Linoria GUI manually
        safeCleanup("GUI", function()
            -- Find and destroy the ScreenGui
            local playerGui = lp:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and (gui.Name:find("Linoria") or gui.Name:find("Xorfhook")) then
                        gui:Destroy()
                    end
                end
            end
            
            -- Also try to find by common Linoria patterns
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("ScreenGui") then
                    -- Check if it has Linoria elements
                    local hasLinoria = false
                    for _, child in pairs(gui:GetDescendants()) do
                        if child.Name:find("Linoria") or child.Name:find("Library") then
                            hasLinoria = true
                            break
                        end
                    end
                    if hasLinoria then
                        gui:Destroy()
                    end
                end
            end
        end)
        
        -- Alternative: try Window.Unload if it exists
        if Window and typeof(Window.Unload) == "function" then
            safeCleanup("Window.Unload", function()
                Window:Unload()
            end)
        end
        
        -- Clear global vars
        getgenv().AimbotEnabled = false
        getgenv().TriggerbotEnabled = false
        getgenv().ESPEnabled = false
        getgenv().CrosshairEnabled = false
        getgenv().FlyEnabled = false
        
        print("[Xorfhook] Unloaded successfully!")
    end,
    DoubleClick = true
})

UnloadBox:AddLabel("Double-click to confirm unload")
UnloadBox:AddLabel("This will disable all features")

print("[Xorfhook] GUI loaded successfully!")
