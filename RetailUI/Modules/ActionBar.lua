local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'ActionBar'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

Module.actionBars = {}
Module.repExpBar = nil
Module.bagsBar = nil
Module.microMenuBar = nil

local function CreateNineSliceFrame(width, height)
    local nineSliceFrame = CreateFrame("Frame", nil, UIParent)
    nineSliceFrame:SetSize(width, height)

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("TOPLEFT", 10, 7)
        texture:SetPoint("TOPRIGHT", -10, 7)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(0, 32 / 512, 145 / 2048, 177 / 2048)
        texture:SetHorizTile(true)
        texture:SetSize(width, 20)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("BOTTOMLEFT", 10, -7)
        texture:SetPoint("BOTTOMRIGHT", -10, -7)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(0, 32 / 512, 97 / 2048, 143 / 2048)
        texture:SetHorizTile(true)
        texture:SetSize(width, 20)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("TOPLEFT", -7, 7)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(463 / 512, 497 / 512, 475 / 2048, 507 / 2048)
        texture:SetSize(20, 20)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("TOPLEFT", -7, -10)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(465 / 512, 499 / 512, 383 / 2048, 405 / 2048)
        texture:SetSize(20, height / 2)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("BOTTOMLEFT", -7, -7)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(465 / 512, 499 / 512, 383 / 2048, 429 / 2048)
        texture:SetSize(20, 20)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("TOPRIGHT", 7, 7)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(463 / 512, 507 / 512, 441 / 2048, 473 / 2048)
        texture:SetSize(20, 20)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("TOPRIGHT", 7, -10)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(465 / 512, 509 / 512, 335 / 2048, 359 / 2048)
        texture:SetSize(20, height / 2)
    end

    do
        local texture = nineSliceFrame:CreateTexture(nil, "BORDER")
        texture:SetPoint("BOTTOMRIGHT", 7, -7)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        texture:SetTexCoord(465 / 512, 509 / 512, 335 / 2048, 381 / 2048)
        texture:SetSize(20, 20)
    end

    return nineSliceFrame
end

MAIN_ACTION_BAR_ID = 1
BONUS_ACTION_BAR_ID = 6
SHAPESHIFT_ACTION_BAR_ID = 7
PET_ACTION_BAR_ID = 8
POSSESS_ACTION_BAR_ID = 9

local function verticalString(str)
    local _, len = str:gsub("[^\128-\193]", "")
    if (len == #str) then
        return str:gsub(".", "%1\n")
    else
        return str:gsub("([%z\1-\127\194-\244][\128-\191]*)", "%1\n")
    end
end

local function CreateActionFrameBar(barID, buttonCount, buttonSize, gap, vertical, frameName)
    if buttonCount > 12 then
        assert(nil, "The Action Bar cannot contain more than 12 buttons")
    end

    local width
    local height

    if vertical then
        width = (buttonSize - 2)
        height = gap * (buttonCount - 1) + ((buttonSize - 2) * buttonCount)
    else
        width = gap * (buttonCount - 1) + ((buttonSize - 2) * buttonCount)
        height = (buttonSize - 2)
    end

    -- Default
    frameName = frameName or ('ActionBar' .. barID)

    local frameBar = CreateUIFrame(width, height, frameName)

    -- Change text direction if vertical bar
    if vertical then
        frameBar.editorText:SetText(verticalString(frameBar.editorText:GetText()))
    end

    frameBar.borderTextures = {}
    frameBar.backgroundTextures = {}

    for index = 1, buttonCount do
        frameBar.borderTextures[index] = frameBar:CreateTexture(nil, 'OVERLAY')
        frameBar.backgroundTextures[index] = frameBar:CreateTexture(nil, "BACKGROUND")
    end

    if barID == MAIN_ACTION_BAR_ID then
        frameBar.nineSlice = CreateNineSliceFrame(width, height)
        frameBar.nineSlice:SetPoint("LEFT", frameBar, "LEFT", 0, 0)
    end

    frameBar.ID = barID
    frameBar.buttonSize = buttonSize
    frameBar.buttonCount = buttonCount
    frameBar.gap = gap
    frameBar.vertical = vertical

    return frameBar
end

local function ShowBackgroundActionButton(button)
    local normalTexture = button:GetNormalTexture()
    normalTexture:SetAlpha(0)
end

local function ActionButton_ShowGrid(button)
    ShowBackgroundActionButton(button)
    button:Show()
end

local function ActionButton_Update(button)
    ShowBackgroundActionButton(button)
end

local function ReputationWatchBar_Update()
    local factionInfo = GetWatchedFactionInfo();
    if factionInfo then
        local repWatchBar = ReputationWatchBar
        repWatchBar:ClearAllPoints()
        repWatchBar:SetHeight(Module.repExpBar:GetHeight())
        repWatchBar:SetPoint("LEFT", Module.repExpBar, "LEFT", 0, 0)
    end
end

local function MainMenuExpBar_Update()
    local mainMenuExpBar = MainMenuExpBar
    mainMenuExpBar:ClearAllPoints()
    mainMenuExpBar:SetWidth(Module.repExpBar:GetWidth())
    mainMenuExpBar:SetHeight(Module.repExpBar:GetHeight())
    mainMenuExpBar:SetPoint("LEFT", Module.repExpBar, "LEFT", 0, 0)

    local repWatchBar = ReputationWatchBar
    if repWatchBar:IsShown() then
        mainMenuExpBar:SetPoint("LEFT", repWatchBar, "LEFT", 0, -22)
    else
        mainMenuExpBar:SetPoint("LEFT", Module.repExpBar, "LEFT", 0, 0)
    end
end

local function ShapeshiftBar_Update()
    local button = _G['ShapeshiftButton' .. 1]
    button:ClearAllPoints()
    button:SetPoint("LEFT", Module.actionBars[SHAPESHIFT_ACTION_BAR_ID], "LEFT", 0)

    if GetNumShapeshiftForms() > 0 then
        button = _G['ShapeshiftButton' .. GetNumShapeshiftForms()]
        Module.actionBars[PET_ACTION_BAR_ID]:SetPoint("LEFT", button, "RIGHT", 10, 0)
    else
        Module.actionBars[PET_ACTION_BAR_ID]:SetPoint("LEFT", Module.actionBars[SHAPESHIFT_ACTION_BAR_ID], "LEFT", 0, 0)
    end

    Module.actionBars[POSSESS_ACTION_BAR_ID]:SetPoint("LEFT", Module.actionBars[SHAPESHIFT_ACTION_BAR_ID], "LEFT", 0, 0)
end

function Module:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PET_BAR_UPDATE")

    self:SecureHook('ActionButton_ShowGrid', ActionButton_ShowGrid)
    self:SecureHook('ActionButton_Update', ActionButton_Update)
    self:SecureHook('ReputationWatchBar_Update', ReputationWatchBar_Update)
    self:SecureHook('MainMenuExpBar_Update', MainMenuExpBar_Update)
    self:SecureHook('ShapeshiftBar_Update', ShapeshiftBar_Update)

    -- Main
    self.actionBars[MAIN_ACTION_BAR_ID] = CreateActionFrameBar(MAIN_ACTION_BAR_ID, 12, 42, 4, false)

    for index = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G['ActionButton' .. index]
        button:SetAttribute('showgrid', 1)
        ActionButton_ShowGrid(button)
    end

    -- RepExp
    self.repExpBar = CreateUIFrame(self.actionBars[MAIN_ACTION_BAR_ID]:GetWidth(), 16, "RepExpBar")

    -- Bottom Side
    for index = 2, 3 do
        self.actionBars[index] = CreateActionFrameBar(index, 12, 42, 4, false)
    end

    -- Right Side
    for index = 4, 5 do
        self.actionBars[index] = CreateActionFrameBar(index, 12, 42, 6, true)
    end

    -- Bonus
    self.actionBars[BONUS_ACTION_BAR_ID] = CreateActionFrameBar(BONUS_ACTION_BAR_ID, 12, 42, 4, false)

    for index = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G['BonusActionButton' .. index]
        button:SetAttribute('showgrid', 1)
        ActionButton_ShowGrid(button)
    end

    -- Stance (Shapeshift)
    self.actionBars[SHAPESHIFT_ACTION_BAR_ID] = CreateActionFrameBar(SHAPESHIFT_ACTION_BAR_ID, 10, 40, 4, false)

    -- Possess
    self.actionBars[POSSESS_ACTION_BAR_ID] = CreateActionFrameBar(POSSESS_ACTION_BAR_ID, 2, 40, 4, false)

    -- Pet
    self.actionBars[PET_ACTION_BAR_ID] = CreateActionFrameBar(PET_ACTION_BAR_ID, 10, 36, 4, false)

    -- Micro Menu
    self.microMenuBar = CreateActionFrameBar(nil, 10, 29, 2, false, 'MicroMenuBar')

    -- Bags
    self.bagsBar = CreateActionFrameBar(nil, 5, 50, 2, false, 'BagsBar')
end

function Module:OnDisable()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PET_BAR_UPDATE")

    self:Unhook('ActionButton_ShowGrid', ActionButton_ShowGrid)
    self:Unhook('ActionButton_Update', ActionButton_Update)
    self:Unhook('ReputationWatchBar_Update', ReputationWatchBar_Update)
    self:Unhook('MainMenuExpBar_Update', MainMenuExpBar_Update)
    self:Unhook('ShapeshiftBar_Update', ShapeshiftBar_Update)

    Module.actionBars = nil
    Module.repExpBar = nil
    Module.bagsBar = nil
    Module.microMenuBar = nil
end

function Module:PLAYER_ENTERING_WORLD()
    self:RemoveBlizzardFrames()
    self:ReplaceBlizzardFrames()

    if RUI.DB.profile.widgets.actionBar == nil or RUI.DB.profile.widgets.bagsBar == nil or RUI.DB.profile.widgets.repExpBar == nil or
        RUI.DB.profile.widgets.microMenuBar == nil then
        self:LoadDefaultSettings()
    end

    self:UpdateWidgets()
end

local petBarInitialized = false

function Module:PET_BAR_UPDATE()
    if not petBarInitialized then
        self:ReplaceBlizzardActionBarFrame(self.actionBars[SHAPESHIFT_ACTION_BAR_ID])
        self:ReplaceBlizzardActionBarFrame(self.actionBars[PET_ACTION_BAR_ID])
    end

    petBarInitialized = true
end

local blizzActionBars = {
    'ActionButton',
    'MultiBarBottomLeftButton',
    'MultiBarBottomRightButton',
    'MultiBarRightButton',
    'MultiBarLeftButton',
    'BonusActionButton',
    'ShapeshiftButton',
    'PetActionButton',
    'PossessButton'
}

function Module:ReplaceBlizzardActionBarFrame(frameBar)
    if frameBar.ID == MAIN_ACTION_BAR_ID then
        local faction = UnitFactionGroup('player')

        local leftEndCap = MainMenuBarLeftEndCap
        leftEndCap:ClearAllPoints()
        leftEndCap:SetPoint("RIGHT", frameBar, "LEFT", 6, 4)

        local rightEndCap = MainMenuBarRightEndCap
        rightEndCap:ClearAllPoints()
        rightEndCap:SetPoint("LEFT", frameBar, "RIGHT", -6, 4)
        rightEndCap:SetSize(92, 92)

        if faction == 'Alliance' then
            leftEndCap:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
            leftEndCap:SetTexCoord(1 / 512, 357 / 512, 209 / 2048, 543 / 2048)
            leftEndCap:SetSize(92, 92)

            rightEndCap:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
            rightEndCap:SetTexCoord(1 / 512, 357 / 512, 545 / 2048, 879 / 2048)
            rightEndCap:SetSize(92, 92)
        else
            leftEndCap:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
            leftEndCap:SetTexCoord(1 / 512, 357 / 512, 881 / 2048, 1215 / 2048)
            leftEndCap:SetSize(104.5, 96)

            rightEndCap:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
            rightEndCap:SetTexCoord(1 / 512, 357 / 512, 1217 / 2048, 1551 / 2048)
            rightEndCap:SetSize(104.5, 96)
        end

        local pageNumber = _G['MainMenuBarPageNumber']
        pageNumber:SetPoint("CENTER", frameBar, "LEFT", -18, 0)
        pageNumber:SetFontObject(GameFontNormal)

        local barUpButton = _G['ActionBarUpButton']
        barUpButton:SetPoint("CENTER", pageNumber, "CENTER", 0, 15)

        local normalTexture = barUpButton:GetNormalTexture()
        normalTexture:SetPoint("TOPLEFT", 7, -6)
        normalTexture:SetPoint("BOTTOMRIGHT", -7, 6)
        normalTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        normalTexture:SetTexCoord(359 / 512, 393 / 512, 833 / 2048, 861 / 2048)

        local pushedTexture = barUpButton:GetPushedTexture()
        pushedTexture:SetPoint("TOPLEFT", 7, -6)
        pushedTexture:SetPoint("BOTTOMRIGHT", -7, 6)
        pushedTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        pushedTexture:SetTexCoord(453 / 512, 487 / 512, 679 / 2048, 707 / 2048)

        local highlightTexture = barUpButton:GetHighlightTexture()
        highlightTexture:SetPoint("TOPLEFT", 7, -6)
        highlightTexture:SetPoint("BOTTOMRIGHT", -7, 6)
        highlightTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        highlightTexture:SetTexCoord(453 / 512, 487 / 512, 709 / 2048, 737 / 2048)

        local barDownButton = _G['ActionBarDownButton']
        barDownButton:SetPoint("CENTER", pageNumber, "CENTER", 0, -15)

        normalTexture = barDownButton:GetNormalTexture()
        normalTexture:SetPoint("TOPLEFT", 7, -6)
        normalTexture:SetPoint("BOTTOMRIGHT", -7, 6)
        normalTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        normalTexture:SetTexCoord(463 / 512, 497 / 512, 605 / 2048, 633 / 2048)

        pushedTexture = barDownButton:GetPushedTexture()
        pushedTexture:SetPoint("TOPLEFT", 7, -6)
        pushedTexture:SetPoint("BOTTOMRIGHT", -7, 6)
        pushedTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        pushedTexture:SetTexCoord(463 / 512, 497 / 512, 545 / 2048, 573 / 2048)

        highlightTexture = barDownButton:GetHighlightTexture()
        highlightTexture:SetPoint("TOPLEFT", 7, -6)
        highlightTexture:SetPoint("BOTTOMRIGHT", -7, 6)
        highlightTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        highlightTexture:SetTexCoord(463 / 512, 497 / 512, 575 / 2048, 603 / 2048)
    end

    for index = 1, frameBar.buttonCount do
        local button = _G[blizzActionBars[frameBar.ID] .. index]
        button:ClearAllPoints()

        if index > 1 then
            if frameBar.vertical then
                button:SetPoint("TOP", _G[blizzActionBars[frameBar.ID] .. index - 1], "BOTTOM", 0, -frameBar.gap)
            else
                button:SetPoint("LEFT", _G[blizzActionBars[frameBar.ID] .. index - 1], "RIGHT", frameBar.gap, 0)
            end
        else
            if frameBar.vertical then
                button:SetPoint("TOP", frameBar, "TOP", 0, 0)
            else
                button:SetPoint("LEFT", frameBar, "LEFT", 0, 0)
            end
        end

        button:SetSize(frameBar.buttonSize - 2, frameBar.buttonSize - 2)

        local normalTexture = button:GetNormalTexture()
        normalTexture:SetAllPoints(button)
        normalTexture:SetPoint("TOPLEFT", -2, 2)
        normalTexture:SetPoint("BOTTOMRIGHT", 2, -2)
        normalTexture:SetDrawLayer("BACKGROUND")
        normalTexture:SetAlpha(0)

        local backgroundTexture = frameBar.backgroundTextures[index]
        backgroundTexture:SetParent(button)
        backgroundTexture:SetAllPoints(button)
        backgroundTexture:SetPoint("TOPLEFT", -2, 2)
        backgroundTexture:SetPoint("BOTTOMRIGHT", 2, -2)
        backgroundTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        backgroundTexture:SetTexCoord(359 / 512, 487 / 512, 209 / 2048, 333 / 2048)

        if frameBar.ID == MAIN_ACTION_BAR_ID or frameBar.ID == BONUS_ACTION_BAR_ID then
            backgroundTexture:Show()
        else
            backgroundTexture:Hide()
        end

        local highlightTexture = button:GetHighlightTexture()
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        highlightTexture:SetTexCoord(359 / 512, 451 / 512, 1065 / 2048, 1155 / 2048)

        local pushedTexture = button:GetPushedTexture()
        pushedTexture:SetAllPoints(button)
        pushedTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        pushedTexture:SetTexCoord(359 / 512, 451 / 512, 881 / 2048, 971 / 2048)

        local checkedTexture = button:GetCheckedTexture()
        checkedTexture:SetAllPoints(button)
        checkedTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        checkedTexture:SetTexCoord(359 / 512, 451 / 512, 881 / 2048, 971 / 2048)

        local icon = _G[button:GetName() .. "Icon"]
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", -1, -1)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        icon:SetDrawLayer('BORDER')

        local border = _G[button:GetName() .. "Border"]
        border:SetPoint("TOPLEFT", button, "TOPLEFT", -1, -1)
        border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        border:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        border:SetTexCoord(359 / 512, 451 / 512, 881 / 2048, 971 / 2048)
        border:SetDrawLayer("OVERLAY")

        local flash = _G[button:GetName() .. "Flash"]
        flash:SetAllPoints(button)
        flash:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        flash:SetTexCoord(359 / 512, 451 / 512, 973 / 2048, 1063 / 2048)

        local macroText = _G[button:GetName() .. "Name"]
        macroText:SetPoint("BOTTOM", 0, 5)

        local count = _G[button:GetName() .. "Count"]
        count:SetPoint("BOTTOMRIGHT", -4, 3)

        local hotKey = _G[button:GetName() .. "HotKey"]
        hotKey:SetPoint("TOPLEFT", 4, -3)

        local cooldown = _G[button:GetName() .. "Cooldown"]
        cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -2)
        cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

        local borderTexture = frameBar.borderTextures[index]
        borderTexture:SetParent(button)
        borderTexture:SetAllPoints(button)
        borderTexture:SetPoint("TOPLEFT", -2, 2)
        borderTexture:SetPoint("BOTTOMRIGHT", 2, -2)
        borderTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ActionBar.blp")
        borderTexture:SetTexCoord(359 / 512, 451 / 512, 649 / 2048, 739 / 2048)
    end
end

function Module:ReplaceBlizzardRepExpBarFrame(frameBar)
    local mainMenuExpBar = MainMenuExpBar
    mainMenuExpBar:ClearAllPoints()

    mainMenuExpBar:SetWidth(frameBar:GetWidth())

    for _, region in pairs { mainMenuExpBar:GetRegions() } do
        if region:GetObjectType() == 'Texture' and region:GetDrawLayer() == 'BACKGROUND' then
            region:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ExperienceBar.blp")
            region:SetTexCoord(0.00088878125, 570 / 2048, 20 / 64, 29 / 64)
        end
    end

    local exhaustionLevelBar = ExhaustionLevelFillBar
    exhaustionLevelBar:SetHeight(frameBar:GetHeight())

    -- Reuse Blizzard Frames
    local frameBorder = MainMenuXPBarTexture0
    frameBorder:SetAllPoints(mainMenuExpBar)
    frameBorder:SetPoint("TOPLEFT", mainMenuExpBar, "TOPLEFT", -3, 3)
    frameBorder:SetPoint("BOTTOMRIGHT", mainMenuExpBar, "BOTTOMRIGHT", 3, -6)
    frameBorder:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ExperienceBar.blp")
    frameBorder:SetTexCoord(1 / 2048, 572 / 2048, 1 / 64, 18 / 64)

    local expText = MainMenuBarExpText
    expText:SetPoint("CENTER", mainMenuExpBar, "CENTER", 0, 2)

    local repWatchBar = ReputationWatchBar
    repWatchBar:ClearAllPoints()

    repWatchBar:SetWidth(frameBar:GetWidth())

    local repStatusBar = ReputationWatchStatusBar
    repStatusBar:SetAllPoints(repWatchBar)

    repStatusBar:SetWidth(repWatchBar:GetWidth())

    local background = _G[repStatusBar:GetName() .. "Background"]
    background:SetAllPoints(repStatusBar)
    background:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ExperienceBar.blp")
    background:SetTexCoord(0.00088878125, 570 / 2048, 20 / 64, 29 / 64)

    -- Reuse Blizzard Frames
    local frameBorder = ReputationXPBarTexture0
    frameBorder:SetAllPoints(repStatusBar)
    frameBorder:SetPoint("TOPLEFT", repStatusBar, "TOPLEFT", -3, 2)
    frameBorder:SetPoint("BOTTOMRIGHT", repStatusBar, "BOTTOMRIGHT", 3, -7)
    frameBorder:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ExperienceBar.blp")
    frameBorder:SetTexCoord(1 / 2048, 572 / 2048, 1 / 64, 18 / 64)

    -- Reuse Blizzard Frames
    frameBorder = ReputationWatchBarTexture0
    frameBorder:SetAllPoints(repStatusBar)
    frameBorder:SetPoint("TOPLEFT", repStatusBar, "TOPLEFT", -3, 2)
    frameBorder:SetPoint("BOTTOMRIGHT", repStatusBar, "BOTTOMRIGHT", 3, -7)
    frameBorder:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-ExperienceBar.blp")
    frameBorder:SetTexCoord(1 / 2048, 572 / 2048, 1 / 64, 18 / 64)
end

local microMenuButtons = {
    CharacterMicroButton,
    SpellbookMicroButton,
    TalentMicroButton,
    AchievementMicroButton,
    QuestLogMicroButton,
    SocialsMicroButton,
    PVPMicroButton,
    LFDMicroButton,
    MainMenuMicroButton,
    HelpMicroButton
}

local microMenuStyles = {
    {
        normalTexture = { left = 1 / 256, right = 39 / 256, top = 325 / 512, bottom = 377 / 512 },
        pushedTexture = { left = 121 / 256, right = 159 / 256, top = 163 / 512, bottom = 215 / 512 },
        highlightTexture = { left = 81 / 256, right = 119 / 256, top = 217 / 512, bottom = 269 / 512 }
    },
    {
        normalTexture = { left = 121 / 256, right = 159 / 256, top = 55 / 512, bottom = 107 / 512 },
        pushedTexture = { left = 81 / 256, right = 119 / 256, top = 433 / 512, bottom = 485 / 512 },
        highlightTexture = { left = 189 / 256, right = 227 / 256, top = 433 / 512, bottom = 485 / 512 }
    },
    {
        normalTexture = { left = 161 / 256, right = 199 / 256, top = 1 / 512, bottom = 53 / 512 },
        pushedTexture = { left = 81 / 256, right = 119 / 256, top = 271 / 512, bottom = 323 / 512 },
        highlightTexture = { left = 81 / 256, right = 119 / 256, top = 1 / 512, bottom = 53 / 512 },
        disabledTexture = { left = 81 / 256, right = 119 / 256, top = 55 / 512, bottom = 107 / 512 }
    },
    {
        normalTexture = { left = 161 / 256, right = 199 / 256, top = 109 / 512, bottom = 161 / 512 },
        pushedTexture = { left = 161 / 256, right = 199 / 256, top = 55 / 512, bottom = 107 / 512 },
        highlightTexture = { left = 201 / 256, right = 239 / 256, top = 55 / 512, bottom = 107 / 512 },
        disabledTexture = { left = 201 / 256, right = 239 / 256, top = 109 / 512, bottom = 161 / 512 }
    },
    {
        normalTexture = { left = 201 / 256, right = 239 / 256, top = 271 / 512, bottom = 323 / 512 },
        pushedTexture = { left = 121 / 256, right = 159 / 256, top = 271 / 512, bottom = 323 / 512 },
        highlightTexture = { left = 41 / 256, right = 79 / 256, top = 433 / 512, bottom = 485 / 512 }
    },
    {
        normalTexture = { left = 41 / 256, right = 79 / 256, top = 55 / 512, bottom = 107 / 512 },
        pushedTexture = { left = 1 / 256, right = 39 / 256, top = 1 / 512, bottom = 53 / 512 },
        highlightTexture = { left = 41 / 256, right = 79 / 256, top = 1 / 512, bottom = 53 / 512 }
    },
    {
        normalTexture = { left = 1 / 256, right = 39 / 256, top = 271 / 512, bottom = 323 / 512 },
        pushedTexture = { left = 201 / 256, right = 239 / 256, top = 163 / 512, bottom = 215 / 512 },
        highlightTexture = { left = 1 / 256, right = 39 / 256, top = 271 / 512, bottom = 323 / 512 },
        disabledTexture = { left = 81 / 256, right = 119 / 256, top = 163 / 512, bottom = 215 / 512 }
    },
    {
        normalTexture = { left = 1 / 256, right = 39 / 256, top = 163 / 512, bottom = 215 / 512 },
        pushedTexture = { left = 81 / 256, right = 119 / 256, top = 109 / 512, bottom = 161 / 512 },
        highlightTexture = { left = 41 / 256, right = 79 / 256, top = 109 / 512, bottom = 161 / 512 },
        disabledTexture = { left = 41 / 256, right = 79 / 256, top = 271 / 512, bottom = 323 / 512 }
    },
    {
        normalTexture = { left = 1 / 256, right = 39 / 256, top = 109 / 512, bottom = 161 / 512 },
        pushedTexture = { left = 161 / 256, right = 199 / 256, top = 271 / 512, bottom = 323 / 512 },
        highlightTexture = { left = 121 / 256, right = 159 / 256, top = 325 / 512, bottom = 377 / 512 }
    },
    {
        normalTexture = { left = 201 / 256, right = 239 / 256, top = 217 / 512, bottom = 269 / 512 },
        pushedTexture = { left = 121 / 256, right = 159 / 256, top = 217 / 512, bottom = 269 / 512 },
        highlightTexture = { left = 161 / 256, right = 199 / 256, top = 217 / 512, bottom = 269 / 512 }
    }
}

function Module:ReplaceBlizzardMicroMenuBarFrame(frameBar)
    for index, button in pairs(microMenuButtons) do
        button:ClearAllPoints()

        if index > 1 then
            button:SetPoint("LEFT", microMenuButtons[index - 1], "RIGHT", frameBar.gap, 0)
        else
            button:SetPoint("LEFT", frameBar, "LEFT", 0, 0)
        end

        button:SetSize(21, 29)
        button:SetHitRectInsets(0, 0, 0, 0)

        local normalTexture = button:GetNormalTexture()
        normalTexture:SetAllPoints(button)
        normalTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-MicroMenu.blp")
        normalTexture:SetTexCoord(microMenuStyles[index].normalTexture.left, microMenuStyles[index].normalTexture.right,
            microMenuStyles[index].normalTexture.top, microMenuStyles[index].normalTexture.bottom)

        local highlightTexture = button:GetHighlightTexture()
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-MicroMenu.blp")
        highlightTexture:SetTexCoord(microMenuStyles[index].highlightTexture.left,
            microMenuStyles[index].highlightTexture.right, microMenuStyles[index].highlightTexture.top,
            microMenuStyles[index].highlightTexture.bottom)

        local pushedTexture = button:GetPushedTexture()
        pushedTexture:SetAllPoints(button)
        pushedTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-MicroMenu.blp")
        pushedTexture:SetTexCoord(microMenuStyles[index].pushedTexture.left,
            microMenuStyles[index].pushedTexture.right, microMenuStyles[index].pushedTexture.top,
            microMenuStyles[index].pushedTexture.bottom)

        if microMenuStyles[index].disabledTexture ~= nil then
            local disabledTexture = button:GetDisabledTexture() or button:CreateTexture(nil, "OVERLAY")
            disabledTexture:SetAllPoints(button)
            disabledTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-MicroMenu.blp")
            disabledTexture:SetTexCoord(microMenuStyles[index].disabledTexture.left,
                microMenuStyles[index].disabledTexture.right, microMenuStyles[index].disabledTexture.top,
                microMenuStyles[index].disabledTexture.bottom)

            button:SetDisabledTexture(disabledTexture)
        end
    end

    -- Portrait
    local playerPortrait = MicroButtonPortrait
    playerPortrait:Hide()

    -- PVP Flag
    _G['PVPMicroButton' .. "Texture"]:Hide()
end

local bagSlotButtons = {
    KeyRingButton,
    CharacterBag3Slot,
    CharacterBag2Slot,
    CharacterBag1Slot,
    CharacterBag0Slot
}

function Module:ReplaceBlizzardBagsBarFrame(frameBar)
    for index, button in pairs(bagSlotButtons) do
        button:ClearAllPoints()

        if index > 1 then
            button:SetPoint("LEFT", bagSlotButtons[index - 1], "RIGHT", frameBar.gap, 0)
        else
            button:SetPoint("LEFT", frameBar, "LEFT", 0, 0)
        end

        button:SetSize(32, 32)

        button:SetNormalTexture('')
        button:SetPushedTexture(nil)

        local highlightTexture = button:GetHighlightTexture()
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-BagSlots.blp")
        highlightTexture:SetTexCoord(358 / 512, 419 / 512, 1 / 128, 62 / 128)

        local checkedTexture = button:GetCheckedTexture() or button:CreateTexture(nil, 'OVERLAY')
        checkedTexture:SetAllPoints(button)
        checkedTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-BagSlots.blp")
        checkedTexture:SetTexCoord(358 / 512, 419 / 512, 1 / 128, 62 / 128)

        button:SetCheckedTexture(checkedTexture)

        local iconTexture = _G[button:GetName() .. 'IconTexture']
        if iconTexture then
            iconTexture:ClearAllPoints()
            iconTexture:SetPoint('TOPLEFT', 6, -5)
            iconTexture:SetPoint('BOTTOMRIGHT', -7, 7)
            iconTexture:SetTexCoord(.08, .92, .08, .92)
            iconTexture:SetDrawLayer('BACKGROUND')
        end

        local borderTexture = frameBar.borderTextures[index]
        borderTexture:SetParent(button)
        borderTexture:SetAllPoints(button)

        if index == 1 then -- Keys
            borderTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-BagSlotsKey.blp")
            borderTexture:SetTexCoord(3 / 128, 63 / 128, 64 / 128, 125 / 128)
        else -- Bags
            borderTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-BagSlots.blp")
            borderTexture:SetTexCoord(295 / 512, 356 / 512, 1 / 128, 62 / 128)
        end
    end

    do
        local button = MainMenuBarBackpackButton
        button:ClearAllPoints()
        button:SetPoint("LEFT", CharacterBag0Slot, "RIGHT", frameBar.gap, 0)

        button:SetSize(50, 50)

        button:SetNormalTexture(nil)
        button:SetPushedTexture(nil)

        local highlightTexture = button:GetHighlightTexture()
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-BagSlots.blp")
        highlightTexture:SetTexCoord(99 / 512, 195 / 512, 1 / 128, 97 / 128)

        button:SetCheckedTexture(highlightTexture)
        button:SetHighlightTexture(highlightTexture)

        local iconTexture = _G[button:GetName() .. 'IconTexture']
        iconTexture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI-BagSlots.blp")
        iconTexture:SetTexCoord(1 / 512, 97 / 512, 1 / 128, 97 / 128)
    end
end

local blizzActionBarFrames = {
    MainMenuBarPerformanceBar,
    MainMenuBarTexture0,
    MainMenuBarTexture1,
    MainMenuBarTexture2,
    MainMenuBarTexture3,
    MainMenuBarMaxLevelBar,
    ReputationXPBarTexture1,
    ReputationXPBarTexture2,
    ReputationXPBarTexture3,
    ReputationWatchBarTexture1,
    ReputationWatchBarTexture2,
    ReputationWatchBarTexture3,
    MainMenuXPBarTexture1,
    MainMenuXPBarTexture2,
    MainMenuXPBarTexture3,
    SlidingActionBarTexture0,
    SlidingActionBarTexture1,
    BonusActionBarTexture0,
    BonusActionBarTexture1,
    ShapeshiftBarLeft,
    ShapeshiftBarMiddle,
    ShapeshiftBarRight,
    PossessBackground1,
    PossessBackground2
}

function Module:RemoveBlizzardFrames()
    for _, frame in pairs(blizzActionBarFrames) do
        frame:SetAlpha(0)
    end

    MainMenuBar:EnableMouse(false)
    ShapeshiftBarFrame:EnableMouse(false)
    PossessBarFrame:EnableMouse(false)
    PetActionBarFrame:EnableMouse(false)
end

local hideMainActionBarFrames = {
    MainMenuBarPageNumber,
    MainMenuBarLeftEndCap,
    MainMenuBarRightEndCap,
    ActionBarUpButton,
    ActionBarDownButton
}

function Module:EnableEditorPreviewForActionBarFrames()
    for index, actionBar in pairs(self.actionBars) do
        if index ~= BONUS_ACTION_BAR_ID and index ~= PET_ACTION_BAR_ID and index ~= POSSESS_ACTION_BAR_ID then
            actionBar:SetMovable(true)
            actionBar:EnableMouse(true)

            actionBar.editorTexture:Show()
            actionBar.editorText:Show()
        end

        if index == 1 then
            actionBar.nineSlice:Hide()

            for _, frame in pairs(hideMainActionBarFrames) do
                frame:SetAlpha(0)
            end
        end

        for index = 1, actionBar.buttonCount do
            local button = _G[blizzActionBars[actionBar.ID] .. index]
            button:SetAlpha(0)
            button:EnableMouse(false)
        end
    end
end

function Module:DisableEditorPreviewForActionBarFrames()
    for index, actionBar in pairs(self.actionBars) do
        if index ~= BONUS_ACTION_BAR_ID and index ~= PET_ACTION_BAR_ID and index ~= POSSESS_ACTION_BAR_ID then
            actionBar:SetMovable(false)
            actionBar:EnableMouse(false)

            actionBar.editorTexture:Hide()
            actionBar.editorText:Hide()

            local _, _, relativePoint, posX, posY = actionBar:GetPoint('CENTER')
            RUI.DB.profile.widgets.actionBar[index].anchor = relativePoint
            RUI.DB.profile.widgets.actionBar[index].posX = posX
            RUI.DB.profile.widgets.actionBar[index].posY = posY
        end

        if index == 1 then
            actionBar.nineSlice:Show()

            for _, frame in pairs(hideMainActionBarFrames) do
                frame:SetAlpha(1)
            end
        end

        for index = 1, actionBar.buttonCount do
            local button = _G[blizzActionBars[actionBar.ID] .. index]
            button:SetAlpha(1)
            button:EnableMouse(true)
        end
    end
end

local hideBagSlotButtons = {
    MainMenuBarBackpackButton,
    CharacterBag0Slot,
    CharacterBag1Slot,
    CharacterBag2Slot,
    CharacterBag3Slot,
    KeyRingButton
}

function Module:EnableEditorPreviewForBagsFrame()
    local bagsBar = self.bagsBar

    bagsBar:SetMovable(true)
    bagsBar:EnableMouse(true)

    bagsBar.editorTexture:Show()
    bagsBar.editorText:Show()

    for _, button in pairs(hideBagSlotButtons) do
        button:SetAlpha(0)
        button:EnableMouse(false)
    end
end

function Module:DisableEditorPreviewForBagsFrame()
    local bagsBar = self.bagsBar

    bagsBar:SetMovable(false)
    bagsBar:EnableMouse(false)

    bagsBar.editorTexture:Hide()
    bagsBar.editorText:Hide()

    for _, button in pairs(hideBagSlotButtons) do
        button:SetAlpha(1)
        button:EnableMouse(true)
    end

    local _, _, relativePoint, posX, posY = bagsBar:GetPoint('CENTER')
    RUI.DB.profile.widgets.bagsBar.anchor = relativePoint
    RUI.DB.profile.widgets.bagsBar.posX = posX
    RUI.DB.profile.widgets.bagsBar.posY = posY
end

local hideMicroMenuButtons = {
    CharacterMicroButton,
    SpellbookMicroButton,
    TalentMicroButton,
    AchievementMicroButton,
    QuestLogMicroButton,
    SocialsMicroButton,
    PVPMicroButton,
    LFDMicroButton,
    MainMenuMicroButton,
    HelpMicroButton
}

function Module:EnableEditorPreviewForMicroMenuBarFrame()
    local microMenuBar = self.microMenuBar

    microMenuBar:SetMovable(true)
    microMenuBar:EnableMouse(true)

    microMenuBar.editorTexture:Show()
    microMenuBar.editorText:Show()

    for _, button in pairs(hideMicroMenuButtons) do
        button:SetAlpha(0)
        button:EnableMouse(false)
    end
end

function Module:DisableEditorPreviewForMicroMenuBarFrame()
    local microMenuBar = self.microMenuBar

    microMenuBar:SetMovable(false)
    microMenuBar:EnableMouse(false)

    microMenuBar.editorTexture:Hide()
    microMenuBar.editorText:Hide()

    for _, button in pairs(hideMicroMenuButtons) do
        button:SetAlpha(1)
        button:EnableMouse(true)
    end

    local _, _, relativePoint, posX, posY = microMenuBar:GetPoint('CENTER')
    RUI.DB.profile.widgets.microMenuBar.anchor = relativePoint
    RUI.DB.profile.widgets.microMenuBar.posX = posX
    RUI.DB.profile.widgets.microMenuBar.posY = posY
end

function Module:EnableEditorPreviewForRepExpBarFrame()
    local repExpBar = self.repExpBar

    repExpBar:SetMovable(true)
    repExpBar:EnableMouse(true)

    repExpBar.editorTexture:Show()
    repExpBar.editorText:Show()

    ReputationWatchBar:SetAlpha(0)
    ReputationWatchBar:EnableMouse(false)

    local hideFrame = MainMenuExpBar
    hideFrame:SetAlpha(0)
    hideFrame:EnableMouse(false)

    hideFrame = ExhaustionTick
    hideFrame:SetAlpha(0)
    hideFrame:EnableMouse(false)
end

function Module:DisableEditorPreviewForRepExpBarFrame()
    local repExpBar = self.repExpBar

    repExpBar:SetMovable(false)
    repExpBar:EnableMouse(false)

    repExpBar.editorTexture:Hide()
    repExpBar.editorText:Hide()

    ReputationWatchBar:SetAlpha(1)
    ReputationWatchBar:EnableMouse(true)

    local hideFrame = MainMenuExpBar
    hideFrame:SetAlpha(1)
    hideFrame:EnableMouse(true)

    hideFrame = ExhaustionTick
    hideFrame:SetAlpha(1)
    hideFrame:EnableMouse(true)

    local _, _, relativePoint, posX, posY = repExpBar:GetPoint('CENTER')
    RUI.DB.profile.widgets.repExpBar.anchor = relativePoint
    RUI.DB.profile.widgets.repExpBar.posX = posX
    RUI.DB.profile.widgets.repExpBar.posY = posY
end

function Module:ReplaceBlizzardFrames()
    for _, actionBar in pairs(self.actionBars) do
        if actionBar.ID ~= PET_ACTION_BAR_ID and actionBar.ID ~= SHAPESHIFT_ACTION_BAR_ID then
            self:ReplaceBlizzardActionBarFrame(actionBar)
        end
    end

    self:ReplaceBlizzardRepExpBarFrame(self.repExpBar)

    self:ReplaceBlizzardMicroMenuBarFrame(self.microMenuBar)
    self:ReplaceBlizzardBagsBarFrame(self.bagsBar)
end

function Module:LoadDefaultSettings()
    RUI.DB.profile.widgets.actionBar = {}

    for index = 1, 3 do
        RUI.DB.profile.widgets.actionBar[index] = {
            anchor = "BOTTOM",
            posX = 0,
            posY = 60 + 4 * (index - 1) +
                42 * (index - 1)
        }
    end

    for index = 4, 5 do
        RUI.DB.profile.widgets.actionBar[index] = {
            anchor = "RIGHT",
            posX = -4 * (index - 4) - 42 * (index - 4),
            posY = -60
        }
    end

    RUI.DB.profile.widgets.actionBar[SHAPESHIFT_ACTION_BAR_ID] = {
        anchor = "BOTTOM",
        posX = -54,
        posY = 200
    }

    RUI.DB.profile.widgets.microMenuBar = { anchor = "BOTTOMRIGHT", posX = 50, posY = 10 }
    RUI.DB.profile.widgets.bagsBar = { anchor = "BOTTOMRIGHT", posX = 25, posY = 45 }
    RUI.DB.profile.widgets.repExpBar = { anchor = "BOTTOM", posX = 0, posY = 30 }

    -- Static
    RUI.DB.profile.widgets.actionBar[PET_ACTION_BAR_ID] = {
        anchor = "CENTER",
        posX = 0,
        posY = 0
    }

    RUI.DB.profile.widgets.actionBar[BONUS_ACTION_BAR_ID] = {
        anchor = "CENTER",
        posX = 0,
        posY = 0
    }

    RUI.DB.profile.widgets.actionBar[POSSESS_ACTION_BAR_ID] = {
        anchor = "CENTER",
        posX = 0,
        posY = 0
    }
end

function Module:UpdateWidgets()
    for index, actionBar in pairs(self.actionBars) do
        local widgetOptions = RUI.DB.profile.widgets.actionBar[index]
        actionBar:SetPoint(widgetOptions.anchor, widgetOptions.posX, widgetOptions.posY)
    end

    do
        local widgetOptions = RUI.DB.profile.widgets.microMenuBar
        self.microMenuBar:SetPoint(widgetOptions.anchor, widgetOptions.posX, widgetOptions.posY)
    end

    do
        local widgetOptions = RUI.DB.profile.widgets.bagsBar
        self.bagsBar:SetPoint(widgetOptions.anchor, widgetOptions.posX, widgetOptions.posY)
    end

    do
        local widgetOptions = RUI.DB.profile.widgets.repExpBar
        self.repExpBar:SetPoint(widgetOptions.anchor, widgetOptions.posX, widgetOptions.posY)
    end

    -- Static
    do
        self.actionBars[BONUS_ACTION_BAR_ID]:SetPoint('LEFT', self.actionBars[MAIN_ACTION_BAR_ID], 'LEFT', 0, 0)
    end
end
