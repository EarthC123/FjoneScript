--Enum.KeyCode.ButtonR3
--Enum.KeyCode.ButtonL3
--Enum.KeyCode.ButtonStart
--Enum.KeyCode.ButtonSelect
--Enum.KeyCode.Thumbstick1
--game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.ActivateVehicle.Keyboard.KeyCode=Enum.KeyCode.DPadRight
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.AlternativeInput.Keyboard.KeyCode=Enum.KeyCode.ButtonL2
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.CancelActions.Keyboard.KeyCode=Enum.KeyCode.ButtonB
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.Dodge.Keyboard.KeyCode=Enum.KeyCode.ButtonX
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.Heavy.Keyboard.KeyCode=Enum.KeyCode.ButtonR1
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.Honk.Keyboard.KeyCode=Enum.KeyCode.DPadDown
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.PlacePing.Keyboard.KeyCode=Enum.KeyCode.Thumbstick2
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.PrimaryAction.Keyboard.KeyCode=Enum.KeyCode.ButtonR2
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.Reload.Keyboard.KeyCode=Enum.KeyCode.ButtonY
--game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.Rotate.Keyboard.KeyCode=
--game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.ShiftLock.Keyboard.KeyCode=
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.Sprint.Keyboard.KeyCode=Enum.KeyCode.ButtonL1
--game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.ToggleInventory.Keyboard.KeyCode=Enum.KeyCode.DPadLeft
game:GetService("Players").LocalPlayer.PlayerGui.Keybinds.VehicleLights.Keyboard.KeyCode=Enum.KeyCode.DPadUp


--[[
local backpackent = require(game:GetService("CoreGui").RobloxGui.Modules.BackpackScript)
print("Fjone:1:get backpack")
local slots=debug.getupvalue(backpackent.IsInventoryEmpty, 2)
print("Fjone:2:get slots")
local slotbytool = nil
if type(slots)=="table" and #slots > 0 then
    local slot = slots[1]
    slotbytool=debug.getupvalue(slot.Select, 5)
    print("Fjone:3:get slotbytool")
end

for tool, slot in pairs(slotbytool) do
    print("Fjone: the slot tool name is :", tool.Name, "at slot ", slot.Index)
end
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- 如果你确实想“顺手 require 一下原模块以确保它已加载”，可以取消下面这一行注释，
-- 但这个脚本本身并不依赖它暴露的 API（因为它实际上没暴露 hotbar/equip 的接口）。
-- local InventoryModule = require(game:GetService("ReplicatedStorage").Path.To.InventoryModule)

----------------------------------------------------------------
-- 配置
----------------------------------------------------------------

-- true  = 严格按槽位 Index +/- 1 切换（中间有空槽就会直接视为到边界/无目标）
-- false = 按“现有已放入 hotbar 的物品顺序”切换（更适合手柄）
local STRICT_ADJACENT_INDEX = false

-- 是否只响应 1 号手柄
local ONLY_GAMEPAD1 = false

----------------------------------------------------------------
-- 获取 UI
----------------------------------------------------------------

local function waitForInventoryGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local userGui = playerGui:WaitForChild("UserGui")
	local inventory = userGui:WaitForChild("Inventory")
	local hotbar = inventory:WaitForChild("Hotbar")
	return hotbar
end

local hotbar = waitForInventoryGui()

----------------------------------------------------------------
-- 角色 / 背包
----------------------------------------------------------------

local function getCharacter(): Model
	return player.Character or player.CharacterAdded:Wait()
end

local function getBackpack(): Backpack
	return player:WaitForChild("Backpack") :: Backpack
end

----------------------------------------------------------------
-- Hotbar 按钮工具函数
----------------------------------------------------------------

local function isHotbarButton(inst: Instance): boolean
	if not inst:IsA("TextButton") then
		return false
	end

	local toolLink = inst:FindFirstChild("ToolLink")
	if not toolLink or not toolLink:IsA("ObjectValue") then
		return false
	end

	return true
end

local function getButtonTool(button: TextButton): Tool?
	local toolLink = button:FindFirstChild("ToolLink")
	if toolLink and toolLink:IsA("ObjectValue") then
		local value = toolLink.Value
		if value and value:IsA("Tool") then
			return value
		end
	end
	return nil
end

local function getButtonIndex(button: TextButton): number?
	local idx = button:GetAttribute("Index")
	if typeof(idx) == "number" then
		return idx
	end
	return nil
end

local function getHotbarButtons(): {TextButton}
	local result = {}

	for _, child in ipairs(hotbar:GetChildren()) do
		if isHotbarButton(child) then
			local button = child :: TextButton
			local tool = getButtonTool(button)
			local idx = getButtonIndex(button)

			-- 只保留真正已在 hotbar 里并且有槽位编号的按钮
			if tool and idx then
				table.insert(result, button)
			end
		end
	end

	table.sort(result, function(a, b)
		local ai = getButtonIndex(a) or math.huge
		local bi = getButtonIndex(b) or math.huge
		return ai < bi
	end)

	return result
end

local function findButtonByTool(tool: Tool): TextButton?
	for _, button in ipairs(getHotbarButtons()) do
		if getButtonTool(button) == tool then
			return button
		end
	end
	return nil
end

local function findButtonByIndex(index: number): TextButton?
	for _, button in ipairs(getHotbarButtons()) do
		if getButtonIndex(button) == index then
			return button
		end
	end
	return nil
end

----------------------------------------------------------------
-- 当前装备状态
----------------------------------------------------------------

local function getEquippedTool(): Tool?
	local character = getCharacter()
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local function getCurrentEquippedButton(): TextButton?
	-- 优先通过 Character 里的 Tool 反查，对齐真实装备状态
	local equippedTool = getEquippedTool()
	if equippedTool then
		local byTool = findButtonByTool(equippedTool)
		if byTool then
			return byTool
		end
	end

	-- 兜底：看 UI 上哪个按钮 Equipped == true
	for _, button in ipairs(getHotbarButtons()) do
		if button:GetAttribute("Equipped") == true then
			return button
		end
	end

	return nil
end

----------------------------------------------------------------
-- 装备 / 取消装备
----------------------------------------------------------------

local function unequipAllTools()
	local character = getCharacter()
	local backpack = getBackpack()

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			child.Parent = backpack
		end
	end
end

local function equipButton(button: TextButton?)
	if not button then
		unequipAllTools()
		return
	end

	local tool = getButtonTool(button)
	if not tool then
		unequipAllTools()
		return
	end

	local character = getCharacter()
	local backpack = getBackpack()

	-- 与原模块逻辑保持一致：先把当前手上的 Tool 全部放回 Backpack，再装备目标 Tool
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			child.Parent = backpack
		end
	end

	-- 只有当 tool 还在 Backpack / Character 下时才切过去
	if tool.Parent == backpack or tool.Parent == character then
		tool.Parent = character
	end
end

----------------------------------------------------------------
-- 左右切换
----------------------------------------------------------------

local function navigateByVisibleOrder(direction: number)
	local buttons = getHotbarButtons()
	if #buttons == 0 then
		return
	end

	local currentButton = getCurrentEquippedButton()

	-- 当前没装备：右 -> 第一个；左 -> 最后一个
	if not currentButton then
		if direction > 0 then
			equipButton(buttons[1])
		else
			equipButton(buttons[#buttons])
		end
		return
	end

	local currentPos = nil
	for i, button in ipairs(buttons) do
		if button == currentButton then
			currentPos = i
			break
		end
	end

	if not currentPos then
		-- 理论上不该发生，兜底
		if direction > 0 then
			equipButton(buttons[1])
		else
			equipButton(buttons[#buttons])
		end
		return
	end

	local targetPos = currentPos + direction
	if targetPos < 1 or targetPos > #buttons then
		-- 到头：取消装备
		equipButton(nil)
		return
	end

	equipButton(buttons[targetPos])
end

local function navigateByStrictIndex(direction: number)
	local currentButton = getCurrentEquippedButton()

	-- 当前没装备时：右 -> 最小 Index；左 -> 最大 Index
	if not currentButton then
		local buttons = getHotbarButtons()
		if #buttons == 0 then
			return
		end

		if direction > 0 then
			equipButton(buttons[1])
		else
			equipButton(buttons[#buttons])
		end
		return
	end

	local currentIndex = getButtonIndex(currentButton)
	if not currentIndex then
		equipButton(nil)
		return
	end

	local targetIndex = currentIndex + direction
	local targetButton = findButtonByIndex(targetIndex)

	if targetButton then
		equipButton(targetButton)
	else
		-- 没有相邻槽位，视为到头/无目标：取消装备
		equipButton(nil)
	end
end

local function navigate(direction: number)
	if STRICT_ADJACENT_INDEX then
		navigateByStrictIndex(direction)
	else
		navigateByVisibleOrder(direction)
	end
end

----------------------------------------------------------------
-- 手柄输入
----------------------------------------------------------------

local function isGamepadInput(input: InputObject): boolean
	if ONLY_GAMEPAD1 then
		return input.UserInputType == Enum.UserInputType.Gamepad1
	end

	-- 兼容任意 GamepadX
	return string.match(input.UserInputType.Name, "^Gamepad") ~= nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if not isGamepadInput(input) then
		return
	end

	if input.KeyCode == Enum.KeyCode.DPadLeft then
		navigate(-1)
	elseif input.KeyCode == Enum.KeyCode.DPadRight then
		navigate(1)
	end
end)

local plrsrv = game:GetService("Players")
local localplayer = plrsrv.LocalPlayer

local function CheckDriving()
    if localplayer:GetAttribute("_IsDriving") then
        
    else
        
    end
end

localplayer:GetAttributeChangedSignal("_IsDriving"):Connect(CheckDriving)
