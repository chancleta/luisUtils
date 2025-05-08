ReadyCheck = {}

local isReadyCheckOnGoing = false
local readyCheckFinishEventHandler = nil
local playerResponded = ''

local channelCommands = {
    ['start'] = "READYSTART",
    ['ready'] = "PLAYERREADY",
    ['notready'] = "NOTPLAYERREADY",
}

local classIcons = {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE = { 0.25, 0.5, 0, 0.25 },
    ROGUE = { 0.5, 0.75, 0, 0.25 },
    DRUID = { 0.75, 1, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    SHAMAN = { 0.25, 0.5, 0.25, 0.5 },
    PRIEST = { 0.5, 0.75, 0.25, 0.5 },
    WARLOCK = { 0.75, 1, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

-- Table of ready check icons by state
local READY_ICONS = {
    ["waiting"] = "Interface\\Buttons\\UI-CheckBox-Check-Disabled",
    ["ready"] = "Interface\\Buttons\\UI-CheckBox-Check",
    ["notready"] = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
}

local PARTY_MEMBER_RC_STATES = {
    ['party1'] = 'waiting',
    ['party2'] = 'waiting',
    ['party3'] = 'waiting',
    ['party4'] = 'waiting',
}

local EVENT = 'CHAT_MSG_ADDON'

local allTextures = {}
local allTexts = {}

ReadyCheck.frame = CreateFrame("Frame", "ReadyCheckFrame", UIParent)
ReadyCheck.frame:SetWidth(340)
ReadyCheck.frame:SetHeight(125)
ReadyCheck.frame:SetPoint("CENTER", 0, 200)
ReadyCheck.frame:SetMovable(true)
ReadyCheck.frame:EnableMouse(true)
ReadyCheck.frame:RegisterForDrag("LeftButton")

ReadyCheck.frame:SetScript("OnDragStart", function()
    ReadyCheck.frame:StartMoving()
end)

ReadyCheck.frame:SetScript("OnDragStop", function()
    ReadyCheck.frame:StopMovingOrSizing()
end)

ReadyCheck.frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ReadyCheck.frame:SetBackdropColor(0, 0, 0, 1)
ReadyCheck.frame:Hide()

-- Title
ReadyCheck.title = ReadyCheck.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
ReadyCheck.title:SetPoint("TOP", 0, -10)
ReadyCheck.title:SetText("Ready Check")

-- Close Button1
ReadyCheck.closeButton = CreateFrame("Button", nil, ReadyCheck.frame, "UIPanelCloseButton")
ReadyCheck.closeButton:SetWidth(24)
ReadyCheck.closeButton:SetHeight(24)
ReadyCheck.closeButton:SetPoint("TOPRIGHT", ReadyCheck.frame, "TOPRIGHT", -2, -2)

local function readyCheckCloseTimeout()
    onTimeout(15, function()
        ReadyCheck.frame:Hide()

        for i = 1, 4 do
            PARTY_MEMBER_RC_STATES['party' .. i] = 'waiting'
        end
    end)
end

local function tryReadyCheckFinished()
    if playerResponded == '' then
        return
    end
    local someAreNotReady = false
    for i = 1, 4 do
        local partyPlayerName = UnitName("party" .. i)
        if partyPlayerName and PARTY_MEMBER_RC_STATES['party' .. i] == 'waiting' then
            return
        end
        if partyPlayerName and PARTY_MEMBER_RC_STATES['party' .. i] == 'notready' then
            someAreNotReady = true
        end
    end
    ReadyCheck.readyButton:Hide()
    ReadyCheck.notReadyButton:Hide()
    readyCheckCloseTimeout()
    isReadyCheckOnGoing = false
    readyCheckFinishEventHandler:SetScript("OnUpdate", nil)
    if someAreNotReady or playerResponded == 'notready' then
        PlaySound("igQuestFailed")
    else
        PlaySound("AuctionWindowClose")
    end
    playerResponded = ''

end


-- Ready Button
ReadyCheck.readyButton = CreateFrame("Button", nil, ReadyCheck.frame, "UIPanelButtonTemplate")
ReadyCheck.readyButton:SetWidth(90)
ReadyCheck.readyButton:SetHeight(24)
ReadyCheck.readyButton:SetText("Ready")
ReadyCheck.readyButton:SetPoint("BOTTOMLEFT", ReadyCheck.frame, "BOTTOMLEFT", 20, -30)
ReadyCheck.readyButton:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    playerResponded = 'ready'
    ReadyCheck.sendPlayerReadyMessage()
    ReadyCheck.readyButton:Hide()
    ReadyCheck.notReadyButton:Hide()
    onTimeout(2, tryReadyCheckFinished)
end)

-- Not Ready Button
ReadyCheck.notReadyButton = CreateFrame("Button", nil, ReadyCheck.frame, "UIPanelButtonTemplate")
ReadyCheck.notReadyButton:SetWidth(90)
ReadyCheck.notReadyButton:SetHeight(24)
ReadyCheck.notReadyButton:SetText("Not Ready")
ReadyCheck.notReadyButton:SetPoint("BOTTOMRIGHT", ReadyCheck.frame, "BOTTOMRIGHT", -20, -30)
ReadyCheck.notReadyButton:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOff")
    playerResponded = 'notready'
    ReadyCheck.sendPlayerNotReadyMessage()
    ReadyCheck.readyButton:Hide()
    ReadyCheck.notReadyButton:Hide()
    onTimeout(2, tryReadyCheckFinished)
end)

function ReadyCheck.loadPartyClassIcons()
    for i = 1, 4 do
        local _, classFile = UnitClass("party" .. i)
        if classFile ~= nil then
            local length = len(allTextures) + 1
            local coords = classIcons[classFile]
            allTextures[length] = ReadyCheck.frame:CreateTexture(nil, "ARTWORK")
            allTextures[length]:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            allTextures[length]:SetWidth(48)
            allTextures[length]:SetHeight(48)
            allTextures[length]:SetTexCoord(unpack(coords))
            allTextures[length]:SetPoint("LEFT", 25 * i + (i - 1) * 70, -15)
            if PARTY_MEMBER_RC_STATES["party" .. i] == 'waiting' then
                allTextures[length]:SetVertexColor(0.5, 0.5, 0.5)
            else
                allTextures[length]:SetVertexColor(1, 1, 1)
            end
        end
    end
end

function ReadyCheck.loadPartyNames()
    for i = 1, 4 do
        local partyPlayerName = UnitName("party" .. i)
        if partyPlayerName ~= nil then
            local length = len(allTexts) + 1
            allTexts[length] = ReadyCheck.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            allTexts[length]:SetPoint("LEFT", 20 * i + (i - 1) * 70, 20)
            allTexts[length]:SetText(partyPlayerName)
        end
    end
end

function ReadyCheck.loadStateIcons()
    for i = 1, 4 do
        local _, classFile = UnitClass("party" .. i)
        if classFile ~= nil then
            local length = len(allTextures) + 1
            allTextures[length] = ReadyCheck.frame:CreateTexture(nil, "OVERLAY")
            allTextures[length]:SetWidth(32)
            allTextures[length]:SetHeight(32)
            allTextures[length]:SetPoint("LEFT", 25 * i + (i - 1) * 70, -35)
            allTextures[length]:SetTexture(READY_ICONS[PARTY_MEMBER_RC_STATES["party" .. i]])
        end
    end
end

local function registerEvents(eventHandler)
    eventHandler:RegisterEvent(EVENT)
end

local function registerCommand()
    local function onCommand(msg, editBox)
        ReadyCheck.startReadyCheck()
    end

    SLASH_RC1 = "/rc"
    SlashCmdList["RC"] = onCommand
end

local function setPlayerState(player, state)
    for i = 1, 4 do
        local partyPlayerName = UnitName("party" .. i)
        if partyPlayerName ~= nil and partyPlayerName == player then
            PARTY_MEMBER_RC_STATES["party" .. i] = state
        end
    end
end

local function reloadUI()

    for i, texture in ipairs(allTextures) do
        texture:SetTexture(nil)
        texture:Hide()
    end

    for i, text in ipairs(allTexts) do
        text:SetText(nil)
        text:Hide()
    end

    allTextures = nil
    allTextures = {}

    ReadyCheck.frame:Hide()

    ReadyCheck.loadStateIcons()
    ReadyCheck.loadPartyClassIcons()
    ReadyCheck.loadPartyNames()
    ReadyCheck.frame:Show()
end

function ReadyCheck.isReadyCheckStartMessage(event, addon, sender, message)
    if event == EVENT and sender ~= UnitName("player") and addon == addonName then
        return message == channelCommands['start']
    end
    return false
end

function ReadyCheck.isReadyCheckOnGoing()
    return isReadyCheckOnGoing
end

local function readyCheckFinish()
    println('mmg tamo aqui klk')
    if isReadyCheckOnGoing == false then
        return
    end

    for i = 1, 4 do
        local partyPlayerName = UnitName("party" .. i)
        if partyPlayerName and PARTY_MEMBER_RC_STATES['party' .. i] == 'waiting' then
            PARTY_MEMBER_RC_STATES['party' .. i] = 'notready'
            PlaySound("igQuestFailed")
        end
    end
    ReadyCheck.readyButton:Hide()
    ReadyCheck.notReadyButton:Hide()
    readyCheckCloseTimeout()
    reloadUI()
    isReadyCheckOnGoing = false
end

local function startRCTimeout()
    readyCheckFinishEventHandler = onTimeout(60, readyCheckFinish)
end

function ReadyCheck.startReadyCheckPartyMember(readyCheckSender)
    if isReadyCheckOnGoing == false then
        isReadyCheckOnGoing = true
        PlaySound("ReadyCheck")
        setPlayerState(readyCheckSender, 'ready')
        ReadyCheck.title:SetText(readyCheckSender .. " started a Ready Check")
        reloadUI()
        ReadyCheck.readyButton:Show()
        ReadyCheck.notReadyButton:Show()
        startRCTimeout()
        onTimeout(2, tryReadyCheckFinished)
    end
end

function ReadyCheck.sendPlayerReadyMessage()
    SendAddonMessage(addonName, channelCommands['ready'], "PARTY")
end

function ReadyCheck.sendPlayerNotReadyMessage()
    SendAddonMessage(addonName, channelCommands['notready'], "PARTY")
end

local function startReadyCheckOwner()
    playerResponded = 'ready'
    PlaySound("ReadyCheck")
    ReadyCheck.readyButton:Hide()
    ReadyCheck.notReadyButton:Hide()
    startRCTimeout()
    reloadUI()
end

function ReadyCheck.isPartyPlayerReadyMessage(event, addon, sender, message)
    if event == EVENT and sender ~= UnitName("player") and addon == addonName then
        return message == channelCommands['ready']
    end
    return false
end

function ReadyCheck.isPartyPlayerNotReadyMessage(event, addon, sender, message)
    if event == EVENT and sender ~= UnitName("player") and addon == addonName then
        return message == channelCommands['notready']
    end
    return false
end

function ReadyCheck.startReadyCheck()
    if isReadyCheckOnGoing == false then
        isReadyCheckOnGoing = true
        startReadyCheckOwner()
        SendAddonMessage(addonName, channelCommands['start'], "PARTY")
    end
end

function ReadyCheck.setPartyPlayerReadyState(player)
    if isReadyCheckOnGoing then
        PlaySound("igPlayerInvite")
        setPlayerState(player, 'ready')
        reloadUI()
        onTimeout(2, tryReadyCheckFinished)
    end
end

function ReadyCheck.setPartyPlayerNotReadyState(player)
    if isReadyCheckOnGoing then
        PlaySound("igQuestFailed")
        setPlayerState(player, 'notready')
        reloadUI()
        onTimeout(2, tryReadyCheckFinished)
    end
end

function ReadyCheck.init(eventHandler)
    registerEvents(eventHandler)
    registerCommand()
end

tinsert(UISpecialFrames, "ReadyCheckFrame")
