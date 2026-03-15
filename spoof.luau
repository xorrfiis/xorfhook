getgenv().SpoofFunctions = {
    spoofKBM = function()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        ReplicatedStorage.Remotes.Replication.Fighter.SetControls:FireServer("MouseKeyboard")
    end,

    spoofController = function()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        ReplicatedStorage.Remotes.Replication.Fighter.SetControls:FireServer("Gamepad")
    end,

    spoofMobile = function()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        ReplicatedStorage.Remotes.Replication.Fighter.SetControls:FireServer("Touch")
    end,

    spoofVR = function()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        ReplicatedStorage.Remotes.Replication.Fighter.SetControls:FireServer("VR")
    end
}
