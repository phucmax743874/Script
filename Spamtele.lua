--====================================================

-- FORCE RESPAWN TO SECRET + DRAGGABLE UI

-- Toggle ON/OFF | Spam Teleport 0.2s

--====================================================



repeat task.wait() until game:IsLoaded()



---------------- SERVICES ----------------

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local UIS = game:GetService("UserInputService")

local lp = Players.LocalPlayer



---------------- CONFIG ----------------

local SECRET_POS = Vector3.new(2257.12, -2.82, -8.04)

local TELEPORT_INTERVAL = 0.00000000000000000000002



---------------- STATE ----------------

local Enabled = false

local teleporting = false

local spamThread



---------------- CORE ----------------

local function stopSpam()

    teleporting = false

    if spamThread then

        task.cancel(spamThread)

        spamThread = nil

    end

end



local function startSpam()

    if teleporting then return end

    teleporting = true



    spamThread = task.spawn(function()

        while teleporting and Enabled do

            local char = lp.Character

            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            local hum = char and char:FindFirstChild("Humanoid")



            if hrp and hum then

                hrp.CFrame = CFrame.new(SECRET_POS)

                hrp.Velocity = Vector3.zero

            end



            task.wait(TELEPORT_INTERVAL)

        end

    end)

end



---------------- CHARACTER ----------------

local function onCharacter(char)

    local hum = char:WaitForChild("Humanoid")



    if Enabled then

        startSpam()

    end



    hum.Died:Connect(function()

        if Enabled then

            startSpam()

        end

    end)

end



if lp.Character then

    onCharacter(lp.Character)

end

lp.CharacterAdded:Connect(onCharacter)



---------------- UI ----------------

pcall(function()

    lp.PlayerGui:FindFirstChild("SECRET_TELE_UI"):Destroy()

end)



local gui = Instance.new("ScreenGui", lp.PlayerGui)

gui.Name = "SECRET_TELE_UI"

gui.ResetOnSpawn = false



local frame = Instance.new("Frame", gui)

frame.Size = UDim2.new(0, 160, 0, 60)

frame.Position = UDim2.new(0.5, -80, 0.3, 0) -- nhích lên sẵn

frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

frame.Active = true

frame.Draggable = false

Instance.new("UICorner", frame)



-- DRAG (PC + MOBILE)

do

    local dragging, dragStart, startPos



    frame.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1

        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true

            dragStart = input.Position

            startPos = frame.Position

        end

    end)



    UIS.InputChanged:Connect(function(input)

        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement

        or input.UserInputType == Enum.UserInputType.Touch) then

            local delta = input.Position - dragStart

            frame.Position = UDim2.new(

                startPos.X.Scale,

                startPos.X.Offset + delta.X,

                startPos.Y.Scale,

                startPos.Y.Offset + delta.Y

            )

        end

    end)



    UIS.InputEnded:Connect(function()

        dragging = false

    end)

end



-- TITLE

local title = Instance.new("TextLabel", frame)

title.Size = UDim2.new(1, 0, 0, 22)

title.BackgroundTransparency = 1

title.Text = "SECRET RESPAWN"

title.Font = Enum.Font.GothamBold

title.TextSize = 12

title.TextColor3 = Color3.fromRGB(0, 220, 180)



-- TOGGLE BUTTON

local toggle = Instance.new("TextButton", frame)

toggle.Position = UDim2.new(0.1, 0, 0.45, 0)

toggle.Size = UDim2.new(0.8, 0, 0, 26)

toggle.Text = "OFF"

toggle.Font = Enum.Font.GothamBlack

toggle.TextSize = 13

toggle.BackgroundColor3 = Color3.fromRGB(170, 60, 60)

toggle.TextColor3 = Color3.new(1,1,1)

Instance.new("UICorner", toggle)



toggle.MouseButton1Click:Connect(function()

    Enabled = not Enabled

    toggle.Text = Enabled and "ON" or "OFF"

    toggle.BackgroundColor3 = Enabled

        and Color3.fromRGB(0, 180, 140)

        or Color3.fromRGB(170, 60, 60)



    if Enabled then

        startSpam()

    else

        stopSpam()

    end

end)



print("on")
