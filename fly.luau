local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

RunService.RenderStepped:Connect(function()
    if getgenv().FlyEnabled then
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then

            local hrp = char.HumanoidRootPart

            if not hrp:FindFirstChild("FlyVelocity") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "FlyVelocity"
                bv.MaxForce = Vector3.new(100000,100000,100000)
                bv.Parent = hrp
            end

            local move = Vector3.zero

            if UIS:IsKeyDown(Enum.KeyCode.W) then
                move += workspace.CurrentCamera.CFrame.LookVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.S) then
                move -= workspace.CurrentCamera.CFrame.LookVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                move -= workspace.CurrentCamera.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.D) then
                move += workspace.CurrentCamera.CFrame.RightVector
            end

            hrp.FlyVelocity.Velocity = move * 60
        end
    else
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local bv = char.HumanoidRootPart:FindFirstChild("FlyVelocity")
            if bv then bv:Destroy() end
        end
    end
end)
