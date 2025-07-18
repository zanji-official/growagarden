local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "CustomGUI"
screenGui.ResetOnSpawn = false

--== Modern Styled GUI Setup (from test.lua style) ==--
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "EggRandomizerGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 120)
main.Position = UDim2.new(0.5, -110, 0.5, -60)
main.BackgroundColor3 = Color3.fromRGB(24, 34, 38)
main.Active = true
main.Draggable = true
main.ZIndex = 10
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(80, 200, 180)
stroke.Thickness = 2

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(28, 44, 48)
Instance.new("UICorner", header)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, 0, 1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "ZANJI: EGG RANDOMIZER"
title.TextColor3 = Color3.fromRGB(220, 240, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Center

-- Remove closeBtn (X) and minimizeBtn

-- Restore Button
local restoreBtn = Instance.new("TextButton", gui)
restoreBtn.Size = UDim2.new(0, 48, 0, 48)
restoreBtn.Position = UDim2.new(0, 15, 0.5, -32)
restoreBtn.BackgroundColor3 = Color3.fromRGB(28, 44, 48)
restoreBtn.Text = "Z"
restoreBtn.Font = Enum.Font.FredokaOne
restoreBtn.TextColor3 = Color3.fromRGB(80, 200, 180)
restoreBtn.TextSize = 40
restoreBtn.Visible = false
Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(1, 0)
restoreBtn.Active = true
restoreBtn.Draggable = true
restoreBtn.ClipsDescendants = true
local restoreGlow = Instance.new("UIStroke", restoreBtn)
restoreGlow.Color = Color3.fromRGB(80, 200, 180)
restoreGlow.Thickness = 1
restoreGlow.Transparency = 0.15
restoreGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local particleFolder = Instance.new("Folder", restoreBtn)
particleFolder.Name = "Particles"
local function spawnRestoreParticle()
    local particle = Instance.new("Frame")
    particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
    local maxX = 1 - (particle.Size.X.Offset / restoreBtn.Size.X.Offset)
    local maxY = 1 - (particle.Size.Y.Offset / restoreBtn.Size.Y.Offset)
    particle.Position = UDim2.new(math.random() * maxX, 0, math.random() * maxY, 0)
    particle.BackgroundColor3 = Color3.fromRGB(
        80 + math.random(-10, 10),
        200 + math.random(-10, 10),
        180 + math.random(-10, 10)
    )
    particle.BackgroundTransparency = 0.15
    particle.BorderSizePixel = 0
    particle.ZIndex = 10
    particle.Parent = particleFolder
    Instance.new("UICorner", particle).CornerRadius = UDim.new(1, 0)
    local goal = {
        Position = UDim2.new(math.random() * maxX, 0, math.random() * maxY, 0),
        BackgroundTransparency = 1
    }
    local tween = TweenService:Create(particle, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
    tween:Play()
    tween.Completed:Connect(function()
        particle:Destroy()
    end)
end
task.spawn(function()
    while true do
        if restoreBtn.Visible then
            spawnRestoreParticle()
            task.wait(0.08)
        else
            task.wait(0.2)
        end
    end
end)
restoreBtn.MouseButton1Click:Connect(function()
    main.Visible = true
    restoreBtn.Visible = false
end)

-- Content Area (Page)
local page = Instance.new("Frame", main)
page.Size = UDim2.new(1, -16, 1, -38)
page.Position = UDim2.new(0, 8, 0, 32)
page.BackgroundColor3 = Color3.fromRGB(20, 28, 32)
page.ZIndex = 11
Instance.new("UICorner", page)

--== Shared Variables ==--
local updateAllEsp = nil
local activeEggs = {}
local espCache = {}
local eggPets = {}
local customPetNames = {} -- ✅ custom pet overrides

--== Cooldown Timer Label ==--
local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Parent = page
cooldownLabel.Position = UDim2.new(0, 0, 0, 120)
cooldownLabel.Size = UDim2.new(0, 240, 0, 25)
cooldownLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
cooldownLabel.TextColor3 = Color3.new(1, 1, 1)
cooldownLabel.TextScaled = true
cooldownLabel.Font = Enum.Font.SourceSansBold
cooldownLabel.Visible = false

--== Toggle Button Creation ==--
local function createToggle(name, pos, initialState, callback)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = pos
	frame.Size = UDim2.new(0, 240, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = page

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.TextScaled = true
	button.Font = Enum.Font.SourceSansBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = frame

	local isOn = initialState
	local randomizerRunning = false

	local function updateText()
		local icon = isOn and "🟢" or "🔴"
		local status = isOn and "ON" or "OFF"
		if name == "AutoHatch" then
			button.Text = icon .. " Auto Hatch:\n" .. status
		elseif name == "AutoRandomizer" then
			button.Text = icon .. " Auto\nRandomizer: " .. status
		end
	end

	button.MouseButton1Click:Connect(function()
		isOn = not isOn
		updateText()

		if name == "AutoRandomizer" then
			if isOn and not randomizerRunning then
				randomizerRunning = true
				task.spawn(function()
					while isOn do
						if callback then callback(true) end
						cooldownLabel.Visible = true
						for i = 10, 1, -1 do
							cooldownLabel.Text = "Cooldown: " .. i .. "s"
							task.wait(1)
						end
						cooldownLabel.Text = "Randomizing..."
						task.wait(3)

						-- ✅ Handle Dinosaur Egg Randomization
						for objectId, object in activeEggs do
							local eggName = object:GetAttribute("EggName")
							if eggName == "Dinosaur Egg" and not customPetNames[objectId] then
								local roll = math.random()
								local pet
								if roll < 0.01 then
									pet = "Brontosaurus"
								elseif roll < 0.04 then
									pet = "Pterodactyl"
								elseif roll < 0.32 then
									pet = "Stegosaurus"
								elseif roll < 0.645 then
									pet = "Triceratops"
								else
									pet = "Raptor"
								end
								customPetNames[objectId] = pet
								UpdateEsp(objectId, pet)
							end
						end
						-- ✅ Handle Common Egg Randomization
						for objectId, object in activeEggs do
							local eggName = object:GetAttribute("EggName")
							if eggName == "Common Egg" and not customPetNames[objectId] then
								local roll = math.random()
								local pet
								if roll < 1/3 then
									pet = "Dog"
								elseif roll < 2/3 then
									pet = "Golden Lab"
								else
									pet = "Bunny"
								end
								customPetNames[objectId] = pet
								UpdateEsp(objectId, pet)
							end
						end
					end
					cooldownLabel.Visible = false
					cooldownLabel.Text = ""
					randomizerRunning = false
				end)
			end
		else
			if callback then callback(isOn) end
		end
	end)

	updateText()
end

-- Remove AutoHatch toggle, help (question mark) button, and X (exit) button below it
-- Remove createToggle("AutoHatch", ...)

-- Remove helpButton, helpPopup, exitButton and their logic

--== ESP Logic ==--
local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local runService = game:GetService("RunService")
local currentCamera = workspace.CurrentCamera
local localPlayer = player

local hatchFunction = getupvalue(getupvalue(getconnections(replicatedStorage.GameEvents.PetEggService.OnClientEvent)[1].Function, 1), 2)
local eggModels = getupvalue(hatchFunction, 1)
eggPets = getupvalue(hatchFunction, 2)

local function getObjectFromId(objectId)
	for eggModel in eggModels do
		if eggModel:GetAttribute("OBJECT_UUID") == objectId then
			return eggModel
		end
	end
end

function UpdateEsp(objectId, fallbackPetName)
	local object = getObjectFromId(objectId)
	if not object or not espCache[objectId] then return end

	local eggName = object:GetAttribute("EggName")
	local displayName = customPetNames[objectId] or fallbackPetName or "Cannot hatch yet!"
	espCache[objectId].Text = `{eggName} | {displayName}`
end

local function AddEsp(object)
	if object:GetAttribute("OWNER") ~= localPlayer.Name then return end

	local eggName = object:GetAttribute("EggName")
	local petName = eggPets[object:GetAttribute("OBJECT_UUID")]
	local objectId = object:GetAttribute("OBJECT_UUID")
	if not objectId then return end

	local label = Drawing.new("Text")
	label.Text = `{eggName} | {petName or "Cannot hatch yet!"}`
	label.Size = 24
	label.Color = Color3.new(1, 1, 1)
	label.Outline = true
	label.OutlineColor = Color3.new(0, 0, 0)
	label.Center = true
	label.Visible = false
	label.ZIndex = 1 -- ESP always behind GUI

	espCache[objectId] = label
	activeEggs[objectId] = object
end

local function RemoveEsp(object)
	if object:GetAttribute("OWNER") ~= localPlayer.Name then return end
	local objectId = object:GetAttribute("OBJECT_UUID")
	if espCache[objectId] then
		espCache[objectId]:Remove()
		espCache[objectId] = nil
	end
	activeEggs[objectId] = nil
end

updateAllEsp = function()
	for objectId, object in activeEggs do
		local petName = eggPets[objectId]
		UpdateEsp(objectId, petName)
	end
end

local function UpdateEspPositions()
	for objectId, object in activeEggs do
		if not object or not object:IsDescendantOf(workspace) then
			activeEggs[objectId] = nil
			if espCache[objectId] then
				espCache[objectId].Visible = false
			end
			continue
		end

		local label = espCache[objectId]
		if label then
			local pos, onScreen = currentCamera:WorldToViewportPoint(object:GetPivot().Position)
			label.Visible = onScreen
			if onScreen then
				label.Position = Vector2.new(pos.X, pos.Y)
			end
		end
	end
end

-- Hook hatch to update ESP
local old
old = hookfunction(getconnections(replicatedStorage.GameEvents.EggReadyToHatch_RE.OnClientEvent)[1].Function, newcclosure(function(objectId, petName)
	UpdateEsp(objectId, petName)
	return old(objectId, petName)
end))

-- Init ESP on current eggs
for _, object in collectionService:GetTagged("PetEggServer") do
	task.spawn(AddEsp, object)
end
collectionService:GetInstanceAddedSignal("PetEggServer"):Connect(AddEsp)
collectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(RemoveEsp)
runService.PreRender:Connect(UpdateEspPositions)

--== Randomize Button and Auto Checkbox ==--
local autoRandomize = false
local randomizing = false
local autoPrimed = false -- user must tap Randomize first

-- Auto Checkbox
local autoCheckFrame = Instance.new("Frame", page)
autoCheckFrame.Position = UDim2.new(0, 10, 0, 8)
autoCheckFrame.Size = UDim2.new(0, 120, 0, 24)
autoCheckFrame.BackgroundTransparency = 1

local autoCheckbox = Instance.new("TextButton", autoCheckFrame)
autoCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoCheckbox.Position = UDim2.new(0, 0, 0, 2)
autoCheckbox.BackgroundColor3 = Color3.fromRGB(28, 44, 48)
autoCheckbox.Text = ""
autoCheckbox.AutoButtonColor = true
Instance.new("UICorner", autoCheckbox).CornerRadius = UDim.new(1, 0)
local checkMark = Instance.new("TextLabel", autoCheckbox)
checkMark.Size = UDim2.new(1, 0, 1, 0)
checkMark.Position = UDim2.new(0, 0, 0, 0)
checkMark.BackgroundTransparency = 1
checkMark.Text = ""
checkMark.TextColor3 = Color3.fromRGB(80, 200, 180)
checkMark.Font = Enum.Font.GothamBold
checkMark.TextSize = 18

local autoLabel = Instance.new("TextLabel", autoCheckFrame)
autoLabel.Size = UDim2.new(0, 90, 1, 0)
autoLabel.Position = UDim2.new(0, 26, 0, 0)
autoLabel.BackgroundTransparency = 1
autoLabel.Text = "Auto Randomize"
autoLabel.TextColor3 = Color3.fromRGB(220, 240, 235)
autoLabel.Font = Enum.Font.GothamBold
autoLabel.TextSize = 14
autoLabel.TextXAlignment = Enum.TextXAlignment.Left

autoCheckbox.MouseButton1Click:Connect(function()
    autoRandomize = not autoRandomize
    checkMark.Text = autoRandomize and "✔" or ""
    -- Reset autoPrimed if unchecked
    if not autoRandomize then
        autoPrimed = false
    end
end)

-- Randomize Button
local randomizeBtn = Instance.new("TextButton", page)
randomizeBtn.Text = "RANDOMIZE"
randomizeBtn.Size = UDim2.new(0, 180, 0, 32)
randomizeBtn.Position = UDim2.new(0, 10, 0, 40)
randomizeBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 180)
randomizeBtn.TextColor3 = Color3.fromRGB(24, 34, 38)
randomizeBtn.Font = Enum.Font.GothamBold
randomizeBtn.TextSize = 16
Instance.new("UICorner", randomizeBtn)
randomizeBtn.ZIndex = 10

-- Loading Animation Frame
local loadingFrame = Instance.new("Frame", gui)
loadingFrame.Size = UDim2.new(0, 260, 0, 110)
loadingFrame.Position = UDim2.new(0.5, -130, 0.5, -55)
loadingFrame.BackgroundColor3 = Color3.fromRGB(24, 34, 38)
loadingFrame.ZIndex = 20
loadingFrame.Visible = false
loadingFrame.Active = true
loadingFrame.Draggable = true
Instance.new("UICorner", loadingFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", loadingFrame)
stroke.Color = Color3.fromRGB(80, 200, 180)
stroke.Thickness = 2

local particleFolder = Instance.new("Folder", loadingFrame)
particleFolder.Name = "Particles"
local function spawnParticle()
    local particle = Instance.new("Frame")
    particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
    local maxX = 1 - (particle.Size.X.Offset / loadingFrame.Size.X.Offset)
    local maxY = 1 - (particle.Size.Y.Offset / loadingFrame.Size.Y.Offset)
    particle.Position = UDim2.new(math.random() * maxX, 0, math.random() * maxY, 0)
    particle.BackgroundColor3 = Color3.fromRGB(
        80 + math.random(-10, 10),
        200 + math.random(-10, 10),
        180 + math.random(-10, 10)
    )
    particle.BackgroundTransparency = 0.15
    particle.BorderSizePixel = 0
    particle.ZIndex = 101
    particle.Parent = particleFolder
    Instance.new("UICorner", particle).CornerRadius = UDim.new(1, 0)
    local goal = {
        Position = UDim2.new(math.random() * maxX, 0, math.random() * maxY, 0),
        BackgroundTransparency = 1
    }
    local tween = TweenService:Create(particle, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
    tween:Play()
    tween.Completed:Connect(function()
        particle:Destroy()
    end)
end

-- Only animate when visible
spawn(function()
    while true do
        if loadingFrame.Visible then
            spawnParticle()
            wait(0.08)
        else
            wait(0.2)
        end
    end
end)

local loadingLabel = Instance.new("TextLabel", loadingFrame)
loadingLabel.Size = UDim2.new(1, -20, 0, 32)
loadingLabel.Position = UDim2.new(0, 10, 0, 10)
loadingLabel.Text = "Randomizing Egg"
loadingLabel.TextColor3 = Color3.fromRGB(220, 240, 235)
loadingLabel.Font = Enum.Font.GothamBold
loadingLabel.TextSize = 18
loadingLabel.BackgroundTransparency = 1
loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
loadingLabel.TextYAlignment = Enum.TextYAlignment.Center

local barBG = Instance.new("Frame", loadingFrame)

barBG.Size = UDim2.new(0.85, 0, 0, 12)
barBG.Position = UDim2.new(0.075, 0, 0, 55)
barBG.BackgroundColor3 = Color3.fromRGB(28, 44, 48)
Instance.new("UICorner", barBG).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame", barBG)
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(80, 200, 180)
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
local glow = Instance.new("UIStroke", bar)
glow.Color = Color3.fromRGB(120, 220, 210)
glow.Thickness = 2
glow.Transparency = 0.3
glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local percent = Instance.new("TextLabel", loadingFrame)
percent.Size = UDim2.new(0, 80, 0, 20)
percent.Position = UDim2.new(0.5, -40, 0, 75)
percent.Text = "0%"
percent.TextColor3 = Color3.fromRGB(220, 240, 235)
percent.Font = Enum.Font.GothamBold
percent.TextSize = 14
percent.BackgroundTransparency = 1
percent.TextXAlignment = Enum.TextXAlignment.Center
percent.TextYAlignment = Enum.TextYAlignment.Center

local function getRandomColor()
    return Color3.fromHSV(math.random(), 1, 1)
end

local function getRandomPet(eggName, excludePet)
    local petTable = {
        ["Common Egg"] = {"Dog", "Golden Lab", "Bunny"},
        ["Mythical Egg"] = {"Grey Mouse", "Brown Mouse", "Squirrel", "Red Giant Ant", "Red Fox"},
        ["Bug Egg"] = {"Caterpillar", "Snail", "Giant Ant", "Praying Mantis", "Dragonfly"},
        ["Common Summer Egg"] = {"Starfish", "Seagull", "Crab"},
        ["Rare Summer Egg"] = {"Flamingo", "Toucan", "Sea Turtle", "Orangutan", "Seal"},
        ["Paradise Egg"] = {"Ostrich", "Peacock", "Capybara", "Scarlet Macaw", "Mimic Octopus"},
        ["Bee Egg"] = {"Bee", "Honey Bee", "Bear Bee", "Petal Bee", "Queen Bee"},
        ["Dinosaur Egg"] = {"Raptor", "Triceratops", "Stegosaurus", "Pterodactyl", "Brontosaurus"},
        ["Primal Egg"] = {"Parasaurolophus", "Iguanodon", "Pachycephalosaurus", "Dilophosaurus", "Ankylosaurus", "Spinosaurus"},
        ["Oasis Egg"] = {"Meerkat", "Sand Snake", "Axolotl", "Hyacinth Macaw", "Fennec Fox"},
        ["Anti Bee Egg"] = {"Wasp", "Tarantula Hawk", "Moth", "Butterfly", "Disco Bee"},
        ["Night Egg"] = {"Hedgehog", "Mole", "Frog", "Echo Frog", "Night Owl", "Raccoon"},
        ["Uncommon Egg"] = {"Black Bunny", "Chicken", "Cat", "Deer"},
        ["Rare Egg"] = {"Orange Tabby", "Spotted Deer", "Pig", "Rooster", "Monkey"},
        ["Legendary Egg"] = {"Cow", "Silver Monkey", "Sea Otter", "Turtle", "Polar Bear"},
    }
    local weights = {
        ["Common Egg"] = {0.33, 0.33, 0.34},
        ["Mythical Egg"] = {0.36, 0.27, 0.27, 0.085, 0.015},
        ["Bug Egg"] = {0.40, 0.30, 0.25, 0.04, 0.01},
        ["Common Summer Egg"] = {0.5, 0.25, 0.25},
        ["Rare Summer Egg"] = {0.3, 0.25, 0.2, 0.15, 0.1},
        ["Paradise Egg"] = {0.4, 0.3, 0.21, 0.08, 0.01},
        ["Bee Egg"] = {0.65, 0.25, 0.05, 0.04, 0.01},
        ["Dinosaur Egg"] = {0.35, 0.325, 0.28, 0.03, 0.015},
        ["Primal Egg"] = {0.35, 0.325, 0.28, 0.03, 0.01, 0.005},
        ["Oasis Egg"] = {0.45, 0.345, 0.15, 0.05, 0.005},
        ["Anti Bee Egg"] = {0.55, 0.3, 0.1375, 0.01, 0.0025},
        ["Night Egg"] = {0.47, 0.235, 0.1674, 0.0823, 0.0353, 0.001},
        ["Uncommon Egg"] = {0.25, 0.25, 0.25, 0.25},
        ["Rare Egg"] = {0.3333, 0.25, 0.1667, 0.1667, 0.0833},
        ["Legendary Egg"] = {0.4255, 0.4255, 0.1064, 0.0213, 0.0213},
    }
    local pets = petTable[eggName]
    local ws = weights[eggName]
    if not pets or not ws then return nil end
    local availablePets, availableWeights = {}, {}
    for i, pet in ipairs(pets) do
        if pet ~= excludePet then
            table.insert(availablePets, pet)
            table.insert(availableWeights, ws[i])
        end
    end
    -- Normalize weights
    local total = 0
    for _, w in ipairs(availableWeights) do total = total + w end
    local normWeights = {}
    for i, w in ipairs(availableWeights) do normWeights[i] = w / total end
    -- Weighted random selection
    local r = math.random()
    local acc = 0
    for i, w in ipairs(normWeights) do
        acc = acc + w
        if r <= acc then
            return availablePets[i]
        end
    end
    return availablePets[#availablePets]
end

local lastPetPerEgg = {}
local function doRandomize()
    for objectId, object in activeEggs do
        local currentPet = customPetNames[objectId]
        if currentPet == nil then
            -- fallback to ESP label text parsing if needed
            local label = espCache[objectId]
            if label and label.Text then
                local parts = string.split(label.Text, " | ")
                currentPet = parts[2]
            end
        end
        if currentPet == "Cannot hatch yet!" then
            continue -- skip eggs that cannot hatch yet
        end
        local eggName = object:GetAttribute("EggName")
        local lastPet = lastPetPerEgg[objectId]
        local pet = getRandomPet(eggName, lastPet)
        if pet then
            lastPetPerEgg[objectId] = customPetNames[objectId] -- store previous pet for exclusion next time
            customPetNames[objectId] = pet
            UpdateEsp(objectId, pet)
        end
    end
end

local function showLoadingAndRandomize(callback)
    loadingFrame.Visible = true
    bar.Size = UDim2.new(0, 0, 1, 0)
    percent.Text = "0%"
    loadingLabel.Text = "Randomizing Egg"
    local totalTime = 10
    local steps = 100
    for i = 1, steps do
        TweenService:Create(bar, TweenInfo.new(totalTime / steps), {
            Size = UDim2.new(i / steps, 0, 1, 0)
        }):Play()
        percent.Text = i .. "%"
        wait(totalTime / steps)
    end
    loadingFrame.Visible = false
    if callback then callback() end
end

randomizeBtn.MouseButton1Click:Connect(function()
    if randomizing then return end
    randomizing = true
    -- If auto is checked, prime auto mode after this run
    if autoRandomize then
        autoPrimed = true
    end
    showLoadingAndRandomize(function()
        doRandomize()
        randomizing = false
    end)
end)

spawn(function()
    while true do
        if autoRandomize and autoPrimed and not randomizing then
            randomizing = true
            showLoadingAndRandomize(function()
                doRandomize()
                randomizing = false
            end)
        end
        wait(0.1)
    end
end)
