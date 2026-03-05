local map
local plrsrv = game:GetService("Players")
local plr = plrsrv.LocalPlayer
local localcharacter = plr.Character or plr.CharacterAdded:Wait()
local plrgui = plr:WaitForChild("PlayerGui")
local localroot = localcharacter:WaitForChild("HumanoidRootPart")

function getMap()
	if map and map.Parent then
		return map
	end
	map = workspace.CurrentRoom:FindFirstChildWhichIsA("Model");
	return map
end

function forceStop()
	local decoding = localcharacter.Decoding.Value
	if decoding ~= nil then
		decoding.Stats.StopInteracting:FireServer("Stop")
	end
	return not plrgui.ScreenGui.Menu.StopGenerator.Visible
end

-- Function to get model center
function getModelCenter(model)
	if not model or not model:IsA("Model") then return nil end

	local parts = {}
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end
	if #parts == 0 then return nil end

	local totalPosition = Vector3.zero
	for _, part in pairs(parts) do
		totalPosition = totalPosition + part.Position
	end
	return totalPosition / #parts
end

-- Function to get Fake Elevator Position
function getFakeElevatorPosition()
	local freeArea = getMap():FindFirstChild("FreeArea")
	if freeArea then
		local fakeElevator = freeArea:FindFirstChild("FakeElevator")
		if fakeElevator and fakeElevator:IsA("Model") then
			local center = getModelCenter(fakeElevator)
			return center
		end
	end
end

function clientinvalidposdetect(playerposition)
	if not playerposition or typeof(playerposition) ~= "Vector3" then
		return false
	end
	--print("x,y,z=",playerposition.X,playerposition.Y,playerposition.Z)
	if playerposition.Magnitude > 2000 then
	    print("2000 fail")
		return false
	end
	--y<=50 will trigger tp, normal y is 100
	if playerposition.Y < 80 then
		print("playerposition.Y=",playerposition.Y)
		return false
	end
	if playerposition.X ~= playerposition.X or (playerposition.Y ~= playerposition.Y or playerposition.Z ~= playerposition.Z) then
		return false
	end
	local v8 = playerposition.X
	if math.abs(v8) ~= (1 / 0) then
		local v9 = playerposition.Y
		if math.abs(v9) ~= (1 / 0) then
			local v10 = playerposition.Z
			if math.abs(v10) ~= (1 / 0) then
				return true
			end
		end
	end
	print("final")
	return false
end

function teleportplr(cf)
	workspace.Gravity = 0
	localroot.AssemblyLinearVelocity = Vector3.zero
	localcharacter:PivotTo(cf)
	workspace.Gravity = 196.2
end

task.spawn(
function()
	while true do
		if getMap() then
			--fix when spoted, there is a chance still doing machine
			local monstersFolder = getMap():FindFirstChild("Monsters")
			if monstersFolder then
				for _, monster in monstersFolder:GetChildren() do
					if monster:FindFirstChild("ChasingValue") and monster.ChasingValue.Value == localcharacter then
						forceStop()
					end
				end
			end
			--fix tp to elevator front when fall out of map
			local playerposition = localcharacter.HumanoidRootPart.Position
			if not clientinvalidposdetect(playerposition) then
			    print("x,y,z=",playerposition.X,playerposition.Y,playerposition.Z)
				local fakeElevatorPosition = getFakeElevatorPosition()
				if fakeElevatorPosition then
					teleportplr(CFrame.new(fakeElevatorPosition))
				end
			end
		end
		task.wait(1/15)
	end
end
)

