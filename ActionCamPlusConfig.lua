local addonName, ACP = ...;
local options = {}
local _
--NOTE: The options in ActionCamPlusDB, the checkbox frames, and the functions in ActionCamPlusConfig_SettingUpdate are reduntantly named to make the code more compact.

-- Positional Variables
local top = -30
local leftMargin = 15
local listIndent = 34
local listItemHeight = -20
local listVertPad = 6
local sectionVertPad = 0

-- Draw all the option elements when the options frame loads
function ActionCamPlusConfig_Setup()
	-- OLD DEFAULTS KEEP UNTIL SAFELY DEAD
	-- local defaults = {			
	-- 	lastVersion = version,
	-- 	addonEnabled = true, 
	-- 	focusEnabled = false,
	-- 	mountedCamDistance = 30,
	-- 	unmountedCamDistance = 20,
	-- 	transitionSpeed = 12,
	-- 	defaultZoomSpeed = 50,
	-- 	mountSpecificZoom = false,
	-- 	druidFormMounts = true,
	-- 	mountZooms = {}
	-- }

	local defaults = {			-- Set defaults
		lastVersion = ACP.version,

		ACP_AddonEnabled = true,
		ACP_ActionCam = true,
		ACP_Focusing = false,
		ACP_Pitch = true,
		ACP_SetCameraZoom = true,
		unmountedCamDistance = 20,

		ACP_Mounted = true,
		ACP_MountedActionCam = false,
		ACP_MountedFocusing = false,
		ACP_MountedPitch = false,
		ACP_DruidFormMounts = true,
		ACP_MountedSetCameraZoom = true,
		ACP_MountSpecificZoom = false,
		mountedCamDistance = 30,

		ACP_Combat = false,
		ACP_CombatActionCam = true,
		ACP_CombatFocusing = true,
		ACP_CombatPitch = true,
		ACP_CombatSetCameraZoom = false,
		combatCamDistance = 20,
		
		transitionSpeed = 12,
		defaultZoomSpeed = 50,
		
		mountZooms = {}
	}
	
	if not ActionCamPlusDB then
		ActionCamPlusDB = defaults

	elseif not ActionCamPlusDB.lastVersion or ActionCamPlusDB.lastVersion ~= ACP.version then 
		ACP.UpdateDB(defaults)
	end

	-- For reference:  ACP.createCheckButton(name, parent, anchor, offX, offY, label, tooltip, framepoint="TOPLEFT", anchorpoint="BOTTOMLEFT")

	-- Addon Enabled
	options.ACP_AddonEnabled = ACP.createCheckButton("AddonEnabled", ActionCamPlusOptionsFrame, ActionCamPlusOptionsFrame, leftMargin, top,
						"Addon Enabled",
						"Toggles ActionCamPlus functionality.",
						"TOPLEFT", "TOPLEFT")
	-- On Foot Options
				-- Action Cam
				options.ACP_ActionCam = ACP.createCheckButton("ActionCam", ACP_AddonEnabled, ACP_AddonEnabled, listIndent, 5,
									"Action Cam",
									"Enable Action Cam while on foot.")

				-- Focusing
				options.ACP_Focusing = ACP.createCheckButton("Focusing", ACP_AddonEnabled, ACP_ActionCam, 0,  listVertPad,
									"Focusing",
									"Target Focusing enabled while on foot.")

				-- Pitch
				options.ACP_Pitch = ACP.createCheckButton("Pitch", ACP_AddonEnabled, ACP_Focusing, 0,  listVertPad,
									"Pitch",
									"Camera pitch enabled while on foot.")

				-- Set Camera Zoom
				options.ACP_SetCameraZoom = ACP.createCheckButton("SetCameraZoom", ACP_AddonEnabled, ACP_Pitch, 0,  listVertPad,
									"Set Camera Zoom",
									"ActionCamPlus will reset your camera zoom distance to where it was before you mounted or entered combat.")

	-- Mounted Header
	options.ACP_Mounted = ACP.createCheckButton("Mounted", ACP_AddonEnabled, ACP_SetCameraZoom, -listIndent,  sectionVertPad,
						"Mounted",
						"Enables ActionCamPlus behavior while mounted.")
	-- Mounted Options
				-- Action Cam
				options.ACP_MountedActionCam = ACP.createCheckButton("MountedActionCam", ACP_Mounted, ACP_Mounted, listIndent,  5,
									"Action Cam",
									"Enable Action Cam while mounted.")

				-- Focusing
				options.ACP_MountedFocusing = ACP.createCheckButton("MountedFocusing", ACP_Mounted, ACP_MountedActionCam, 0,  listVertPad,
									"Focusing",
									"Target Focusing enabled while mounted.")

				-- Pitch
				options.ACP_MountedPitch = ACP.createCheckButton("MountedPitch", ACP_Mounted, ACP_MountedFocusing, 0,  listVertPad,
									"Pitch",
									"Camera pitch enabled while mounted.")

				-- Druid Form Mounts
				options.ACP_DruidFormMounts = ACP.createCheckButton("DruidFormMounts", ACP_Mounted, ACP_MountedPitch, 0,  listVertPad,
									"Druid Form Mounts",
									"Druids' travel forms will be treated as mounts.")

				-- Set Camera Zoom
				options.ACP_MountedSetCameraZoom = ACP.createCheckButton("MountedSetCameraZoom", ACP_Mounted, ACP_DruidFormMounts, 0,  listVertPad,
									"Set Camera Zoom",
									"When you mount, ActionCamPlus will set the camera distance to what it was last time you were mounted.")

				-- Mount Specific Zoom
				options.ACP_MountSpecificZoom = ACP.createCheckButton("MountSpecificZoom", ACP_MountedSetCameraZoom, ACP_MountedSetCameraZoom, 0,  listVertPad,
									"Mount-Specific Zoom",
									"ActionCamPlus will remember a zoom level for each mount.")

	-- Combat Header
	options.ACP_Combat = ACP.createCheckButton("Combat", ACP_AddonEnabled, ACP_MountSpecificZoom, -listIndent, sectionVertPad,
						"Combat",
						"Enables ActionCamPlus behavior while in combat.")
	-- Combat Options
				-- Action Cam
				options.ACP_CombatActionCam = ACP.createCheckButton("CombatActionCam", ACP_Combat, ACP_Combat, listIndent,  5,
									"Action Cam",
									"Enable Action Cam while in combat.")

				-- Focusing
				options.ACP_CombatFocusing = ACP.createCheckButton("CombatFocusing", ACP_Combat, ACP_CombatActionCam, 0,  listVertPad,
									"Focusing",
									"Target Focusing enabled while in combat.")

				-- Pitch
				options.ACP_CombatPitch = ACP.createCheckButton("CombatPitch", ACP_Combat, ACP_CombatFocusing, 0,  listVertPad,
									"Pitch",
									"Camera pitch enabled while in combat.")

				-- Set Camera Zoom
				options.ACP_CombatSetCameraZoom = ACP.createCheckButton("CombatSetCameraZoom", ACP_Combat, ACP_CombatPitch, 0,  listVertPad,
									"Set Camera Zoom",
									"When you enter combat, ActionCamPlus will set the camera distance to what it was last time you were in combat.")

end

function ACP.UpdateDB(defaults)
	for k,v in pairs(defaults) do
		-- print(k, ActionCamPlusDB[k], v)
		if not ActionCamPlusDB[k] then 
			ActionCamPlusDB[k] = v
		end
	end
	ActionCamPlusDB.lastVersion = ACP.version
end

function ACP.UpdateDependencies(option)
	local children = {option:GetChildren()}

	if #children > 0 then
		for _,child in pairs(children) do
			if not option:GetChecked() or option:IsSoftDisabled() then
				child:SoftDisable()
			else
				child:SoftEnable()
			end

			ACP.UpdateDependencies(child)
		end
	end
end

-- Function to change a setting
function ACP.SettingUpdate(setting, settingtype)
	if settingtype == "checkbutton" then 
		if setting:GetChecked() then
			ActionCamPlusDB[setting:GetName()] = true
		else
			ActionCamPlusDB[setting:GetName()] = false
		end
	end
end

-- Option UI element creation functions
function ACP.createCheckButton(name, parent, anchor, offX, offY, label, tooltip, framepoint, anchorpoint)
	framepoint = framepoint or "TOPLEFT"
	anchorpoint = anchorpoint or "BOTTOMLEFT"

	local checkButton = CreateFrame("CheckButton", "ACP_"..name, parent, "OptionsCheckButtonTemplate")
	checkButton:SetPoint(framepoint, anchor, anchorpoint, offX, offY)
	checkButton:SetScript("OnClick", ActionCamPlusConfig_OnClick)
	checkButton:SetScript("OnShow", ActionCamPlusConfig_OnShow)

	checkButton:GetCheckedTexture():Show()
	checkButton:GetCheckedTexture():Hide()
	checkButton:SetChecked(true)
	checkButton.SoftDisableCheckedTexture = checkButton:CreateTexture("SoftDisableCheckedTexture", "OVERLAY", 7)
	checkButton.SoftDisableCheckedTexture:SetTexture(checkButton:GetDisabledCheckedTexture():GetTexture())
	checkButton.SoftDisableCheckedTexture:SetAllPoints(checkButton)
	checkButton.SoftDisableCheckedTexture:Hide()

	checkButton.SoftDisable = function() ACP.SoftToggle(checkButton) end
	checkButton.SoftEnable = function() ACP.SoftToggle(checkButton, true) end
	checkButton.SoftDisabled = false
	checkButton.IsSoftDisabled = function() return checkButton.SoftDisabled end

	getglobal(checkButton:GetName() .. 'Text'):SetText(label)
	ACP.setOptionTooltip(checkButton, tooltip)

	return checkButton
end

function ActionCamPlusConfig_OnClick(self, mousebutton, down) 
	ACP.SettingUpdate(self, "checkbutton")

	if self:GetChecked() and self:IsSoftDisabled() then
		self.SoftDisableCheckedTexture:Show()
	else
		self.SoftDisableCheckedTexture:Hide()
	end

	ACP.SetActionCam()
	ACP.UpdateDependencies(self)
end

-- Make Sure all the settings are set when we open config
function ActionCamPlusConfig_OnShow(self)
	self:SetChecked(ActionCamPlusDB[self:GetName()])
	ACP.UpdateDependencies(self)
end

function ACP.SoftToggle(button, enable)
	text = getglobal(button:GetName().."Text")
	if enable then
		button.SoftDisableCheckedTexture:Hide()
		text:SetFontObject("GameFontNormal")
		button.SoftDisabled = false
	else
		if button:GetChecked() then
			button.SoftDisableCheckedTexture:Show()
		end
		text:SetFontObject("GameFontDisable")
		button.SoftDisabled = true
	end
end

function ACP.setOptionTooltip(option, text)
	option:SetScript("OnEnter", function() 
		GameTooltip:SetOwner(option, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(text, nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)

	option:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:ClearLines()
	end)
end

-- hides the tooltip when we're done
function ActionCamPlusConfig_HideTooltip()
	GameTooltip:Hide()
	GameTooltip:ClearLines()
end