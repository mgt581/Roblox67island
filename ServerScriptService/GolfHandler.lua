-- GolfHandler Script (ServerScriptService)
-- Handles "Swing" events fired by the GolfClub tool.
-- Finds the nearest golf ball to the player's club head and applies velocity.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure the Golf RemoteEvent folder exists in ReplicatedStorage
local golfFolder = ReplicatedStorage:FindFirstChild("Golf")
    or Instance.new("Folder", ReplicatedStorage)
golfFolder.Name = "Golf"

local golfEvents = golfFolder:FindFirstChild("GolfEvents")
    or Instance.new("RemoteEvent", golfFolder)
golfEvents.Name = "GolfEvents"

-- Maximum distance (studs) from the club head to detect a golf ball
local MAX_HIT_DISTANCE = 10

-- Tag or name used to identify golf balls in the Workspace
local GOLF_BALL_NAME = "GolfBall"

-- Find the closest golf ball to a given position within MAX_HIT_DISTANCE
local function findNearestBall(origin)
    local nearest = nil
    local nearestDist = MAX_HIT_DISTANCE

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == GOLF_BALL_NAME then
            local dist = (obj.Position - origin).Magnitude
            if dist < nearestDist then
                nearest = obj
                nearestDist = dist
            end
        end
    end

    return nearest
end

-- Compute the swing direction: forward relative to the player's root part,
-- angled slightly upward to give the ball loft.
local function getSwingDirection(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return Vector3.new(0, 0, -1) end

    local lookVector = rootPart.CFrame.LookVector
    -- Add a slight upward component (loft)
    local swingDir = (lookVector + Vector3.new(0, 0.3, 0)).Unit
    return swingDir
end

-- Apply force to the golf ball using a LinearVelocity constraint for one frame,
-- then remove it so the ball flies freely.
local function hitBall(ball, direction, power)
    -- Use AssemblyLinearVelocity for a clean, instant velocity change
    ball.AssemblyLinearVelocity = direction * power
end

-- Listen for swing events from clients
golfEvents.OnServerEvent:Connect(function(player, action, power)
    if action ~= "Swing" then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    -- Validate power: clamp to a safe range to prevent exploits
    local safePower = math.clamp(tonumber(power) or 200, 0, 500)

    -- Find the club handle position (used as the swing origin)
    local tool = character:FindFirstChildWhichIsA("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    local origin = handle and handle.Position or character:FindFirstChild("HumanoidRootPart").Position

    local ball = findNearestBall(origin)
    if not ball then
        -- No ball nearby; nothing to hit
        return
    end

    local swingDir = getSwingDirection(character)
    hitBall(ball, swingDir, safePower)
end)
