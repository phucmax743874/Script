--========================================
-- PHUCMAX | ANTI AFK + INFO OVERLAY (PRO)
--========================================

repeat task.wait() until game:IsLoaded()

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local lp = Players.LocalPlayer

---------------- ANTI AFK ----------------
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

---------------- GUI SETUP ----------------
pcall(function()
    lp.PlayerGui:FindFirstChild("PHUCMAX_INFO"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "PHUCMAX_INFO"
gui.ResetOnSpawn = false
gui.Parent = lp.PlayerGui

local label = Instance.new("TextLabel")
label.Parent = gui
label.Size = UDim2.new(0, 240, 0, 50)
label.Position = UDim2.new(0.5, -120, 0.1, 0)
label.BackgroundTransparency = 1
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextStrokeTransparency = 0.4
label.Active = true
label.Selectable = true

---------------- DRAG ----------------
do
    local dragging, startPos, startGui
    label.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = i.Position
            startGui = label.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - startPos
            label.Position = UDim2.new(
                startGui.X.Scale,
                startGui.X.Offset + delta.X,
                startGui.Y.Scale,
                startGui.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function()
        dragging = false
    end)
end

---------------- FPS CALC ----------------
local fps = 0
local frames = 0
local lastFpsTick = tick()

RunService.RenderStepped:Connect(function()
    frames += 1
    if tick() - lastFpsTick >= 1 then
        fps = frames
        frames = 0
        lastFpsTick = tick()
    end
end)

---------------- TIME TRACK ----------------
local startTime = tick()

local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

---------------- RAINBOW WAVE ----------------
task.spawn(function()
    local t = 0
    while label and label.Parent do
        t += 0.03
        local r = math.sin(t) * 0.5 + 0.5
        local g = math.sin(t + 2) * 0.5 + 0.5
        local b = math.sin(t + 4) * 0.5 + 0.5
        label.TextColor3 = Color3.new(r, g, b)
        task.wait()
    end
end)

---------------- MAIN UPDATE LOOP ----------------
task.spawn(function()
    while label and label.Parent do
        local ping = 0
        pcall(function()
            ping = math.floor(
                Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            )
        end)

        local uptime = formatTime(tick() - startTime)

        label.Text =
            " Time : " .. uptime ..
            "\n FPS  : " .. fps ..
            "\n Ping : " .. ping .. " ms" ..
            "\nAnti AFK : ON"

        task.wait(0.2)
    end
end)