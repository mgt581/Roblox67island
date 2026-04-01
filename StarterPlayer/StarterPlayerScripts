local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the RemoteEvent from the Golf folder
local golfEvents = ReplicatedStorage:WaitForChild("Golf"):WaitForChild("GolfEvents")

-- Set a base power level (you can adjust this later)
local power = 200

-- Detect mouse clicks and fire event to the server
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- When the player clicks, send the event to the server
        golfEvents:FireServer("Swing", power)
    end
end)
