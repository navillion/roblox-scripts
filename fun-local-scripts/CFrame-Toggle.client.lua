local kd = {}
local p = game.Players.LocalPlayer
local m = p:GetMouse()
local speed = 0.25 -- ALSO REFLECTED BY FPS OF PLAYER
local on = true

m.KeyDown:Connect(function(key)
	key = string.lower(key)
	local s = true
	kd[key] = s

	if key == "e" then
		on = not on
	elseif key == "m" then
		speed += 0.05
	elseif key == "n" then
		speed -= 0.05
	end
end)

m.KeyUp:Connect(function(key)
	key = string.lower(key)
	local s = false
	kd[key] = s
end)

function a()
	if not on then
		return
	end

	local p = game.Players.LocalPlayer
	local hrp = p.Character.HumanoidRootPart
	local o = hrp.Orientation
	local q = math.rad
	local f = Vector3.new(0, 0, 0)

	if kd["w"] or kd["s"] or kd["d"] or kd["a"] then
		f = hrp.CFrame.LookVector * speed
	end

	hrp.CFrame = CFrame.new(hrp.CFrame.X, hrp.CFrame.Y, hrp.CFrame.Z) * CFrame.Angles(q(o.X), q(o.Y), q(o.Z)) + f
end

x = game:GetService("RunService").Heartbeat:Connect(a)
p.Character.Humanoid.Died:Connect(function()
	x:Disconnect()
end)

p.CharacterAdded:Connect(function(ch)
	ch:WaitForChild("Humanoid")
	ch:WaitForChild("HumanoidRootPart")

	x = game:GetService("RunService").Heartbeat:Connect(a)
	ch:WaitForChild("Humanoid").Died:Disconnect(function()
		x:Disconnect()
	end)
end)
