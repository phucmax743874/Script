--====================================================
-- KHANHLY X PHUCMAX HUB | FULL FIX FINAL
-- WindUI RELEASE | Stable | No UI Freeze
--====================================================

repeat task.wait() until game:IsLoaded()

--================ LOAD WINDUI =================
local WindUI
local ok, ui = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
        true
    ))()
end)

if not ok or not ui then
    error("Failed to load WindUI")
end
WindUI = ui

--================ SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

--================ CHARACTER =================
local char, hrp, hum
local function bindChar(c)
    char = c
    hrp = c:WaitForChild("HumanoidRootPart")
    hum = c:WaitForChild("Humanoid")
end
bindChar(lp.Character or lp.CharacterAdded:Wait())
lp.CharacterAdded:Connect(bindChar)

--================ WINDOW =================
local Window = WindUI:CreateWindow({
    Title = "PHUCMAX PRO",
    Icon = "rbxassetid://138311826892324",
    Author = "by thanhphuc",
    Folder = "phucmaxdepzai",
    Size = UDim2.fromOffset(580, 340),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 150,
    Background = "rbxassetid://120729878046622",
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    User = { Enabled = true, Anonymous = false },
})

Window:EditOpenButton({
    Title = "OPEN PHUCMAX",
    Icon = "rbxassetid://138311826892324",
    CornerRadius = UDim.new(0,40),
    StrokeThickness = 1,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Draggable = true,
})

--================ TABS =================
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local FpsTab  = Window:Tab({ Title = "FPS", Icon = "zap" })

local Info = InfoTab:Section({ Title = "Information" })
local Main = MainTab:Section({ Title = "Main Functions" })
local FPS  = FpsTab:Section({ Title = "FPS Boost" })
--====================================================
-- FLY BUTTON
--====================================================
Info:Button({
    Title = "Copy link sever Discord",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/PqWjzSVpuw")
        end
        WindUI:Notify({
            Title = "Discord",
            Content = "copied  link Discord!",
            Duration = 3,
            Type = "success"
        })
    end
})

Main:Button({
    Title = "fly to the hole ",
    Callback = function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/phucmax743874/Script/refs/heads/main/Flyphuc"
        ))()
    end
})


Main:Button({
    Title = "fly ",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TurboLite/Script/refs/heads/main/Fly.lua"))()
    end
})




--====================================================
-- CAMERA ZOOM / FOV (SIÊU XA - SIÊU RỘNG)
--====================================================
do
    local cam = workspace.CurrentCamera
    local zoomEnabled = false

    local DEFAULT_FOV = cam.FieldOfView
    local DEFAULT_MIN = lp.CameraMinZoomDistance
    local DEFAULT_MAX = lp.CameraMaxZoomDistance

    local selectedFOV = 70

    -- list FOV (nhỏ -> to)
    -- nhỏ = zoom gần | lớn = góc rộng nhìn xa
    local fovList = {
        "10","20","30","40","50","70",
        "90","120","150","180","220","260"
    }

    Main:Dropdown({
        Title = "Camera Zoom / FOV",
        Values = fovList,
        Default = "70",
        Callback = function(v)
            selectedFOV = tonumber(v)
            if zoomEnabled and cam then
                cam.FieldOfView = selectedFOV
            end
        end
    })

    Main:Toggle({
        Title = "Camera Zoom (Ultra)",
        Default = false,
        Callback = function(v)
            zoomEnabled = v
            if v then
                -- mở khóa zoom tuyệt đối
                lp.CameraMinZoomDistance = 0.1
                lp.CameraMaxZoomDistance = 1e6

                cam.FieldOfView = selectedFOV
            else
                -- khôi phục
                cam.FieldOfView = DEFAULT_FOV
                lp.CameraMinZoomDistance = DEFAULT_MIN
                lp.CameraMaxZoomDistance = DEFAULT_MAX
            end
        end
    })

    -- đảm bảo không reset khi chết
    lp.CharacterAdded:Connect(function()
        task.wait(0.3)
        if zoomEnabled and cam then
            lp.CameraMinZoomDistance = 0.1
            lp.CameraMaxZoomDistance = 1e6
            cam.FieldOfView = selectedFOV
        end
    end)
end


--====================================================
-- AUTO UPGRADE SPEED
--====================================================
do
    local on = false
    local mode = 1
    local remote = ReplicatedStorage.RemoteFunctions.UpgradeSpeed

    Main:Toggle({
        Title = "Auto Upgrade Speed",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end

            task.spawn(function()
                while on do
                    pcall(function()
                        remote:InvokeServer(mode)
                    end)
                    task.wait(0.3)
                end
            end)
        end
    })

    Main:Dropdown({
        Title = "Speed Upgrade Mode",
        Values = { "1", "10" },
        Default = "1",
        Callback = function(v)
            mode = tonumber(v)
        end
    })
end

--====================================================
-- SHIFT LOCK (FIXED)
--====================================================
do
    local on = false
    local conn

    Main:Toggle({
        Title = "Shift Lock",
        Default = false,
        Callback = function(v)
            on = v
            if on then
                hum.AutoRotate = false
                hum.CameraOffset = Vector3.new(1.5,0,0)

                if conn then conn:Disconnect() end
                conn = RunService.RenderStepped:Connect(function()
                    if not on or hum.Health <= 0 then return end
                    local cam = workspace.CurrentCamera
                    if not cam then return end
                    local lv = cam.CFrame.LookVector
                    local f = Vector3.new(lv.X,0,lv.Z)
                    if f.Magnitude > 0 then
                        f = f.Unit
                        hrp.CFrame = CFrame.new(hrp.Position)
                            * CFrame.Angles(0, math.atan2(-f.X,-f.Z), 0)
                    end
                end)
            else
                if conn then conn:Disconnect() conn = nil end
                hum.AutoRotate = true
                hum.CameraOffset = Vector3.zero
            end
        end
    })
end

--====================================================
-- AUTO REBIRTH
--====================================================
do
    local on = false
    local remote = ReplicatedStorage.RemoteFunctions.Rebirth

    Main:Toggle({
        Title = "Auto Rebirth",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end

            task.spawn(function()
                while on do
                    pcall(function()
                        remote:InvokeServer()
                    end)
                    task.wait(0.6)
                end
            end)
        end
    })
end

--====================================================
-- AUTO SPIN (0.4s)
--====================================================
do
    local on = false
    local remote = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("Net")
        :WaitForChild("RF/WheelSpin.Roll")

    Main:Toggle({
        Title = "Auto Spin",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end
            task.spawn(function()
                while on do
                    pcall(function()
                        remote:InvokeServer()
                    end)
                    task.wait(0.4)
                end
            end)
        end
    })
end

--====================================================
-- AUTO COIN ULTRA (HÚT LÊN ĐẦU → THẢ XUỐNG)
--====================================================
do
    local on = false
    local RANGE = 99999

    local HEAD_OFFSET = 6     -- hút coin lên trên đầu
    local DROP_OFFSET = -2.5  -- thả xuống gần chân
    local HOLD_TIME = 0.02    -- thời gian giữ trên đầu (rất ngắn)

    local function isCoin(v)
        if not v:IsA("BasePart") then return false end
        local n = v.Name:lower()
        return n:find("coin") or n:find("cash") or n:find("gold")
    end

    Main:Toggle({
        Title = "Auto Coin (Ultra)",
        Default = false,
        Callback = function(v)
            on = v
            if not on then return end

            task.spawn(function()
                while on and hrp and hum and hum.Health > 0 do
                    for _,obj in ipairs(Workspace:GetDescendants()) do
                        if not on then break end
                        if isCoin(obj) then
                            local dist = (obj.Position - hrp.Position).Magnitude
                            if dist <= RANGE then
                                pcall(function()
                                    obj.CanCollide = false
                                    obj.CastShadow = false

                                    -- 1️⃣ hút coin lên đầu
                                    obj.CFrame = hrp.CFrame * CFrame.new(0, HEAD_OFFSET, 0)

                                    -- 2️⃣ giữ rất ngắn
                                    task.wait(HOLD_TIME)

                                    -- 3️⃣ thả xuống để trigger touch
                                    obj.CFrame = hrp.CFrame * CFrame.new(0, DROP_OFFSET, 0)
                                end)
                            end
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
    })
end

--====================================================
-- FPS BOOST (MERGED FROM bloxkidPVP) | NO FPS/PING UI
--====================================================
do
    -- load module gọn gàng
    local function load(url)
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(url, true))()
        end)
        return ok and res or nil
    end

    -- load 2 module FPS gốc
    local FPSBoost = load(
        "https://raw.githubusercontent.com/kdo91653-cpu/bloxkidPVP-/refs/heads/main/Fps%20boss"
    )

    local FPSBoostMAX = load(
        "https://raw.githubusercontent.com/kdo91653-cpu/bloxkidPVP-/refs/heads/main/Fps%20boost%20max"
    )

    -- FPS Boost thường
    FPS:Toggle({
        Title = "FPS Boost",
        Default = false,
        Callback = function(v)
            if FPSBoost and FPSBoost.Set then
                pcall(function()
                    FPSBoost:Set(v)
                end)
            end
        end
    })

    -- FPS Boost MAX
    FPS:Toggle({
        Title = "FPS Boost MAX",
        Default = false,
        Callback = function(v)
            if FPSBoostMAX and FPSBoostMAX.Set then
                pcall(function()
                    FPSBoostMAX:Set(v)
                end)
            end
        end
    })
end

FPS:Button({
    Title = "Anti AFK : ON",
    Callback = function()
        WindUI:Notify({
            Title = "Anti AFK",
            Content = "Anti AFK is running",
            Duration = 3,
            Type = "success"
        })
    end
})