--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
]]

local RUI = LibStub('AceAddon-3.0'):NewAddon('RetailUI', 'AceConsole-3.0')
local AceConfig = LibStub("AceConfig-3.0")
local AceDB = LibStub("AceDB-3.0")
RetailUIDB = RetailUIDB or {}
if RetailUIDB.bagsExpanded == nil then
    RetailUIDB.bagsExpanded = false -- Standard: sichtbar
end

RUI.InterfaceVersion = select(4, GetBuildInfo())
RUI.Wrath = (RUI.InterfaceVersion >= 30300)
RUI.DB = nil

function RUI:OnInitialize()
	RUI.DB = AceDB:New("RetailUIDB", RUI.default, true)
	AceConfig:RegisterOptionsTable("RUI Commands", RUI.optionsSlash, "rui")
end

function RUI:OnEnable()
    if GetCVar("useUiScale") == "0" then
        SetCVar("useUiScale", 1)
        SetCVar("uiScale", 0.75)
    end
end

function RUI:OnDisable() end

function CreateUIFrame(width, height, frameName)
	local frame = CreateFrame("Frame", 'RUI_' .. frameName, UIParent)
	frame:SetSize(width, height)

	frame:RegisterForDrag("LeftButton")
	frame:EnableMouse(false)
	frame:SetMovable(false)
	frame:SetScript("OnDragStart", function(self, button)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	-- Mouse wheel scaling support
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(self, delta)
		if not self:IsMouseEnabled() then return end -- Only work when in editor mode

		local currentScale = GetUIFrameScale(frameName) or 1
		local scaleStep = 0.1
		local newScale = currentScale + (delta * scaleStep)

		-- Clamp scale between 0.5 and 3.0
		newScale = math.max(0.5, math.min(3.0, newScale))

		-- Save and apply the new scale
		SaveUIFrameScale(newScale, frameName)

	end)	frame:SetFrameLevel(100)
	frame:SetFrameStrata('FULLSCREEN')

	do
		local texture = frame:CreateTexture(nil, 'BACKGROUND')
		texture:SetAllPoints(frame)
		texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI\\ActionBarHorizontal.blp")
		texture:SetTexCoord(0, 512 / 512, 14 / 2048, 85 / 2048)
		texture:Hide()

		frame.editorTexture = texture
	end

	do
		local fontString = frame:CreateFontString(nil, "BORDER", 'GameFontNormal')
		fontString:SetAllPoints(frame)
		fontString:SetText(frameName)
		fontString:Hide()

		frame.editorText = fontString
	end

	return frame
end

RUI.frames = {}

function ShowUIFrame(frame)
	frame:SetMovable(false)
	frame:EnableMouse(false)

	frame.editorTexture:Hide()
	frame.editorText:Hide()

	for _, target in pairs(RUI.frames[frame]) do
		target:SetAlpha(1)
	end

	RUI.frames[frame] = nil
end

function HideUIFrame(frame, exclude)
	frame:SetMovable(true)
	frame:EnableMouse(true)

	frame.editorTexture:Show()
	frame.editorText:Show()

	-- Update editor text to show current scale
	local frameName = frame:GetName():gsub("RUI_", "")
	local currentScale = GetUIFrameScale(frameName) or 1
	frame.editorText:SetText(frameName .. "\nScale: " .. string.format("%.1f", currentScale))

	RUI.frames[frame] = {}

	exclude = exclude or {}

	for _, target in pairs(exclude) do
		target:SetAlpha(0)
		tinsert(RUI.frames[frame], target)
	end
end

function SaveUIFramePosition(frame, widgetName)
	local _, _, relativePoint, posX, posY = frame:GetPoint('CENTER')
	RUI.DB.profile.widgets[widgetName].anchor = relativePoint
	RUI.DB.profile.widgets[widgetName].posX = posX
	RUI.DB.profile.widgets[widgetName].posY = posY
end

function SaveUIFrameScale(input, widgetName)
    local scale = tonumber(input) -- Convert input to a number
	if not scale or scale <= 0 then -- validate
		print("Invalid scale. Please provide a positive number.")
		return
	end

	-- Convert frame name to widget name if needed
	local configName = widgetName
	if widgetName:match("^ActionBar%d+$") then
		-- Convert "ActionBar1" to "actionBar1"
		local number = widgetName:match("ActionBar(%d+)")
		configName = "actionBar" .. number
	elseif widgetName == "PlayerFrame" then
		configName = "player"
	elseif widgetName == "TargetFrame" then
		configName = "target"
	elseif widgetName == "FocusFrame" then
		configName = "focus"
	elseif widgetName == "PetFrame" then
		configName = "pet"
	elseif widgetName == "TargetOfTargetFrame" then
		configName = "targetOfTarget"
	elseif widgetName:match("^Boss%d+Frame$") then
		local number = widgetName:match("Boss(%d+)Frame")
		configName = "boss" .. number
	elseif widgetName == "RepExpBar" then
		configName = "repExpBar"
	elseif widgetName == "MicroMenuBar" then
		configName = "microMenuBar"
	elseif widgetName == "BagsBar" then
		configName = "bagsBar"
	elseif widgetName == "PlayerCastingBar" or widgetName == "CastingBarFrame" then
		configName = "playerCastingBar"
	elseif widgetName == "Minimap" or widgetName == "MinimapFrame" then
		configName = "minimap"
	elseif widgetName == "QuestTracker" or widgetName == "QuestTrackerFrame" then
		configName = "questTracker"
	elseif widgetName == "BuffFrame" then
		configName = "buffs"
	end

	-- Ensure the widget entry exists before setting scale
	if not RUI.DB.profile.widgets[configName] then
		RUI.DB.profile.widgets[configName] = {}
	end

	RUI.DB.profile.widgets[configName].scale = scale -- save the scale

    -- Update the specific frame based on widget type
    if configName == "player" then
        PlayerFrame:SetScale(scale)
    elseif configName == "target" then
        TargetFrame:SetScale(scale)
    elseif configName == "focus" then
        FocusFrame:SetScale(scale)
    elseif configName == "pet" then
        PetFrame:SetScale(scale)
    elseif configName == "targetOfTarget" then
        TargetFrameToT:SetScale(scale)
    elseif string.find(configName, "boss") then
        local bossIndex = tonumber(string.match(configName, "boss(%d+)"))
        if bossIndex then
            -- Scale all boss frames, not just the specific one
            for i = 1, 4 do
                local bossFrame = _G['Boss' .. i .. 'TargetFrame']
                if bossFrame then
                    bossFrame:SetScale(scale)
                end
            end

            -- Reposition boss frames 2, 3, 4 based on scale to maintain proper spacing
            for i = 2, 4 do
                local bossFrame = _G['Boss' .. i .. 'TargetFrame']
                local prevBossFrame = _G['Boss' .. (i-1) .. 'TargetFrame']
                if bossFrame and prevBossFrame then
                    -- Calculate spacing based on scale: base height (30) * scale + padding
                    local baseHeight = 30
                    local padding = 2
                    local spacing = (baseHeight * scale) + padding
                    bossFrame:ClearAllPoints()
                    bossFrame:SetPoint("TOP", prevBossFrame, "BOTTOM", 0, -spacing)
                end
            end
        end
    elseif string.find(configName, "actionBar") or configName == "microMenuBar" or configName == "bagsBar" or configName == "repExpBar" then
        -- For ActionBar elements, get the ActionBar module and update
        local ActionBarModule = RUI:GetModule("ActionBar")
        if ActionBarModule and ActionBarModule.UpdateWidgets then
            ActionBarModule:UpdateWidgets()
        end
    elseif configName == "playerCastingBar" then
        local CastingBarModule = RUI:GetModule("CastingBar")
        if CastingBarModule and CastingBarModule.UpdateWidgets then
            CastingBarModule:UpdateWidgets()
        end
    elseif configName == "minimap" then
        local MinimapModule = RUI:GetModule("Minimap")
        if MinimapModule and MinimapModule.UpdateWidgets then
            MinimapModule:UpdateWidgets()
        end
    elseif configName == "questTracker" then
        local QuestTrackerModule = RUI:GetModule("QuestTracker")
        if QuestTrackerModule and QuestTrackerModule.UpdateWidgets then
            QuestTrackerModule:UpdateWidgets()
        end
    elseif configName == "buffs" then
        local BuffFrameModule = RUI:GetModule("BuffFrame")
        if BuffFrameModule and BuffFrameModule.UpdateWidgets then
            BuffFrameModule:UpdateWidgets()
        end
    end

end

function GetUIFrameScale(widgetName)
	-- Convert frame name to widget name if needed
	local configName = widgetName
	if widgetName:match("^ActionBar%d+$") then
		-- Convert "ActionBar1" to "actionBar1"
		local number = widgetName:match("ActionBar(%d+)")
		configName = "actionBar" .. number
	elseif widgetName == "PlayerFrame" then
		configName = "player"
	elseif widgetName == "TargetFrame" then
		configName = "target"
	elseif widgetName == "FocusFrame" then
		configName = "focus"
	elseif widgetName == "PetFrame" then
		configName = "pet"
	elseif widgetName == "TargetOfTargetFrame" then
		configName = "targetOfTarget"
	elseif widgetName:match("^Boss%d+Frame$") then
		local number = widgetName:match("Boss(%d+)Frame")
		configName = "boss" .. number
	elseif widgetName == "RepExpBar" then
		configName = "repExpBar"
	elseif widgetName == "MicroMenuBar" then
		configName = "microMenuBar"
	elseif widgetName == "BagsBar" then
		configName = "bagsBar"
	elseif widgetName == "PlayerCastingBar" or widgetName == "CastingBarFrame" then
		configName = "playerCastingBar"
	elseif widgetName == "Minimap" or widgetName == "MinimapFrame" then
		configName = "minimap"
	elseif widgetName == "QuestTracker" or widgetName == "QuestTrackerFrame" then
		configName = "questTracker"
	elseif widgetName == "BuffFrame" then
		configName = "buffs"
	end

	if not RUI.DB.profile.widgets[configName] then
		return 1 -- Default scale if widget doesn't exist
	end
	return RUI.DB.profile.widgets[configName].scale or 1 -- Default to 1 if scale is nil
end

function CheckSettingsExists(self, widgets)
	for _, widget in pairs(widgets) do
		if RUI.DB.profile.widgets[widget] == nil then
			self:LoadDefaultSettings()
			break
		end
	end
	self:UpdateWidgets()
end

local function MoveChatOnFirstLoad()
    local chat = ChatFrame1
    if not chat then return end

    if chat:IsUserPlaced() then return end

    chat:ClearAllPoints()
    chat:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 32, 32)
    chat:SetWidth(chat:GetWidth() - 40)
    chat:SetMovable(true)
    chat:SetUserPlaced(true)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    MoveChatOnFirstLoad()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
