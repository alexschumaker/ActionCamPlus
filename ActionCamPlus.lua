local addonName, ACP = ...;
local actionCamEngaged = false
local castingMount = false
local defaultZoomSpeed = 50
local _

local ActionCamPlus_EventFrame = CreateFrame("Frame")
ActionCamPlus_EventFrame:RegisterEvent("ADDON_LOADED")
ActionCamPlus_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Mount Events
ActionCamPlus_EventFrame:RegisterEvent("UNIT_SPELLCAST_START")
ActionCamPlus_EventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
ActionCamPlus_EventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")

ActionCamPlus_EventFrame:SetScript("OnEvent", function(self,event,...) self[event](self,event,...);end)

-- Create frame for tracking where we like to have our camera set
local ActionCamPlus_ZoomLevelUpdateFrame = CreateFrame("Frame")
ActionCamPlus_ZoomLevelUpdateFrame:SetScript("OnUpdate", function(self, elapsed) ACP.zoomLevelUpdate(self, elapsed) end)

local camMoving = false
local lastCamPosition = 0
local timeSinceLastUpdate = 0
function ACP.zoomLevelUpdate(self, elapsed)
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	local camPosition = GetCameraZoom()
	if timeSinceLastUpdate > .5 then
		timeSinceLastUpdate = 0
		if camMoving then
			if camPosition == lastCamPosition and not castingMount then
				camMoving = false
				SetCVar("cameraZoomSpeed", defaultZoomSpeed)
				if IsMounted() then 
					ActionCamPlusDB.mountedCamDistance = GetCameraZoom()
				else
					ActionCamPlusDB.unmountedCamDistance = GetCameraZoom()
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
		if not ActionCamPlusDB then -- Set defaults
			ActionCamPlusDB = {
				addonEnabled = true, 
				mountedCamDistance = 15,
				unmountedCamDistance = 15,
				transitionSpeed = 15
			}
		end

		if ActionCamPlusDB.addonEnabled then 
			UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
		end
	end
end

function ActionCamPlus_EventFrame:PLAYER_ENTERING_WORLD()
	defaultZoomSpeed = GetCVar("cameraZoomSpeed")
	if ActionCamPlusDB.addonEnabled then 
		ActionCamPlus_EventFrame:PLAYER_MOUNT_DISPLAY_CHANGED()
	else
		ACP.ActionCamOFF()
	end
end

-- Mount Event Functions
function ActionCamPlus_EventFrame:UNIT_SPELLCAST_START(self, unit, counter, spellID)
	if unit == "player" and ACP.SpellIsMount(spellID) then
		castingMount = true
		ACP.ActionCamOFF()
	end
end

function ActionCamPlus_EventFrame:UNIT_SPELLCAST_INTERRUPTED(self, unit)
	if unit == "player" and castingMount and not IsMounted() then 
		ACP.ActionCamON()
		castingMount = false
	end
end

function ActionCamPlus_EventFrame:PLAYER_MOUNT_DISPLAY_CHANGED()
	if castingMount then 
		castingMount = false
	end

	if IsMounted() then 
		ACP.ActionCamOFF()
	else
		ACP.ActionCamON()
	end
end

-- set up slash commands
SLASH_ACTIONCAMPLUS1 = "/actioncamplus"
SLASH_ACTIONCAMPLUS2 = "/acp"

function SlashCmdList.ACTIONCAMPLUS(msg)
	msg = string.lower(msg)
	if msg == "" then
		if ActionCamPlusDB.addonEnabled then
			ActionCamPlusDB.addonEnabled = false
		else
			ActionCamPlusDB.addonEnabled = true
		end
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
	if not actionCamEngaged and ActionCamPlusDB.addonEnabled then
		SetCVar("test_cameraDynamicPitch", 1)
		SetCVar("test_cameraOverShoulder", 1)
		-- if not camMoving then ActionCamPlusDB.mountedCamDistance = GetCameraZoom() end
		ACP.SetCameraZoom(ActionCamPlusDB.unmountedCamDistance)
		actionCamEngaged = true
	end
end

function ACP.ActionCamOFF()
	if actionCamEngaged then 
		SetCVar("test_cameraDynamicPitch", 0)
		SetCVar("test_cameraOverShoulder", 0)
		-- if not cameraMoving then ActionCamPlusDB.unmountedCamDistance = GetCameraZoom() end
		ACP.SetCameraZoom(ActionCamPlusDB.mountedCamDistance)
		actionCamEngaged = false
	end
end

function ACP.SetCameraZoom(destination)
	SetCVar("cameraZoomSpeed", ActionCamPlusDB.transitionSpeed)
	if destination >= GetCameraZoom() then 
		CameraZoomOut(destination - GetCameraZoom())
	else
		CameraZoomIn(GetCameraZoom() - destination)
	end
	--SetCVar("cameraZoomSpeed", speed)
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