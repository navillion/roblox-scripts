-- You will have to customize this script to fit your use-case.
-- This script served as a ROBLOX PvP Bot that aimed at players and attacked them intelligently.

local player = game.Players.LocalPlayer
local base = game:GetService("Workspace"):WaitForChild("Structure").Baseplate
local selection = base.SelectionBox
local parts = {}

local Advanced = true
local Bait = true -- Stay near players
local AttackRange = 16

local touched = false

local function Invisible()
	for i, v in pairs(parts) do
		v:Destroy()
	end

	local Positions = {
		base.CFrame + base.CFrame.LookVector * base.Size.X / 2,
		base.CFrame - base.CFrame.LookVector * base.Size.X / 2,
		base.CFrame + base.CFrame.RightVector * base.Size.X / 2,
		base.CFrame - base.CFrame.RightVector * base.Size.X / 2,
	}

	for i, v in pairs(Positions) do
		local part = Instance.new("Part", workspace)
		table.insert(parts, part)
		part.Anchored = true
		part.Transparency = 0.5
		part.BrickColor = BrickColor.new("Magenta")
		part.CanCollide = true
		part.CFrame = v
		part.Size = Vector3.new(base.Size.X, 50, 20)
		if i > 2 then
			part.Size = Vector3.new(20, 50, base.Size.X)
		end
	end
end

selection:GetPropertyChangedSignal("Visible"):Connect(function()
	while selection.Visible and touched do
		player.Character.Humanoid:MoveTo(Vector3.new(0, 0, 0))
		task.wait()
	end
end)

BaseC = base:GetPropertyChangedSignal("Size"):Connect(Invisible)
Invisible()

local function SpawnCheck(p)
	return p.X > (-45 * 1.1 / 2) and p.X < (45 * 1.1 / 2) and p.Z > (-45 * 1.1 / 2) and p.Z < (45 * 1.1 / 2)
end

local function HitPart(p)
	local la = p.Character["Left Arm"]
	local ra = p.Character["Right Arm"]
	local head = p.Character["Head"]

	if math.abs(head.Orientation.Y - player.Character.Head.Orientation.Y) < 90 then
		return la
	else
		return ra
	end
end

local RS = game:GetService("RunService").Heartbeat:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	if character.Humanoid.Health < 0 then
		return
	end

	local near2, mag2, near, mag = nil, math.huge, nil, math.huge

	for i, ePlayer in pairs(game.Players:GetPlayers()) do
		if
			ePlayer ~= player
			and ePlayer.Character
			and ePlayer.Character:FindFirstChild("Humanoid")
			and ePlayer.Character.Humanoid.Health > 0
			and not SpawnCheck(ePlayer.Character.HumanoidRootPart.Position)
		then
			local dis = player:DistanceFromCharacter(ePlayer.Character.HumanoidRootPart.Position)

			if dis < mag then
				near2 = near
				mag2 = mag

				mag = dis
				near = ePlayer
			end
		end
	end

	if mag <= AttackRange then
		local tool = player.Backpack:FindFirstChildOfClass("Tool") or player.Character:FindFirstChildOfClass("Tool")
		if tool then
			tool.Parent = player.Character
			tool:Activate()
		end

		local eHrp = near.Character.HumanoidRootPart.Position
		local eP = Vector3.new(eHrp.X, hrp.Position.Y, eHrp.Z)

		if Advanced then
			local hitPart = HitPart(near).Position
			eP = Vector3.new(hitPart.X, hrp.Position.Y, hitPart.Z)
		end

		hrp.CFrame = CFrame.new(hrp.Position, eP)

		character.Humanoid:MoveTo(eHrp)

		if Advanced then
			if
				(near.Character.Humanoid.Jump == true)
				or (near2 and near2.Character and near2.Character.Humanoid.Jump == true and mag2 <= AttackRange * 1.5)
			then
				task.wait()
				character.Humanoid.Jump = true
			end
		end
	else
		character.Humanoid:MoveTo(near.Character.HumanoidRootPart.Position)
		character.Humanoid:UnequipTools()
	end
end)

player:GetMouse().KeyDown:Connect(function(key)
	key = string.lower(key)
	if key == "z" then
		Bait = not Bait
	elseif key == "x" then
		RS:Disconnect()
		BaseC:Disconnect()
		for i, v in pairs(parts) do
			v:Destroy()
		end
	end
end)
