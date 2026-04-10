-- GolfClub LocalScript
-- Place this LocalScript inside the GolfClub Tool in StarterPack.
-- The Tool's Handle should be a Part named "Handle" with a mesh/appearance
-- resembling a golf club shaft and head.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Wait for the RemoteEvent used to communicate swings to the server
local golfFolder = ReplicatedStorage:WaitForChild("Golf")
local golfEvents = golfFolder:WaitForChild("GolfEvents")

-- Power of the swing (studs/second applied to the ball)
local SWING_POWER = 200
local canSwing = true
local SWING_COOLDOWN = 1.5  -- seconds between swings

-- Play a simple swing animation via CFrame tweening on the Handle
local function playSwingAnimation()
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    local originalCFrame = handle.CFrame
    local swingCFrame = originalCFrame * CFrame.Angles(0, 0, math.rad(-90))

    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local swingTween = TweenService:Create(handle, tweenInfo, {CFrame = swingCFrame})
    swingTween:Play()
    swingTween.Completed:Wait()

    local returnTween = TweenService:Create(handle, TweenInfo.new(0.3), {CFrame = originalCFrame})
    returnTween:Play()
end

-- Called when the player activates the tool (left-click while equipped)
tool.Activated:Connect(function()
    if not canSwing then return end
    canSwing = false

    playSwingAnimation()
    golfEvents:FireServer("Swing", SWING_POWER)

    task.delay(SWING_COOLDOWN, function()
        canSwing = true
    end)
end)

tool.Equipped:Connect(function()
    canSwing = true
end)

tool.Unequipped:Connect(function()
    canSwing = false
end)
