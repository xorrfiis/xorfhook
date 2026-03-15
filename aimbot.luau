local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputType")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- defaults (GUI will overwrite these)
getgenv().show_circle = getgenv().show_circle or false
getgenv().Aimbot = getgenv().Aimbot or false
getgenv().SilentAim = getgenv().SilentAim or false -- NEW: Silent Aim toggle
getgenv().SilentAimChance = getgenv().SilentAimChance or 100 -- NEW: Hit chance %
getgenv().Smoothness = getgenv().Smoothness or 1
getgenv().FOV = getgenv().FOV or 180
getgenv().TeamCheck = getgenv().TeamCheck ~= false
getgenv().WallCheck = getgenv().WallCheck ~= false
getgenv().HitPart = getgenv().HitPart or "Head" -- NEW: Target part (Head, Torso, etc.)

-- Universal mousemoverel detection
local mousemoverel_func = nil
local function getMouseMoveRel()
    if mousemoverel_func then return mousemoverel_func end
    
    -- Check various executor implementations
    if typeof(mousemoverel) == "function" then
        mousemoverel_func = mousemoverel
    elseif typeof(syn) == "table" and typeof(syn.mousemoverel) == "function" then
        mousemoverel_func = syn.mousemoverel
    elseif typeof(fluxus) == "table" and typeof(fluxus.mousemoverel) == "function" then
        mousemoverel_func = fluxus.mousemoverel
    elseif typeof(KRNL) == "table" and typeof(KRNL.mousemoverel) == "function" then
        mousemoverel_func = KRNL.mousemoverel
    elseif typeof(YUBX) == "table" and typeof(YUBX.mousemoverel) == "function" then
        mousemoverel_func = YUBX.mousemoverel
    elseif typeof(Xeno) == "table" and typeof(Xeno.mousemoverel) == "function" then
        mousemoverel_func = Xeno.mousemoverel
    elseif typeof(hookfunction) == "function" then
        -- Fallback: use input injection if available
        local VirtualInputManager = game:GetService("VirtualInputManager")
        mousemoverel_func = function(x, y)
            VirtualInputManager:SendMouseMoveEvent(x, y, game)
        end
    end
    
    return mousemoverel_func
end

-- Drawing setup with fallback
local DrawingLib = Drawing or {}
local circle

local function setupCircle()
    if typeof(DrawingLib.new) == "function" then
        circle = DrawingLib.new("Circle")
        circle.Thickness = 2
        circle.Visible = false
        circle.Color = Color3.fromRGB(255, 50, 50)
        circle.Transparency = 0.5
        circle.Filled = false
    else
        warn("[Xorfhook] Drawing library not available")
    end
end

setupCircle()

-- Wall check with improved raycasting
local function is_visible(part)
    if not part or not part.Parent then return false end
    
    local origin = cam.CFrame.Position
    local direction = (part.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit * distance

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {lp.Character, cam}
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)

    if result then
        local instance = result.Instance
        local isVisible = instance:IsDescendantOf(part.Parent) or 
                         (instance.Parent and instance.Parent:IsDescendantOf(part.Parent))
        return isVisible
    end

    return true -- No obstruction found
end

-- Get target part based on settings
local function getTargetPart(character)
    local hitPart = getgenv().HitPart or "Head"
    local part = character:FindFirstChild(hitPart)
    
    if not part then
        -- Fallback priority
        part = character:FindFirstChild("Head") or 
               character:FindFirstChild("HumanoidRootPart") or
               character:FindFirstChild("UpperTorso") or
               character:FindFirstChild("Torso")
    end
    
    return part
end

-- Target acquisition (shared between aimbot and silent aim)
local function get_target()
    local target = nil
    local dist = getgenv().FOV
    local mouse = uis:GetMouseLocation()

    for _, v in pairs(plrs:GetPlayers()) do
        if v ~= lp and v.Character then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            local head = getTargetPart(v.Character)

            if humanoid and humanoid.Health > 0 and head then
                -- Team check
                if getgenv().TeamCheck and v.Team == lp.Team then
                    continue
                end

                -- Wall check
                if getgenv().WallCheck and not is_visible(head) then
                    continue
                end

                local pos, on_screen = cam:WorldToViewportPoint(head.Position)

                if on_screen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude

                    if mag < dist then
                        dist = mag
                        target = {
                            Player = v,
                            Part = head,
            Position = head.Position,
            ScreenPos = pos
                        }
                    end
                end
            end
        end
    end

    return target
end

-- ============================================
-- SILENT AIM IMPLEMENTATION
-- ============================================
local SilentAimConnection
local originalNamecall
local silentAimTarget = nil

local function setupSilentAim()
    -- Hook into remote events for bullet firing
    local mt = getrawmetatable(game)
    if not mt then
        warn("[Xorfhook] Silent Aim: Cannot get metatable")
        return
    end
    
    setreadonly(mt, false)
    originalNamecall = mt.__namecall
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Check if silent aim is enabled and we have a target
        if getgenv().SilentAim and silentAimTarget and math.random(1, 100) <= (getgenv().SilentAimChance or 100) then
            -- Intercept Raycast/FindPartOnRay for bullet hit registration
            if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                -- Modify ray direction to hit target
                local origin = args[1]
                if typeof(origin) == "Vector3" and silentAimTarget.Position then
                    local direction = (silentAimTarget.Position - origin).Unit * 1000
                    args[2] = direction
                    return originalNamecall(self, unpack(args))
                end
            end
            
            -- Intercept FireServer for gun remotes (common in Rivals-style games)
            if method == "FireServer" then
                local remoteName = tostring(self)
                -- Common gun remote names
                if remoteName:lower():find("shoot") or 
                   remoteName:lower():find("fire") or 
                   remoteName:lower():find("hit") or
                   remoteName:lower():find("damage") or
                   remoteName:lower():find("bullet") then
                    
                    -- Try to modify hit position in args
                    for i, arg in pairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = silentAimTarget.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(silentAimTarget.Position)
                        elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            args[i] = silentAimTarget.Part
                        elseif typeof(arg) == "table" then
                            -- Deep scan for position data
                            for k, v in pairs(arg) do
                                if typeof(v) == "Vector3" then
                                    arg[k] = silentAimTarget.Position
                                elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                                    arg[k] = silentAimTarget.Part
                                end
                            end
                        end
                    end
                end
            end
        end
        
        return originalNamecall(self, ...)
    end)
    
    setreadonly(mt, true)
    
    -- Update target loop
    SilentAimConnection = rs.RenderStepped:Connect(function()
        if getgenv().SilentAim then
            silentAimTarget = get_target()
        else
            silentAimTarget = nil
        end
    end)
end

-- Setup silent aim
local silentAimSuccess, silentAimErr = pcall(setupSilentAim)
if not silentAimSuccess then
    warn("[Xorfhook] Silent Aim setup failed: " .. tostring(silentAimErr))
end

-- Main loop with proper error handling
local connection
connection = rs.RenderStepped:Connect(function()
    local success, err = pcall(function()
        -- Update circle
        if circle then
            circle.Visible = (getgenv().Aimbot or getgenv().SilentAim) and getgenv().show_circle
            if circle.Visible then
                circle.Radius = getgenv().FOV
                circle.Position = uis:GetMouseLocation()
                
                -- Change color based on mode
                if getgenv().SilentAim and silentAimTarget then
                    circle.Color = Color3.fromRGB(50, 255, 50) -- Green for silent aim lock
                elseif getgenv().Aimbot then
                    circle.Color = Color3.fromRGB(255, 50, 50) -- Red for regular aimbot
                end
            end
        end

        -- Regular Aimbot logic (only if silent aim is off)
        if getgenv().Aimbot and not getgenv().SilentAim and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = get_target()

            if target and target.Part and target.Part.Parent then
                local pos = cam:WorldToViewportPoint(target.Position)
                local mouse_loc = uis:GetMouseLocation()

                local smooth = math.clamp(getgenv().Smoothness, 0.1, 5)
                local x = (pos.X - mouse_loc.X) / smooth
                local y = (pos.Y - mouse_loc.Y) / smooth

                local mouseMoveRel = getMouseMoveRel()
                if mouseMoveRel then
                    mouseMoveRel(x, y)
                end
            end
        end
    end)
    
    if not success then
        warn("[Xorfhook Aimbot] Error: " .. tostring(err))
    end
end)

-- Cleanup on error or script destruction
getgenv().XorfhookAimbotConnection = connection
getgenv().XorfhookSilentAimConnection = SilentAimConnection
