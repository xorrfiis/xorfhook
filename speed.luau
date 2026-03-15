game:GetService("RunService").RenderStepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if getgenv().SpeedEnabled then
            char.Humanoid.WalkSpeed = getgenv().SpeedValue
        else
            char.Humanoid.WalkSpeed = 16
        end
    end
end)
