-- GolfHandler Script (ServerScriptService)
-- Handles "Swing" events fired by the GolfClub tool.
-- Finds the nearest golf ball to the player's club head and applies velocity.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure the Golf RemoteEvent folder exists in ReplicatedStorage
local golfFolder = ReplicatedStorage:FindFirstChild("Golf")
if not golfFolder then
    golfFolder = Instance.new("Folder")
    golfFolder.Name = "Golf"
    golfFolder.Parent = ReplicatedStorage
end

local golfEvents = golfFolder:FindFirstChild("GolfEvents")
if not golfEvents then
    golfEvents = Instance.new("RemoteEvent")
    golfEvents.Name = "GolfEvents"
    golfEvents.Parent = golfFolder
end

-- Maximum distance (studs) from the club head to detect a golf ball
local MAX_HIT_DISTANCE = 10

-- Name used to identify golf balls in the Workspace.
-- Place all golf balls in a Folder named "GolfBalls" directly under Workspace,
-- or give every golf ball Part the name "GolfBall".
local GOLF_BALL_NAME = "GolfBall"

-- Server-side cooldown tracking per player to prevent exploit spam
local SWING_COOLDOWN = 1.0  -- seconds
local lastSwingTime = {}

-- Find the closest golf ball to a given position within MAX_HIT_DISTANCE.
-- Searches a dedicated "GolfBalls" folder first for efficiency; falls back to
-- scanning all workspace descendants if the folder is absent.
local function findNearestBall(origin)
    local nearest = nil
    local nearestDist = MAX_HIT_DISTANCE

    local searchRoot = workspace:FindFirstChild("GolfBalls") or workspace

    for _, obj in ipairs(searchRoot:GetDescendants()) do
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
local function getSwingDirection(rootPart)
    local lookVector = rootPart.CFrame.LookVector
    return (lookVector + Vector3.new(0, 0.3, 0)).Unit
end

-- Apply an instant velocity to the golf ball.
local function hitBall(ball, direction, power)
    ball.AssemblyLinearVelocity = direction * power
end

-- Listen for swing events from clients
golfEvents.OnServerEvent:Connect(function(player, action, power)
    if action ~= "Swing" then return end

    -- Server-side cooldown check
    local now = tick()
    local lastTime = lastSwingTime[player] or 0
    if now - lastTime < SWING_COOLDOWN then return end
    lastSwingTime[player] = now

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Validate power: clamp to a safe range to prevent exploits
    local safePower = math.clamp(tonumber(power) or 200, 0, 500)

    -- Use the club handle position as the swing origin when available
    local tool = character:FindFirstChildWhichIsA("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    local origin = handle and handle.Position or rootPart.Position

    local ball = findNearestBall(origin)
    if not ball then return end

    local swingDir = getSwingDirection(rootPart)
    hitBall(ball, swingDir, safePower)
end)

-- Clean up cooldown entries when players leave
Players.PlayerRemoving:Connect(function(player)
    lastSwingTime[player] = nil
end)
