function println(message)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(message or 'null'))
end


function stringInArray(str, arr)
    if str == nil or type(str) ~= "string" then
        return false, -1
    else
        for i, value in ipairs(arr) do
            if value == str then
                return true, i
            end
        end
    end
    return false, -1
end

function onTimeout(duration, callback)
    local timerFrame = CreateFrame("Frame")
    local totalElapsedTime = 0
    timerFrame:SetScript("OnUpdate", function()
        totalElapsedTime = arg1 + totalElapsedTime
        if totalElapsedTime >= duration then
            timerFrame:SetScript("OnUpdate", nil)
            callback()
        end
    end)
    return timerFrame
end

function PrintTable(tbl, indent)
    if type(tbl) ~= "table" then
        print("Not a table!")
        return
    end

    indent = indent or 0
    local prefix = string.rep("  ", indent)

    for k, v in pairs(tbl) do
        local key = tostring(k)
        if type(v) == "table" then
            print(prefix .. key .. ":")
            PrintTable(v, indent + 1)
        else
            print(prefix .. key .. ": " .. tostring(v))
        end
    end
end

function len(t)
    local count = 0
    for _ in ipairs(t) do
        count = count + 1
    end
    return count
end