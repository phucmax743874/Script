--==============================
-- PHUCMAX | RAINBOW TITLE + DISCORD WEBHOOK
--==============================

repeat task.wait() until game:IsLoaded()

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1463537347730604096/L_fe3VFp4I2CCi8DSR6KIlD_8lhXI_rY-EXJ47XS2msOAFIHcU5Y1DqQ_71jcHZd0LPq" -- << THAY LINK VÀO ĐÂY

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer

--------------------------------------------------
-- UI
--------------------------------------------------
pcall(function()
	lp.PlayerGui:FindFirstChild("PHUCMAX_TITLE"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "PHUCMAX_TITLE"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = lp.PlayerGui

local label = Instance.new("TextLabel", gui)
label.Size = UDim2.new(1, 0, 0, 40)
label.Position = UDim2.new(0, 0, 0, 20)-- mép trên
label.BackgroundTransparency = 1
label.Text = "."
label.Font = Enum.Font.GothamBlack
label.TextSize = 1
label.TextStrokeTransparency = 0.25
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center

--------------------------------------------------
-- RAINBOW WAVE EFFECT
--------------------------------------------------
task.spawn(function()
	local t = 0
	while label.Parent do
		t += 0.03

		-- rainbow color
		local hue = (t * 0.15) % 1
		label.TextColor3 = Color3.fromHSV(hue, 1, 1)

		-- wave motion
		local offset = math.sin(t * 2) * 4
		label.Position = UDim2.new(0, 0, 0, 8 + offset)

		task.wait(0.03)
	end
end)

--------------------------------------------------
-- DISCORD WEBHOOK SEND
--------------------------------------------------
task.spawn(function()
	if not syn and not http_request and not request then return end

	local req = syn and syn.request or http_request or request
	if not req then return end

	local data = {
		username = "PHUCMAX ",
		embeds = {{
			title = "Script Executed",
			color = 65280,
			fields = {
				{name = "Player", value = lp.Name, inline = true},
				{name = "UserId", value = tostring(lp.UserId), inline = true},
				{name = "GameId", value = tostring(game.GameId), inline = false},
				{name = "JobId", value = tostring(game.JobId), inline = false}
			},
			footer = {text = "PHUCMAX Script"}
		}}
	}

	pcall(function()
		req({
			Url = DISCORD_WEBHOOK,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(data)
		})
	end)

end)
