local RED = "|cFFFF4477";
local YELLOW = "|cFFFFFFAA";
local BLUE = "|cFF22AAFF";
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("ADDON_LOADED")

MessageNotifications.init(eventHandler)
ReadyCheck.init(eventHandler)

eventHandler:SetScript('OnEvent', function()

    if event == "ADDON_LOADED" and arg1 == addonName then
        println(RED .. "luisUtils" .. version .. " loaded >>> " .. BLUE .. "Type /co or /chatobserver for more options.")
    end

    if MessageNotifications.shouldPlaySoundOnMessage(event, arg1) then
        MessageNotifications.playMessageSound(event)
    end

    local addonSender = arg1
    local message = arg2
    local playerSender = arg4

    if ReadyCheck.isReadyCheckStartMessage(event, addonSender, playerSender, message) and ReadyCheck.isReadyCheckOnGoing() == false then
        ReadyCheck.startReadyCheckPartyMember(playerSender)
    end

    if ReadyCheck.isPartyPlayerReadyMessage(event, addonSender, playerSender, message) and ReadyCheck.isReadyCheckOnGoing() then
        ReadyCheck.setPartyPlayerReadyState(playerSender)
    end

    if ReadyCheck.isPartyPlayerNotReadyMessage(event, addonSender, playerSender, message) and ReadyCheck.isReadyCheckOnGoing() then
        ReadyCheck.setPartyPlayerNotReadyState(playerSender)
    end 

end)

