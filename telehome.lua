--// SPAM TELE UI PRO | PHUCMAX
--// Glass UI + Countdown + Sound Finish

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

--================ CONFIG =================--
local TARGET_POS = Vector3.new(128.74, 3.18, 15.57)
local UNDER_Y = -999999999999999
local SPAM_DELAY = 0.01
local DURATION = 3

local SOUND_ID = "rbxassetid://583920174" -- <<< I ID ÂM THANH  ÂY
local SOUND_VOLUME = 100

local running = false
local spamThread

--================ UI =================--
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpamTeleGlassUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 170)
frame.Position = UDim2.new(0.5, -140, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0,255,170)
stroke.Thickness = 1.2
stroke.Transparency = 0.4

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = " TELE HOME"
title.TextColor3 = Color3.fromRGB(0,255,170)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1,-20,0,30)
status.Position = UDim2.new(0,10,0,40)
status.BackgroundTransparency = 1
status.Text = "status: ready "
status.TextColor3 = Color3.fromRGB(200,200,200)
status.Font = Enum.Font.Gotham
status.TextSize = 14

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1,-20,0,35)
startBtn.Position = UDim2.new(0,10,0,85)
startBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
startBtn.BackgroundTransparency = 0.1
startBtn.Text = " START"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Font = Enum.Font.Gotham
startBtn.TextSize = 15
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,10)

--================ SOUND =================--
local sound = Instance.new("Sound")
sound.SoundId = SOUND_ID
sound.Volume = SOUND_VOLUME
sound.Parent = frame

--================ LOGIC =================--
local function getHRP()
	return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

local function startSpam()
	if running then return end
	running = true
	startBtn.Text = "running..."
	startBtn.AutoButtonColor = false

	spamThread = task.spawn(function()
		for i = DURATION, 1, -1 do
			status.Text = "teleporting: "..i
			local t = tick()
			while tick() - t < 1 do
				local hrp = getHRP()
				if hrp then
					hrp.CFrame = CFrame.new(hrp.Position.X, UNDER_Y, hrp.Position.Z)
				end
				task.wait(SPAM_DELAY)
			end
		end

		local hrp = getHRP()
		if hrp then
			hrp.CFrame = CFrame.new(TARGET_POS)
		end

		--  PLAY SOUND KHI LÊN LI
		if SOUND_ID ~= "" then
			sound:Play()
		end

		status.Text = "Pick up the game easily"
		task.wait(1.2)

		status.Text = "status: ready "
		startBtn.Text = " START"
		startBtn.AutoButtonColor = true
		running = false
	end)
end

startBtn.MouseButton1Click:Connect(startSpam)