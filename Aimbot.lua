local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Variables
local aimbotEnabled = false
local espEnabled = false
local speedEnabled = false

local aimbotFOV = 100 -- grados
local aimbotSpeed = 0.3 -- velocidad de apuntado (0-1)

local espBoxes = {}
local humanoid = nil

-- Crear GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimbotMenu"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 230)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local aimbotButton = Instance.new("TextButton", frame)
aimbotButton.Size = UDim2.new(1, -20, 0, 50)
aimbotButton.Position = UDim2.new(0, 10, 0, 10)
aimbotButton.Text = "Activar Aimbot"
aimbotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
aimbotButton.TextColor3 = Color3.new(1, 1, 1)
aimbotButton.Font = Enum.Font.SourceSansBold
aimbotButton.TextSize = 18

local espButton = Instance.new("TextButton", frame)
espButton.Size = UDim2.new(1, -20, 0, 50)
espButton.Position = UDim2.new(0, 10, 0, 70)
espButton.Text = "Activar ESP"
espButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.Font = Enum.Font.SourceSansBold
espButton.TextSize = 18

local speedButton = Instance.new("TextButton", frame)
speedButton.Size = UDim2.new(1, -20, 0, 50)
speedButton.Position = UDim2.new(0, 10, 0, 130)
speedButton.Text = "Activar Speed"
speedButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedButton.TextColor3 = Color3.new(1, 1, 1)
speedButton.Font = Enum.Font.SourceSansBold
speedButton.TextSize = 18

local fovSliderLabel = Instance.new("TextLabel", frame)
fovSliderLabel.Size = UDim2.new(1, -20, 0, 20)
fovSliderLabel.Position = UDim2.new(0, 10, 0, 190)
fovSliderLabel.Text = "FOV: " .. aimbotFOV
fovSliderLabel.TextColor3 = Color3.new(1,1,1)
fovSliderLabel.BackgroundTransparency = 1
fovSliderLabel.Font = Enum.Font.SourceSans
fovSliderLabel.TextSize = 14
fovSliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local fovSlider = Instance.new("TextBox", frame)
fovSlider.Size = UDim2.new(1, -20, 0, 30)
fovSlider.Position = UDim2.new(0, 10, 0, 210)
fovSlider.Text = tostring(aimbotFOV)
fovSlider.ClearTextOnFocus = false
fovSlider.TextColor3 = Color3.new(1,1,1)
fovSlider.BackgroundColor3 = Color3.fromRGB(50,50,50)
fovSlider.Font = Enum.Font.SourceSans
fovSlider.TextSize = 18

-- Funciones ESP
local function createESP(character)
    if espBoxes[character] then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = rootPart
    box.Size = Vector3.new(6, 8, 6)
    box.Transparency = 0.6
    box.Color3 = Color3.new(0, 1, 0)
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = rootPart

    espBoxes[character] = box
end

local function removeESP(character)
    if espBoxes[character] then
        espBoxes[character]:Destroy()
        espBoxes[character] = nil
    end
end

local function toggleESP(state)
    espEnabled = state
    if espEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                createESP(p.Character)
            end
        end
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(c)
                if espEnabled then createESP(c) end
            end)
        end)
        Players.PlayerRemoving:Connect(function(p)
            if p.Character then removeESP(p.Character) end
        end)
    else
        for c, box in pairs(espBoxes) do
            box:Destroy()
        end
        espBoxes = {}
    end
end

-- Buscar jugador más cercano dentro del FOV apuntando a la cabeza
local function getClosestTarget()
    local closestDist = math.huge
    local closestPart = nil
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local headPos, onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(headPos.X, headPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if dist < closestDist and dist <= aimbotFOV then
                    closestDist = dist
                    closestPart = p.Character.Head
                end
            end
        end
    end
    return closestPart
end

-- Apuntar suavemente hacia la cabeza enemiga
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestTarget()
        if target then
            local camCFrame = camera.CFrame
            local direction = (target.Position - camCFrame.Position).Unit
            local aimCFrame = CFrame.new(camCFrame.Position, camCFrame.Position + direction)
            camera.CFrame = camCFrame:Lerp(aimCFrame, aimbotSpeed)
        end
    end
end)

-- Speed hack simple (aumenta la velocidad del humanoid)
RunService.Heartbeat:Connect(function()
    if speedEnabled then
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = 32
        end
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = 16
        end
    end
end)

-- Botones del menú
aimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotButton.Text = aimbotEnabled and "Desactivar Aimbot" or "Activar Aimbot"
end)

espButton.MouseButton1Click:Connect(function()
    toggleESP(not espEnabled)
    espButton.Text = espEnabled and "Desactivar ESP" or "Activar ESP"
end)

speedButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedButton.Text = speedEnabled and "Desactivar Speed" or "Activar Speed"
end)

fovSlider.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(fovSlider.Text)
        if val and val > 0 and val <= 360 then
            aimbotFOV = val
            fovSliderLabel.Text = "FOV: " .. aimbotFOV
        else
            fovSlider.Text = tostring(aimbotFOV)
        end
    end
end)
