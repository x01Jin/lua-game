local json = require("json")
local love = require("love")
local player = require("player")

local save_load = {}
local saves = {}

local function updateSaveFiles()
    saves = love.filesystem.getDirectoryItems("")
    for i = #saves, 1, -1 do
        if not saves[i]:match("%.json$") then
            table.remove(saves, i)
        else
            saves[i] = saves[i]:gsub("%.json$", "")
        end
    end
end

updateSaveFiles()

function save_load.saveGame(filename)
    local saveData = {
        player = player,
        history = history
    }
    local file = love.filesystem.newFile(filename .. ".json", "w")
    file:write(json.encode(saveData))
    file:close()
    updateSaveFiles()
end

function save_load.loadGame(filename)
    if love.filesystem.getInfo(filename .. ".json") then
        local file = love.filesystem.newFile(filename .. ".json", "r")
        local saveData = json.decode(file:read())
        file:close()
        player = saveData.player
        history = saveData.history
        return true
    else
        return false
    end
end

function save_load.displaySaveFiles()
    updateSaveFiles()
    for i, save in ipairs(saves) do
        table.insert(history, "Save file: " .. save)
    end
end

function save_load.getSaves()
    return saves
end

return save_load
