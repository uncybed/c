-- aimlock by cybe42
-- loadstring(game:HttpGet('https://uncybed.github.io/aimlock.lua'))()
--  OR
-- loadstring(HttpGet('https://uncybed.github.io/aimlock.lua'))()

if _G.aimlockmoduleloaded == true then return end

local ver = "v0.0.1"

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua'))()
local players = game:GetService("Players")

local Window = Rayfield:CreateWindow({
	Name = "aimlock "..ver,
	LoadingTitle = "aimlock "..ver,
	LoadingSubtitle = "by cybe42",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "aimlock",
		FileName = "conf"
	},
	KeySystem = false
})

local Tab = Window:CreateTab("Settings", 4483362458) -- Title, Image
local Tab2 = Window:CreateTab("Finetune", 4483362458)

local Toggle = Tab:CreateToggle({
	Name = "Toggle",
	CurrentValue = false,
	Flag = "enabled", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		_G.aimbotEnabled = Value
	end,
})
local Toggle = Tab:CreateToggle({
	Name = "Team Check",
	CurrentValue = false,
	Flag = "teamcheck", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		_G.teamCheck = Value
	end,
})

local aimpart = Tab:CreateDropdown({
	Name = "Aim part",
	Options = {"Head", "HumanoidRootPart"},
	CurrentOption = "Head",
	Flag = "aimpart", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	MultipleOptions = false,
	Callback = function(Option)
		for _, val in pairs(Option) do
			_G.aimPart = val
		end
	end,
})

local Slider = Tab:CreateSlider({
	Name = "Delay",
	Range = {0, 150},
	Increment = 1,
	Suffix = "milliseconds",
	CurrentValue = 0,
	Flag = "delay", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		_G.sensitivity = Value/1000
	end,
})

local Keybind = Tab:CreateKeybind({
	Name = "Aimlock Key",
	CurrentKeybind = "LeftControl",
	HoldToInteract = false,
	Flag = "keybind", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	CallOnChange = true,
	Callback = function(Keybind)
		local enumkeybind = Enum.KeyCode[Keybind]
		if enumkeybind then
			_G.activationKey = enumkeybind
		end
	end,
})

local opt = {}
for _,v in pairs(players:GetChildren()) do
	if v.Name ~= players.LocalPlayer.Name then
		table.insert(opt, v.Name)
	end
end
local realexceptions = {}

local Dropdown = Tab:CreateDropdown({
	Name = "Exceptions",
	Options = opt,
	CurrentOption = "",
	Flag = "exceptionlist",
	MultipleOptions = true,
	Callback = function(Option)
		local tempexc = {}
		for key, val in pairs(Option) do
			if val ~= "" then
				table.insert(tempexc, val)
			end
		end
		_G.exceptionList = tempexc
	end,
})

local Button2 = Tab:CreateButton({
	Name = "Refresh List",
	Callback = function()
		if Dropdown then
			opt = {}
			for _,v in pairs(players:GetChildren()) do
				if v.Name ~= players.LocalPlayer.Name then
					table.insert(opt, v.Name)
				end
			end
			Dropdown:Refresh(opt)
		end
	end,
})

local Toggle2 = Tab2:CreateToggle({
	Name = "Click Pause",
	CurrentValue = false,
	Flag = "clickpause", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		_G.aimlockclickpause = Value
	end,
})

local Slider2 = Tab2:CreateSlider({
	Name = "Click pause delay",
	Range = {0, 4},
	Increment = 0.01,
	Suffix = "seconds",
	CurrentValue = 0,
	Flag = "clickpausedelay", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		_G.aimlockclickpausedelay = Value
	end,
})

coroutine.wrap(function()
	if _G.aimlockmoduleloaded == true then
		return
	end
	_G.aimlockmoduleloaded = true
	_G.aimlockclickpause = false
	_G.aimlockclickpausedelay = 1
	local camera = workspace.CurrentCamera
	local runService = game:GetService("RunService")
	local userInputService = game:GetService("UserInputService")
	local tweenService = game:GetService("TweenService")
	local localPlayer = game.Players.LocalPlayer
	_G.keyholding = false

	_G.aimbotEnabled = false
	_G.teamCheck = false -- if set to true then the script would only lock your aim at enemy team members.
	_G.aimPart = "Head" -- where the aimbot script would lock at.
	_G.sensitivity = 0 -- how many seconds it takes for the aimbot script to officially lock onto the target's aimpart.
	_G.exceptionList = {} -- list of players to ignore
	_G.activationKey = Enum.KeyCode.LeftControl -- key to activate the aimbot

	local aimbotPaused = false -- State for pausing the aimbot

	local function getClosestPlayer()
		local maximumDistance = math.huge
		local target = nil

		coroutine.wrap(function()
			wait(20)
			maximumDistance = math.huge
		end)()

		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Name ~= localPlayer.Name and not table.find(_G.exceptionList, player.Name) then
				if not (_G.teamCheck and player.Team == localPlayer.Team) then
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
						local screenPoint = camera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
						local vectorDistance = (Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

						local directionToTarget = (player.Character.HumanoidRootPart.Position - camera.CFrame.Position).Unit
						local cameraDirection = camera.CFrame.LookVector
						local dotProduct = cameraDirection:Dot(directionToTarget)
						local fieldOfVision = math.cos(math.rad(camera.FieldOfView / 2))

						if vectorDistance < maximumDistance and dotProduct > fieldOfVision then
							target = player
							maximumDistance = vectorDistance
						end
					end
				end
			end
		end

		return target
	end

	userInputService.InputBegan:Connect(function(input)
		if _G.aimlockclickpause == true and input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Pause aimbot for 2 seconds on left-click
			if not aimbotPaused then
				aimbotPaused = true
				wait(_G.aimlockclickpausedelay)
				aimbotPaused = false
			end
		elseif input.KeyCode == _G.activationKey then
			_G.keyholding = true
		end
	end)

	userInputService.InputEnded:Connect(function(input)
		if input.KeyCode == _G.activationKey then
			_G.keyholding = false
		end
	end)

	runService.RenderStepped:Connect(function()
		if _G.keyholding and _G.aimbotEnabled and not aimbotPaused then
			local closestPlayer = getClosestPlayer()
			if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild(_G.aimPart) then
				tweenService:Create(
					camera,
					TweenInfo.new(_G.sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{CFrame = CFrame.new(camera.CFrame.Position, closestPlayer.Character[_G.aimPart].Position)}
				):Play()
			end
		end
	end)
end)()
