local addonName, ACP = ...;
ACP.version = 0.20

local actionCamEngaged = false
local focusEngaged = false
local castingMount = false
local activeMountID = 0
local ignoreCVarUpdate = false
local druidMount = false
BINDING_HEADER_ACTIONCAMPLUS = "ActionCamPlus" 
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
if select(2, UnitClass("player")) == "DRUID" then
	ActionCamPlus_EventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM") -- for Druid forms
end

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
function ACP.zoomLevelUpdate(self, elapsed) -- Save where we like our camera to be while walking, mounted, or in combat
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	local camPosition = GetCameraZoom()
	if timeSinceLastUpdate > .25 then
		timeSinceLastUpdate = 0
		if camMoving then
			if camPosition == lastCamPosition and not castingMount then
				camMoving = false

				ignoreCVarUpdate = true
				SetCVar("cameraZoomSpeed", ActionCamPlusDB.defaultZoomSpeed)
				ignoreCVarUpdate = false

				if ActionCamPlusDB.ACP_AddonEnabled then
					local zoomAmount = GetCameraZoom()
					if IsMounted() or druidMount then 
						if ActionCamPlusDB.ACP_MountSpecificZoom then 
							ActionCamPlusDB.mountZooms[activeMountID] = zoomAmount
						end

						ActionCamPlusDB.mountedCamDistance = zoomAmount

					elseif UnitAffectingCombat("player") then
						ActionCamPlusDB.combatCamDistance = zoomAmount

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
		
		ActionCamPlusConfig_Setup()
		UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
	end
end

function ActionCamPlus_EventFrame:PLAYER_ENTERING_WORLD()
	ACP.SetActionCam()
	ActionCamPlusDB.defaultZoomSpeed = GetCVar("cameraZoomSpeed")
	if ActionCamPlusDB.ACP_AddonEnabled then 
		ActionCamPlus_EventFrame:PLAYER_MOUNT_DISPLAY_CHANGED()
		ActionCamPlus_EventFrame:UPDATE_SHAPESHIFT_FORM()
	else
		ACP.ActionCamOFF()
	end
	print("ActionCamPlus Loaded. /acp config")
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


function ActionCamPlus_EventFrame:UPDATE_SHAPESHIFT_FORM() -- druid form check
	local currentForm = GetShapeshiftFormID()
	local mountForms = {4, 29, 27, 3}
	if ActionCamPlusDB.druidFormMounts and currentForm and tContains(mountForms, currentForm) then
		druidMount = true
		activeMountID = currentForm
	else
		druidMount = false
	end
	ACP.SetActionCam()
end

-- Combat Event Functions
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
		if ActionCamPlusDB.ACP_AddonEnabled then
			ActionCamPlusDB.ACP_AddonEnabled = false
			print("ActionCamPlus disabled.")
		else
			ActionCamPlusDB.ACP_AddonEnabled = true
			print("ActionCamPlus enabled.")
		end
		ACP.SetActionCam(ActionCamPlusDB.ACP_AddonEnabled)

	elseif arg1 == "h" or arg1 == "config" then 
		if ActionCamPlusOptionsFrame:IsShown() then 
			ActionCamPlusOptionsFrame:Hide()
		else
			ActionCamPlusOptionsFrame:Show()
		end

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
		-- actionCamEngaged = true
		ACP.SetActionCam()

	elseif arg1 == "druidmount" or arg1 == "dm" then 
		if ActionCamPlusDB.druidFormMounts then
			ActionCamPlusDB.druidFormMounts = false
			print("Druid Forms no longer treated as mounts.")
		else
			ActionCamPlusDB.druidFormMounts = true
			print("Druid Forms are now treated as mounts.")
		end
		ACP.SetActionCam()

	elseif arg1 == "transitionspeed" or arg1 == "ts" then 
		ActionCamPlusDB.transitionSpeed = tonumber(arg2)

	elseif arg1 == "zoomspeed" or arg1 == "zs" then
		SetCVar("cameraZoomSpeed", tonumber(arg2))
		ActionCamPlusDB.defaultZoomSpeed = tonumber(arg2)

	elseif arg1 == "t" or arg1 == "test" then 
		--TEST CODE
		-- SetCVar("test_cameraDynamicPitchSmartPivotCutoffDist", arg2)
		print(ActionCamPlusDB.transitionSpeed)
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

function ACP.SetActionCam() -- This function basically decides everything
	if ActionCamPlusDB.ACP_AddonEnabled then
		local mounted = IsMounted() or castingMount or druidMount
		local combat = UnitAffectingCombat("player")
		if mounted and ActionCamPlusDB.ACP_Mounted then 
			ACP.ActionCam(ActionCamPlusDB.ACP_MountedActionCam)
			ACP.SetFocus(ActionCamPlusDB.ACP_MountedFocusing)

			if ActionCamPlusDB.ACP_MountSpecificZoom then
				ACP.SetCameraZoom(ActionCamPlusDB.ACP_MountedSetCameraZoom, ActionCamPlusDB.mountZooms[activeMountID])
			else
				ACP.SetCameraZoom(ActionCamPlusDB.ACP_MountedSetCameraZoom, ActionCamPlusDB.mountedCamDistance)
			end

		elseif combat and ActionCamPlusDB.ACP_Combat then
			ACP.ActionCam(ActionCamPlusDB.ACP_CombatActionCam)
			ACP.SetFocus(ActionCamPlusDB.ACP_CombatFocusing)
			ACP.SetCameraZoom(ActionCamPlusDB.ACP_CombatSetCameraZoom, ActionCamPlusDB.combatCamDistance)

		else
			ACP.ActionCam(ActionCamPlusDB.ACP_ActionCam)
			ACP.SetFocus(ActionCamPlusDB.ACP_Focusing)
			ACP.SetCameraZoom(ActionCamPlusDB.ACP_SetCameraZoom, ActionCamPlusDB.unmountedCamDistance)
		end
	else
		ACP.ActionCam(false)
		ACP.SetFocus(false)
	end
end

function ACP.ActionCam(enable)
	if enable then
		SetCVar("test_cameraDynamicPitch", 1)
		SetCVar("test_cameraOverShoulder", 1)
		actionCamEngaged = true

	else
		SetCVar("test_cameraDynamicPitch", 0)
		SetCVar("test_cameraOverShoulder", 0)
		actionCamEngaged = false
	end
end

function ACP.SetFocus(enable)
	if enable then 
		SetCVar("test_cameraTargetFocusEnemyEnable", 1)
		focusEngaged = true

	else
		SetCVar("test_cameraTargetFocusEnemyEnable", 0)
		focusEngaged = false
	end
end

function ACP.SetCameraZoom(enabled, destination)
	if enabled then
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

-- function ACP.IsMounted():
-- 	if ActionCamPlusDB.druidFormMounts then
-- 		if IsMounted() or druidMounted then 
-- 			return true
-- 		end
-- 	else
-- 		return IsMounted()
-- 	end 
-- end
