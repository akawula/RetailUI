--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'EditorMode'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local UnitFrameModule, CastingBarModule, ActionBarModule, MinimapModule, QuestTrackerModule, BuffFrameModule

Module.editorGridFrame = nil
Module.hudEditModeFrame = nil
Module.editModeSettings = {
    layout = "Modern",
    grid = true,
    snap = true,
    gridSpacing = 20,
    targetAndFocus = true,
    castBar = true,
    partyFrames = true,
    raidFrames = true,
    stanceBar = false,
    petBar = false,
    buffFrame = false,
    debuffFrame = false,
    bossFrames = false,
    hudTooltip = false,
    encounterBar = false,
    extraAbilities = false,
    possessBar = false,
    talkingHead = false,
    vehicleExitButton = false,
    arenaFrames = false,
    lootWindow = false
}

local function CreateEditorGridFrame()
    local editorGridFrame = CreateFrame("Frame", 'RUI_EditorGridFrame', UIParent)
    editorGridFrame:SetPoint("TOPLEFT", 0, 0)
    editorGridFrame:SetSize(GetScreenWidth(), GetScreenHeight())
    editorGridFrame:SetFrameLevel(0)
    editorGridFrame:SetFrameStrata("BACKGROUND")

    do
        local texture = editorGridFrame:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(editorGridFrame)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI\\EditorGrid.blp", "REPEAT", "REPEAT")
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertTile(true)
        texture:SetHorizTile(true)
        texture:SetSize(Module.editModeSettings.gridSpacing, Module.editModeSettings.gridSpacing)
        texture:SetAlpha(0.4)
        editorGridFrame.texture = texture
    end

    editorGridFrame:Hide()
    return editorGridFrame
end

local function CreateHUDEditModeFrame()
    local frame = CreateFrame("Frame", "RUI_HUDEditModeFrame", UIParent)
    frame:SetSize(320, 100)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Module:SaveWindowPosition()
    end)

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(1, 1, 1, 1)
    frame.bg:SetVertexColor(0.1, 0.1, 0.1, 0.9)

    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    frame.border:SetTexture(1, 1, 1, 1)
    frame.border:SetVertexColor(0.8, 0.6, 0.2, 1)

    frame.innerBorder = frame:CreateTexture(nil, "BORDER", nil, 1)
    frame.innerBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    frame.innerBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    frame.innerBorder:SetTexture(1, 1, 1, 1)
    frame.innerBorder:SetVertexColor(0.3, 0.2, 0.1, 1)

    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetSize(320, 30)
    frame.titleBar:SetPoint("TOP", frame, "TOP", 0, 0)

    frame.titleBar.bg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBar.bg:SetAllPoints()
    frame.titleBar.bg:SetTexture(1, 1, 1, 1)
    frame.titleBar.bg:SetVertexColor(0.2, 0.15, 0.1, 1)

    frame.infoIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.infoIcon:SetSize(20, 20)
    frame.infoIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -5)
    frame.infoIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
    frame.title:SetText("HUD Edit Mode")
    frame.title:SetTextColor(1, 0.82, 0, 1)

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.closeButton:SetSize(20, 20)
    frame.closeButton:SetScript("OnClick", function()
        Module:Hide()
    end)

    frame.messageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.messageText:SetPoint("CENTER", frame, "CENTER", 0, -10)
    frame.messageText:SetText("Edit mode is now active")
    frame.messageText:SetTextColor(1, 0.82, 0, 1)

    frame:Hide()
    return frame
end

function Module:OnEnable()
    UnitFrameModule = RUI:GetModule("UnitFrame")
    CastingBarModule = RUI:GetModule("CastingBar")
    ActionBarModule = RUI:GetModule("ActionBar")
    MinimapModule = RUI:GetModule("Minimap")
    QuestTrackerModule = RUI:GetModule("QuestTracker")
    BuffFrameModule = RUI:GetModule("BuffFrame")

    self.editorGridFrame = CreateEditorGridFrame()
    self.hudEditModeFrame = CreateHUDEditModeFrame()
    self:LoadSettings()
end

function Module:OnDisable() end

function Module:LoadSettings()
    if RUI.DB and RUI.DB.profile and RUI.DB.profile.editModeSettings then
        for k, v in pairs(RUI.DB.profile.editModeSettings) do
            self.editModeSettings[k] = v
        end
    end

    if RUI.DB and RUI.DB.profile and RUI.DB.profile.hudEditModePosition then
        local pos = RUI.DB.profile.hudEditModePosition
        if pos.point and pos.x and pos.y then
            self.hudEditModeFrame:ClearAllPoints()
            self.hudEditModeFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
        end
    end
end

function Module:SaveSettings()
    if not RUI.DB then return end
    if not RUI.DB.profile then RUI.DB.profile = {} end
    RUI.DB.profile.editModeSettings = {}

    for k, v in pairs(self.editModeSettings) do
        RUI.DB.profile.editModeSettings[k] = v
    end

    self:SaveWindowPosition()
end

function Module:SaveWindowPosition()
    if not RUI.DB then return end
    if not RUI.DB.profile then RUI.DB.profile = {} end
    if not self.hudEditModeFrame then return end

    local point, _, _, x, y = self.hudEditModeFrame:GetPoint()
    RUI.DB.profile.hudEditModePosition = {
        point = point or "CENTER",
        x = x or 0,
        y = y or 0
    }
end

function Module:RevertAllChanges()
    self.editModeSettings = {
        layout = "Modern",
        grid = true,
        snap = true,
        gridSpacing = 20,
        targetAndFocus = true,
        castBar = true,
        partyFrames = true,
        raidFrames = true,
        stanceBar = false,
        petBar = false,
        buffFrame = false,
        debuffFrame = false,
        bossFrames = false,
        hudTooltip = false,
        encounterBar = false,
        extraAbilities = false,
        possessBar = false,
        talkingHead = false,
        vehicleExitButton = false,
        arenaFrames = false,
        lootWindow = false
    }

    self:UpdateHUDEditModeFrame()
    self:UpdateUIElements()
end

function Module:UpdateHUDEditModeFrame()
    if not self.hudEditModeFrame then return end
end

function Module:UpdateUIElements()
    if self.editModeSettings.grid and self.editorGridFrame:IsShown() then
        self.editorGridFrame:Show()
    else
        self.editorGridFrame:Hide()
    end
end

function Module:UpdateGridSpacing()
    if self.editorGridFrame and self.editorGridFrame.texture then
        self.editorGridFrame.texture:SetSize(self.editModeSettings.gridSpacing, self.editModeSettings.gridSpacing)
    end
end

function Module:Show()
    if InCombatLockdown() then
        self:Printf(DEFAULT_CHAT_FRAME, "Cannot open settings while in combat")
        return
    end

    self.editorGridFrame:Show()
    self.hudEditModeFrame:Show()
    self:UpdateHUDEditModeFrame()

    ActionBarModule:ShowEditorTest()
    UnitFrameModule:ShowEditorTest()
    CastingBarModule:ShowEditorTest()
    MinimapModule:ShowEditorTest()
    QuestTrackerModule:ShowEditorTest()
    BuffFrameModule:ShowEditorTest()
end

function Module:Hide()
    self.editorGridFrame:Hide()
    self.hudEditModeFrame:Hide()

    ActionBarModule:HideEditorTest(true)
    UnitFrameModule:HideEditorTest(true)
    CastingBarModule:HideEditorTest(true)
    MinimapModule:HideEditorTest(true)
    QuestTrackerModule:HideEditorTest(true)
    BuffFrameModule:HideEditorTest(true)
end

function Module:IsShown()
    return self.hudEditModeFrame:IsShown()
end
