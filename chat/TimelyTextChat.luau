_G.enable_chat = false
task.wait(1)
_G.enable_chat = true
task.wait(1)

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local RUNTIME_NAME = "__TempFilteredChatMirror"
local DURATION_SECONDS = 60 * 60
local MAX_MESSAGES = 10

do
	local oldRuntime = ServerStorage:FindFirstChild(RUNTIME_NAME)
	if oldRuntime then
		local shutdown = oldRuntime:FindFirstChild("Shutdown")
		if shutdown and shutdown:IsA("BindableEvent") then
			pcall(function()
				shutdown:Fire()
			end)
		end
		oldRuntime:Destroy()
	end
end

local runtimeFolder = Instance.new("Folder")
runtimeFolder.Name = RUNTIME_NAME
runtimeFolder.Parent = ServerStorage

local shutdownEvent = Instance.new("BindableEvent")
shutdownEvent.Name = "Shutdown"
shutdownEvent.Parent = runtimeFolder

local active = true
local connections = {}
local playerChatConnections = {}
local history = {}
local nextMessageId = 0
local GLOBAL_TOGGLE_NAME = "enable_chat"

local cleanup

if _G[GLOBAL_TOGGLE_NAME] == nil then
	_G[GLOBAL_TOGGLE_NAME] = true
end

local function isChatEnabled()
	return _G[GLOBAL_TOGGLE_NAME] ~= false
end

local function escapeRichText(str)
	str = tostring(str or "")
	str = str:gsub("&", "&amp;")
	str = str:gsub("<", "&lt;")
	str = str:gsub(">", "&gt;")
	str = str:gsub('"', "&quot;")
	str = str:gsub("'", "&apos;")
	return str
end

local function colorToHex(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function getNameColor(userId)
	local hue = (userId * 0.61803398875) % 1
	return Color3.fromHSV(hue, 0.65, 1)
end

local function getDisplayNameText(player)
	if player.DisplayName and player.DisplayName ~= player.Name then
		return string.format("%s (@%s)", player.DisplayName, player.Name)
	end
	return player.Name
end

local function getPlayerGui(player)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if pg then
		return pg
	end

	local ok, result = pcall(function()
		return player:WaitForChild("PlayerGui", 20)
	end)

	if ok then
		return result
	end

	return nil
end

local function getScrollFrame(player)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end

	local gui = pg:FindFirstChild(RUNTIME_NAME)
	if not gui then
		return nil
	end

	return gui:FindFirstChild("ChatScroll")
end

local function addEntryToScroll(scroll, entry)
	if not scroll or not scroll.Parent then
		return
	end

	local label = Instance.new("TextLabel")
	label.Name = "Line_" .. entry.id
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.RichText = true
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, -4, 0, 0)
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.LayoutOrder = entry.id
	label.Text = entry.richText
	label.ZIndex = 100
	label.Parent = scroll
end

local function trimOldestIfNeeded()
	while #history > MAX_MESSAGES do
		local removed = table.remove(history, 1)
		for _, player in ipairs(Players:GetPlayers()) do
			local scroll = getScrollFrame(player)
			if scroll then
				local oldLabel = scroll:FindFirstChild("Line_" .. removed.id)
				if oldLabel then
					oldLabel:Destroy()
				end
			end
		end
	end
end

local function makeGuiForPlayer(player)
	if not active then
		return
	end

	local pg = getPlayerGui(player)
	if not pg then
		return
	end

	local oldGui = pg:FindFirstChild(RUNTIME_NAME)
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = RUNTIME_NAME
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = pg

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ChatScroll"
	scroll.Parent = screenGui
	scroll.AnchorPoint = Vector2.new(1, 0)
	scroll.Position = UDim2.new(1, -8, 0, 12) -- top-right so it doesnt get covered by the default chat
	scroll.Size = UDim2.fromOffset(420, 240)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Active = true
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 0
	scroll.ScrollBarImageTransparency = 1
	scroll.ZIndex = 100

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 2)
	padding.PaddingRight = UDim.new(0, 2)
	padding.PaddingTop = UDim.new(0, 2)
	padding.PaddingBottom = UDim.new(0, 2)
	padding.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Parent = scroll

	for _, entry in ipairs(history) do
		addEntryToScroll(scroll, entry)
	end
end

local function broadcastRawMessage(fromPlayer, rawMessage)
	if not active then
		return
	end

	rawMessage = tostring(rawMessage or "")
	rawMessage = rawMessage:gsub("^%s+", ""):gsub("%s+$", "")
	if rawMessage == "" then
		return
	end

	nextMessageId += 1

	local nameText = escapeRichText(getDisplayNameText(fromPlayer))
	local messageText = escapeRichText(rawMessage)
	local nameColor = colorToHex(getNameColor(fromPlayer.UserId))
	local msgColor = "#FFFFFF"

	local entry = {
		id = nextMessageId,
		richText = string.format(
			'<font color="%s">%s:</font> <font color="%s">%s</font>',
			nameColor,
			nameText,
			msgColor,
			messageText
		),
	}

	table.insert(history, entry)
	trimOldestIfNeeded()

	for _, player in ipairs(Players:GetPlayers()) do
		local scroll = getScrollFrame(player)
		if scroll then
			addEntryToScroll(scroll, entry)
		end
	end
end

local function hookPlayerChat(player)
	if playerChatConnections[player] then
		return
	end

	local conn = player.Chatted:Connect(function(message)
		broadcastRawMessage(player, message)
	end)

	playerChatConnections[player] = conn
	table.insert(connections, conn)
end

cleanup = function()
	if not active then
		return
	end
	active = false

	for player, conn in pairs(playerChatConnections) do
		if conn and conn.Connected then
			pcall(function()
				conn:Disconnect()
			end)
		end
		playerChatConnections[player] = nil
	end

	for _, conn in ipairs(connections) do
		if conn and conn.Connected then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if pg then
			local gui = pg:FindFirstChild(RUNTIME_NAME)
			if gui then
				gui:Destroy()
			end
		end
	end

	if runtimeFolder and runtimeFolder.Parent then
		runtimeFolder:Destroy()
	end
end

table.insert(connections, shutdownEvent.Event:Connect(cleanup))

if not isChatEnabled() then
	cleanup()
	print("[TempFilteredChatMirror] Disabled by _G.enable_chat = false")
	return
end

for _, player in ipairs(Players:GetPlayers()) do
	makeGuiForPlayer(player)
	hookPlayerChat(player)
end

table.insert(
	connections,
	Players.PlayerAdded:Connect(function(player)
		makeGuiForPlayer(player)
		hookPlayerChat(player)
	end)
)

table.insert(
	connections,
	Players.PlayerRemoving:Connect(function(player)
		local conn = playerChatConnections[player]
		if conn and conn.Connected then
			pcall(function()
				conn:Disconnect()
			end)
		end
		playerChatConnections[player] = nil
	end)
)

task.delay(DURATION_SECONDS, cleanup)

task.spawn(function()
	while active do
		if not isChatEnabled() then
			cleanup()
			break
		end
		task.wait(0.2)
	end
end)

print("[TempFilteredChatMirror] Live for 1 hour on current + future players.")
