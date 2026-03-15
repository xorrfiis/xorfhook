local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- defaults (GUI will overwrite these)
getgenv().show_circle = false
getgenv().Aimbot = false
getgenv().Smoothness = 1
getgenv().FOV = 180
getgenv().TeamCheck = true
getgenv().WallCheck = true

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Visible = true
circle.Color = Color3.fromRGB(255, 50, 50)
circle.Transparency = 0.5

-- wall check
local function is_visible(part)
    local origin = cam.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {lp.Character}

    local result = workspace:Raycast(origin, direction, params)

    if result then
        return result.Instance:IsDescendantOf(part.Parent)
    end

    return false
end

local function get_target()
    local target = nil
    local dist = getgenv().FOV
    local mouse = uis:GetMouseLocation()

    for _, v in pairs(plrs:GetPlayers()) do

        if v ~= lp
        and v.Character
        and v.Character:FindFirstChild("Humanoid")
        and v.Character.Humanoid.Health > 0
        and (not getgenv().TeamCheck or v.Team ~= lp.Team) then

            local part =
                v.Character:FindFirstChild("HeadHB")
                or v.Character:FindFirstChild("Head")
                or v.Character:FindFirstChild("UpperTorso")

            if part and (not getgenv().WallCheck or is_visible(part)) then

                local pos, on_screen = cam:WorldToViewportPoint(part.Position)

                if on_screen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude

                    if mag < dist then
                        dist = mag
                        target = part
                    end
                end
            end
        end
    end

    return target
end

rs.RenderStepped:Connect(function()

    circle.Visible = getgenv().Aimbot and getgenv().show_circle
    circle.Radius = getgenv().FOV
    circle.Position = uis:GetMouseLocation()

    if getgenv().Aimbot and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then

        local target = get_target()

        if target then
            local pos = cam:WorldToViewportPoint(target.Position)
            local mouse_loc = uis:GetMouseLocation()

            local x = (pos.X - mouse_loc.X) * getgenv().Smoothness
            local y = (pos.Y - mouse_loc.Y) * getgenv().Smoothness

            if mousemoverel then
                mousemoverel(x, y)
            end
        end

    end
end)
