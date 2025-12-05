-- Serves as a general speed script for moving the player around using WASD keys.

local kd = {}
local p = game.Players.LocalPlayer
local m = p:GetMouse()
local speed = 3 -- ALSO REFLECTED BY FPS OF PLAYER

m.KeyDown:Connect(function(key)
	key = string.lower(key)
	local s = true
	kd[key] = s
end)

m.KeyUp:Connect(function(key)
	key = string.lower(key)
	local s = false
	kd[key] = s
end)

function a()
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
a()

p.Character.Humanoid.Died:Connect(function()
	x:Disconnect()
end)
