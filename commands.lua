local player = require("player")
local save_load = require("save_load")
local monsterModule = require("monster")
local combat = require("combat")

local encounterPending = false
local merchantEncounter = false
local savePending = false
local loadPending = false
local saveConfirmation = false
local loadConfirmation = false
local saveName = ""
local input = ""
local history = {}
local logScroll = 0
local logHeight = 400
local font

local function handleCommand(command)
    if combat.isInProgress() then
        return "Combat is in progress. Finish the fight first."
    end

    if encounterPending then
        if command == "fight" then
            encounterPending = false
            combat.start(monster)
            return "Combat started against level " .. monster.level .. " " .. monster.name .. "!"
        elseif command == "run" then
            encounterPending = false
            return "You ran away from the level " .. monster.level .. " " .. monster.name .. "."
        else
            return "You can only use 'fight' or 'run' in this state."
        end
    end

    if merchantEncounter then
        if command == "accept" then
            if player.gold >= 500 then
                player.gold = player.gold - 500
                player.greatPotions = player.greatPotions + 1
                merchantEncounter = false
                return "You bought a great potion from the merchant."
            else
                return "You don't have enough gold."
            end
        elseif command == "decline" then
            merchantEncounter = false
            return "You declined the merchant's offer."
        else
            return "You can only use 'accept' or 'decline' in this state."
        end
    end

    if savePending then
        if saveConfirmation then
            if command == "yes" then
                saveConfirmation = false
                savePending = true
                return "Name your save file:"
            elseif command == "no" then
                saveConfirmation = false
                savePending = false
                return "Save canceled."
            else
                return "You can only use 'yes' or 'no' in this state."
            end
        else
            if command == "cancel" then
                savePending = false
                return "Save canceled."
            else
                saveName = command
                save_load.saveGame(saveName)
                savePending = false
                return "Game saved as " .. saveName
            end
        end
    end

    if loadPending then
        if loadConfirmation then
            if command == "yes" then
                loadConfirmation = false
                loadPending = false
                if save_load.loadGame(saveName) then
                    return "Loaded save " .. saveName
                else
                    return "Save file not found."
                end
            elseif command == "no" then
                loadConfirmation = false
                loadPending = false
                return "Load canceled."
            else
                return "You can only use 'yes' or 'no' in this state."
            end
        else
            if command == "cancel" then
                loadPending = false
                return "Load canceled."
            else
                saveName = command
                if not table.contains(save_load.getSaves(), saveName) then
                    return "Save file not found. Please type a valid save file name."
                else
                    loadConfirmation = true
                    return "Do you want to load the save " .. saveName .. "? Type 'yes' or 'no'."
                end
            end
        end
    end

    if command == "savefiles" then
        save_load.displaySaveFiles()
        return "Use 'exit' to leave or 'delete' to delete a save file."
    end

    if command == "delete" then
        savePending = false
        loadPending = false
        return "Enter the name of the save file you want to delete:"
    end

    if command == "hunt" then
        if player.health <= 0 then
            return "You can't hunt while you're dead."
        end
        encounterPending = true
        local monsterLevel = math.max(1, player.level + math.random(-3, 3))
        monster = math.random() < 0.1 and monsterModule.createRareMonster(monsterLevel) or monsterModule.createMonster(monsterLevel)
        return "You encountered a level " .. monster.level .. " " .. monster.name .. ". Type 'fight' to fight or 'run' to run."
    elseif command == "explore" then
        return Wander(command)
    elseif command == "status" then
        return Commands(command)
    elseif command == "rest" then
        return Commands(command)
    elseif command == "potion" then
        return Commands(command)
    elseif command == "save" then
        savePending = true
        saveConfirmation = true
        return "Are you sure you want to save? Type 'yes' or 'no'."
    elseif command == "load" then
        loadPending = true
        save_load.displaySaveFiles()
        return "Type the name of the save file you want to load."
    elseif command == "restart" then
        return Options(command)
    elseif command == "exit" then
        return Options(command)
    elseif command == "help" then
        return Options(command)
    else
        return "Invalid command. Type 'help' for a list of usable commands."
    end
end

function Wander(command)
    if player.health <= 0 then
        return "You can't explore while you're dead."
    end
    local result = math.random(1, 100)
    if result <= 50 then
        return "You found nothing while exploring."
    elseif result <= 70 then
        local goldFound = math.random(10, 75)
        player.gold = player.gold + goldFound
        return "You found " .. goldFound .. " gold while exploring."
    elseif result <= 90 then
        player.potions = player.potions + 1
        return "You found a potion while exploring."
    else
        merchantEncounter = true
        return "You encountered a merchant! He offers a great potion for 500 gold 'accept'  or 'decline'?"
    end
end

function Commands(command)
    if command == "status" then
        return "Health: " .. player.health .. "/" .. player.maxHealth .. ", Gold: " .. player.gold .. ", Potions: " .. player.potions .. ", Great Potions: " .. player.greatPotions .. ", Level: " .. player.level .. ", EXP: " .. player.exp .. "/" .. player.expToNextLevel
    elseif command == "rest" then
        if player.health <= 0 then
            return "You can't rest while you're dead."
        end
        local ambushChance = math.random(1, 100)
        if ambushChance <= 30 then
            local ambushDamage = math.random(10, 20)
            player.health = player.health - ambushDamage
            return "While resting, you were ambushed and took " .. ambushDamage .. " damage!"
        else
            player.health = math.min(player.maxHealth, player.health + math.random(10, 20))
            return "You rested and restored some health."
        end
    elseif command == "potion" then
        if player.health <= 0 then
            return "You can't use a potion while you're dead."
        end
        if player.potions > 0 then
            player.health = math.min(player.maxHealth, player.health + 30)
            player.potions = player.potions - 1
            return "You drank a potion and restored 30 health."
        else
            return "You don't have any potions."
        end
    elseif command == "great potion" then
        if player.health <= 0 then
            return "You can't use a great potion while you're dead."
        end
        if player.greatPotions > 0 then
            player.health = player.maxHealth
            player.greatPotions = player.greatPotions - 1
            return "You drank a great potion and fully restored your health."
        else
            return "You don't have any great potions."
        end
    end
end

function Options(command)
    if command == "restart" then
        player.health = player.maxHealth
        return "You have been revived. Welcome back!"
    elseif command == "exit" then
        love.event.quit()
    elseif command == "help" then
        return "List of usable commands: hunt, rest, explore, potion, status, save, load, restart, and exit"
    end
end

return handleCommand
