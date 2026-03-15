local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

getgenv().show_circle = false
getgenv().Aimbot = false
getgenv().Smoothness = 1
getgenv().FOV = 180

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Visible = true
circle.Color = Color3.fromRGB(255, 50, 50)
circle.Transparency = 0.5

local function get_target()
    local target = nil
    local dist = getgenv().FOV
    local mouse = uis:GetMouseLocation()

    for _, v in pairs(plrs:GetPlayers()) do
        -- make sure they aren't us and they are actually alive
        if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            
            -- check for head hitboxes first, then normal head
            local part = v.Character:FindFirstChild("HeadHB") or v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("UpperTorso")
            
            if part then
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
    circle.Visible = getgenv().Aimbot and show_circle
    circle.Radius = getgenv().FOV
    circle.Position = uis:GetMouseLocation()

    if uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and getgenv().Aimbot then -- change MouseButton2 to anything else if you don't want to lock with holding right click
        local target = get_target()
        
        if target then
            local pos, _ = cam:WorldToViewportPoint(target.Position)
            local mouse_loc = uis:GetMouseLocation()
            
            local x = (pos.X - mouse_loc.X) * getgenv().Smoothness
            local y = (pos.Y - mouse_loc.Y) * getgenv().Smoothness
            
            if mousemoverel then
                mousemoverel(x, y)
            end
        end
    end
end)
