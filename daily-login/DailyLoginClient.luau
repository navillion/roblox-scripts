-- Ensure all these events are created (Event being a Remote Event and Daily being a Remote Function)
local Daily = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Daily")
local Event = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("DailyEvent")
	
local player = game.Players.LocalPlayer

-- Create GUIs so that player knows what's going on! The default ones will be attached as an rbxm file to the git.
local daily_claim = game.ReplicatedStorage:WaitForChild("GUIs"):WaitForChild("Daily"):WaitForChild("DailyMessage")
local gui_claimed = game.ReplicatedStorage:WaitForChild("GUIs"):WaitForChild("Daily"):WaitForChild("ClaimedMessage")
local early_claim = game.ReplicatedStorage:WaitForChild("GUIs"):WaitForChild("Daily"):WaitForChild("EarlyMessage")
local ready_early = game.ReplicatedStorage:WaitForChild("GUIs"):WaitForChild("Daily"):WaitForChild("ReadyEarlyMessage")
local CurrentTime = os.time()

local TimeUntilReady = Daily:InvokeServer("Ready", false)
local ReadyToClaim = false

-- Set how long the player has to wait in the server before claiming! This boosts your session time :)
local ClaimCooldown = 10 * 60 -- 15 mins

if TimeUntilReady == true then
	--print("Player is eligible to claim Daily")
	delay(ClaimCooldown, function()
		ReadyToClaim = true
		daily_claim:Clone().Parent = player.PlayerGui
	end)
elseif TimeUntilReady == "First" then
	ReadyToClaim = true
	wait(15)
	daily_claim:Clone().Parent = player.PlayerGui
else
	--print("Not available for player yet.")
end


Event.OnClientEvent:Connect(function(request, amount)
	if request == "Display" then
		daily_claim:Clone().Parent = player.PlayerGui
	elseif request == "Claimed" then
		local claimed = gui_claimed:Clone()
		claimed.SP.Value = amount
		claimed.Parent = player.PlayerGui
	elseif request == "Early" then
		local early = early_claim:Clone()
		early.SP.Value = amount
		early.Parent = player.PlayerGui
	end
end)


-- Infinite timeout time (so it doesn't say "infinite yield possible")
local ClaimBaseplate = workspace:WaitForChild("Treasure"):WaitForChild("Daily"):WaitForChild("TouchPart", math.huge)

local Cooldown = false
ClaimBaseplate.Touched:Connect(function(part)
	if part.Parent == player.Character and not Cooldown then
		Cooldown = true
		
		if not ReadyToClaim then
			-- Check if the time is gonna end up negative for whatever reason.
			if (ClaimCooldown - (os.time() - CurrentTime)) < 0 then
				ReadyToClaim = true
				Cooldown = false
			end
			
			local early = early_claim:Clone()
			early.SP.Value = ClaimCooldown - (os.time() - CurrentTime)
			early.Parent = player.PlayerGui
			print("[LS]: Time Remaining:", ClaimCooldown - (os.time() - CurrentTime)) 
			
			wait(8)
			Cooldown = false
			return
		end
		
		local Claim = Daily:InvokeServer("Claim")
		
		if Claim then
			wait(8)
			Cooldown = false
		else
			wait(8)
			Cooldown = false
		end

	end
end)
