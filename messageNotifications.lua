MessageNotifications = {}

local events = { "CHAT_MSG_PARTY", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER" }
local eventsSounds = { "TellMessage", "TellMessage", "TellMessage" }
local eventSoundsEnabled = { true, true, true }

function MessageNotifications.shouldPlaySoundOnMessage(event, messageSentBy)
    local isMessageEvent, soundIndex = stringInArray(event, events)
    return isMessageEvent and messageSentBy ~= UnitName("player") and eventSoundsEnabled[soundIndex]
end

function MessageNotifications.playMessageSound(event)
    local _, index = stringInArray(event, events)
    eventSoundsEnabled[index] = false
    PlaySound(eventsSounds[index])
    onTimeout(3, function()
        eventSoundsEnabled[index] = true
    end)
end

local function registerEvents(eventHandler)
    for i, _event in ipairs(events) do
        eventHandler:RegisterEvent(_event)
    end
end

function MessageNotifications.init(eventHandler)
    registerEvents(eventHandler)
end

