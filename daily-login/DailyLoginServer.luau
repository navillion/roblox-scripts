-- Create this events before continuing
local Daily = game.ReplicatedStorage.Events.Daily
local Event = game.ReplicatedStorage.Events.DailyEvent

local DailyStore = game:GetService("DataStoreService"):GetDataStore("DailyLogin 7")
local DailyLb = game:GetService("DataStoreService"):GetOrderedDataStore("DailyLoginLb")

local ClaimCooldown = 20 * 60 * 60 -- Set the number of hours you want them to wait.

local PlayersProcessing = {}

local function GetData(player)
	local Data = DailyStore:GetAsync(player.UserId)
	if Data then
		return Data
	else
		local NewData = {
			Streak = 0;
			LastClaim = os.time();
		}
		return NewData
	end
end

Daily.OnServerInvoke = function(player, request)
	if request == "Ready" then
		local Data = GetData(player)
		local TimeSinceLast = os.time() - Data.LastClaim
		if Data.Streak == 0 then
			--print("Player is ready to claim [First Time]")
			return "First"
		elseif TimeSinceLast < ClaimCooldown  then
			--print("It is too early to claim")
			return Data.LastClaim + ClaimCooldown
		else
			--print("Player is ready to claim")
			return true
		end	
		

	elseif request == "Claim" then
		-- Prevent multiple claims from occuring at once
		if PlayersProcessing[player] then
			--print("On cooldown for", player)
			return false
		else
			PlayersProcessing[player] = true
		end
		
		local Data = GetData(player)
		local TimeSinceLast = os.time() - Data.LastClaim
--		print("TIME:", TimeSinceLast)
		-- (TOO LITTLE TIME)
		if TimeSinceLast < ClaimCooldown and Data.Streak ~= 0 then
			PlayersProcessing[player] = false
			--print("Player has already claimed recently")
			Event:FireClient(player, "Early", ClaimCooldown - TimeSinceLast)
			print("[SS]: Time Remaining:", ClaimCooldown - TimeSinceLast)
			return false
		end
		
		-- First claim gives a lot more
    -- Modify these values to match your leaderboards
		if Data.Streak == 0 then
			Event:FireClient(player, "Claimed", 1000)
			player.leaderstats['Ship Points'].Value += 1000
		else
			local Reward = 100 + 10 * Data.Streak
			if Reward >= 500 then Reward = 500 end
			Event:FireClient(player, "Claimed", Reward)
			player.leaderstats['Ship Points'].Value += Reward
		end
		
		Data.Streak += 1
		Data.LastClaim = os.time();
		
		--print(Data)
		
		DailyStore:SetAsync(player.UserId, Data)
		
		PlayersProcessing[player] = false
		
		task.spawn(function()
			DailyLb:SetAsync(player.UserId, Data.Streak)
		end)
		return true
	elseif request == "Streak" then
		local Data = GetData(player)
		return Data.Streak or 0
	end
end

-- When requesting a player's streak.
game.ReplicatedStorage.Events.DailyServer.OnInvoke = function(player, request)
	if request == "Streak" then
		local Data = GetData(player)
		return Data.Streak or 0
	end
end
