local addonName, ACP = ...;
local version = 0.15
local actionCamEngaged = false
local focusEngaged = false
local castingMount = false
local activeMountID = 0
local ignoreCVarUpdate = false
local _

local ActionCamPlus_EventFrame = CreateFrame("Frame")
-- Init Events
ActionCamPlus_EventFrame:RegisterEvent("ADDON_LOADED")
ActionCamPlus_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ActionCamPlus_EventFrame:RegisterEvent("CVAR_UPDATE")

-- Mount Events
ActionCamPlus_EventFrame:RegisterEvent("UNIT_SPELLCAST_START")
ActionCamPlus_EventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
ActionCamPlus_EventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")

-- Focusing Events
ActionCamPlus_EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ActionCamPlus_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

ActionCamPlus_EventFrame:SetScript("OnEvent", function(self,event,...) self[event](self,event,...);end)

-- Create frame for tracking where we like to have our camera set
local ActionCamPlus_ZoomLevelUpdateFrame = CreateFrame("Frame")
ActionCamPlus_ZoomLevelUpdateFrame:SetScript("OnUpdate", function(self, elapsed) ACP.zoomLevelUpdate(self, elapsed) end)

local camMoving = false
local lastCamPosition = 0
local timeSinceLastUpdate = 0
function ACP.zoomLevelUpdate(self, elapsed) -- Save where we like our camera to be while walking or mounted
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	local camPosition = GetCameraZoom()
	if timeSinceLastUpdate > .5 then
		timeSinceLastUpdate = 0
		if camMoving then
			if camPosition == lastCamPosition and not castingMount then
				camMoving = false
				ignoreCVarUpdate = true
				SetCVar("cameraZoomSpeed", ActionCamPlusDB.defaultZoomSpeed)
				ignoreCVarUpdate = false
				if ActionCamPlusDB.addonEnabled then
					local zoomAmount = GetCameraZoom()
					if IsMounted() then 
						if ActionCamPlusDB.mountSpecificZoom then 
							ActionCamPlusDB.mountZooms[activeMountID] = zoomAmount
						end

						ActionCamPlusDB.mountedCamDistance = zoomAmount
					else
						ActionCamPlusDB.unmountedCamDistance = zoomAmount
					end
				end
			end
		elseif camPosition ~= lastCamPosition then
			camMoving = true
		end
		lastCamPosition = camPosition
	end
end

--init
function ActionCamPlus_EventFrame:ADDON_LOADED(self, addon)
	if addon == addonName then
		local defaults = {			-- Set defaults
			lastVersion = version,
			addonEnabled = true, 
			focusEnabled = false,
			mountedCamDistance = 30,
			unmountedCamDistance = 20,
			transitionSpeed = 12,
			defaultZoomSpeed = 50,
			mountSpecificZoom = false,
			mountZooms = {}
		}

		if not ActionCamPlusDB or not ActionCamPlusDB.lastVersion or ActionCamPlusDB.lastVersion ~= version then 
			ACP.UpdateDB(defaults)
		end

		UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
	end
end

function ACP.UpdateDB(defaults)
	for k,v in pairs(defaults) do
		if not ActionCamPlusDB[k] or ActionCamPlusDB[k] == nil then 
			ActionCamPlusDB[k] = v
		end
	end
	ActionCamPlusDB.lastVersion = version
end

function ActionCamPlus_EventFrame:PLAYER_ENTERING_WORLD()
	ActionCamPlusDB.defaultZoomSpeed = GetCVar("cameraZoomSpeed")
	if ActionCamPlusDB.addonEnabled then 
		ActionCamPlus_EventFrame:PLAYER_MOUNT_DISPLAY_CHANGED()
	else
		ACP.ActionCamOFF()
	end
end

function ActionCamPlus_EventFrame:CVAR_UPDATE(self, CVar, value)
	if CVar == "cameraZoomSpeed" and not ignoreCVarUpdate then
		ActionCamPlusDB.defaultZoomSpeed = value
	end
end

-- Mount Event Functions
function ActionCamPlus_EventFrame:UNIT_SPELLCAST_START(self, unit, counter, spellID)
	if unit == "player" and ACP.SpellIsMount(spellID) then
		activeMountID = spellID
		castingMount = true
		ACP.SetActionCam()
	end
end

function ActionCamPlus_EventFrame:UNIT_SPELLCAST_INTERRUPTED(self, unit)
	if unit == "player" and castingMount and not IsMounted() then 
		castingMount = false
		ACP.SetActionCam()
	end
end

function ActionCamPlus_EventFrame:PLAYER_MOUNT_DISPLAY_CHANGED()
	if castingMount then 
		castingMount = false
	end

	ACP.SetActionCam()
end


-- Focusing Event Functions
function ActionCamPlus_EventFrame:PLAYER_REGEN_DISABLED()
	ACP.SetActionCam()
end

function ActionCamPlus_EventFrame:PLAYER_REGEN_ENABLED()
	ACP.SetActionCam()
end

-- set up slash commands
SLASH_ACTIONCAMPLUS1 = "/actioncamplus"
SLASH_ACTIONCAMPLUS2 = "/acp"

function SlashCmdList.ACTIONCAMPLUS(msg)
	msg = string.lower(msg)
	arg1, arg2 = strsplit(" ", msg, 2)

	if arg1 == "" then
		if ActionCamPlusDB.addonEnabled then
			ActionCamPlusDB.addonEnabled = false
			print("ActionCamPlus disabled.")
		else
			ActionCamPlusDB.addonEnabled = true
			print("ActionCamPlus enabled.")
		end
		ACP.SetActionCam()

	elseif arg1 == "focus" or arg1 == "f" then
		if ActionCamPlusDB.focusEnabled then
			ActionCamPlusDB.focusEnabled = false
			print("Focusing disabled.")
		else
			ActionCamPlusDB.focusEnabled = true
			print("Focusing enabled.")
		end
		ACP.SetActionCam()

	elseif arg1 == "mountspecific" or arg1 == "ms" then 
		if ActionCamPlusDB.mountSpecificZoom then
			ActionCamPlusDB.mountSpecificZoom = false
			print("Mount-specific Zoom levels disabled.")
		else
			ActionCamPlusDB.mountSpecificZoom = true
			print("Mount-specific Zoom levels enabled.")
		end
		actionCamEngaged = true
		ACP.SetActionCam()

	elseif arg1 == "transitionspeed" or arg1 == "ts" then 
		ActionCamPlusDB.transitionSpeed = tonumber(arg2)

	elseif arg1 == "zoomspeed" or arg1 == "zs" then
		SetCVar("cameraZoomSpeed", tonumber(arg2))
		ActionCamPlusDB.defaultZoomSpeed = tonumber(arg2)

	elseif arg1 == "t" or arg1 == "test" then 
		--TEST CODE

		--END TEST CODE
	end
end

function ACP.ToggleCVar(CVar)
	if GetCVar(CVar) == "1" then
		SetCVar(CVar, 0)
	else
		SetCVar(CVar, 1)
	end
end

function ACP.ActionCamON()
	if not actionCamEngaged then
		SetCVar("test_cameraDynamicPitch", 1)
		SetCVar("test_cameraOverShoulder", 1)
		ACP.SetCameraZoom(ActionCamPlusDB.unmountedCamDistance)
		actionCamEngaged = true
	end
end

function ACP.ActionCamOFF()
	if actionCamEngaged then 
		SetCVar("test_cameraDynamicPitch", 0)
		SetCVar("test_cameraOverShoulder", 0)
		if ActionCamPlusDB.mountSpecificZoom and ActionCamPlusDB.mountZooms[activeMountID] then 
			ACP.SetCameraZoom(ActionCamPlusDB.mountZooms[activeMountID])
		else
			ACP.SetCameraZoom(ActionCamPlusDB.mountedCamDistance)
		end
		actionCamEngaged = false
	end
end

function ACP.SetFocusON()
	if not focusEngaged then 
		SetCVar("test_cameraTargetFocusEnemyEnable", 1)
		focusEngaged = true
	end
end

function ACP.SetFocusOFF()
	if focusEngaged then 
		SetCVar("test_cameraTargetFocusEnemyEnable", 0)
		focusEngaged = false
	end
end

function ACP.SetCameraZoom(destination)
	if ActionCamPlusDB.addonEnabled then
		ignoreCVarUpdate = true
		SetCVar("cameraZoomSpeed", ActionCamPlusDB.transitionSpeed)
		ignoreCVarUpdate = false
		if destination >= GetCameraZoom() then 
			MoveViewInStop()  -- this line stops the camera from doing whatever it might have been doing before...
			-- we have to delay for one in-game frame so that our wow's cam doesn't get confused
			C_Timer.After(.001, function() CameraZoomOut(destination - GetCameraZoom()) end) 
		else
			MoveViewInStop()
			C_Timer.After(.001, function() CameraZoomIn(GetCameraZoom() - destination) end)
		end
	end
end

function ACP.SetActionCam() -- This function basically decides everything
	if ActionCamPlusDB.addonEnabled then
		local mounted = IsMounted()
		local combat = UnitAffectingCombat("player")
		if castingMount then 
			ACP.ActionCamOFF()
			ACP.SetFocusOFF()

		elseif mounted then 
			ACP.ActionCamOFF()
			ACP.SetFocusOFF()

		elseif not castingMount and not mounted then
			ACP.ActionCamON()
			if combat and ActionCamPlusDB.focusEnabled then
				ACP.SetFocusON()
			else
				ACP.SetFocusOFF()
			end
		end
	else
		ACP.ActionCamOFF()
	end
end

-- Is spell id a mount?
function ACP.SpellIsMount(spellID)
	local mountIDs = C_MountJournal.GetMountIDs()
	for i = 1,#mountIDs do 
		_, mountSpellID = C_MountJournal.GetMountInfoByID(mountIDs[i])
		if spellID == mountSpellID then
			return true
		end
	end
	return false
end