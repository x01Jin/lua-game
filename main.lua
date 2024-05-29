local love = require("love")

local player = {
    health = 100,
    maxHealth = 100,
    gold = 0,
    potions = 0,
    level = 1,
    exp = 0,
    expToNextLevel = 100,
    attackMin = 20,
    attackMax = 30
}

local monsterTemplate = {
    name = "Monster",
    baseAttackMin = 3,
    baseAttackMax = 5
}

local monster
local combatLog = {}
local combatTimer = 0
local combatInProgress = false
local combatTurn = 1
local playerHealth
local monsterHealth

local encounterPending = false
local merchantEncounter = false
local history = {}
local input = ""
local logScroll = 0
local logHeight = 400
local font

local function startCombat()
    playerHealth = player.health
    monsterHealth = monster.health
    combatLog = {}
    combatTimer = 0
    combatInProgress = true
    combatTurn = 1
end

local function combatTurnStep()
    if playerHealth > 0 and monsterHealth > 0 then
        local playerAttack = math.random(player.attackMin, player.attackMax)
        local monsterAttack = math.random(monster.attackMin, monster.attackMax)

        monsterHealth = monsterHealth - playerAttack
        playerHealth = playerHealth - monsterAttack

        table.insert(combatLog, "Turn " .. combatTurn .. ":")
        table.insert(combatLog, "Player dealt " .. playerAttack .. " damage, Monster dealt " .. monsterAttack .. " damage")
        table.insert(combatLog, "Player HP: " .. playerHealth .. "/" .. player.maxHealth .. ", Monster HP: " .. monsterHealth .. "/" .. monster.health)
        combatTurn = combatTurn + 1
    end

    if playerHealth <= 0 or monsterHealth <= 0 then
        combatInProgress = false
        if playerHealth <= 0 then
            local goldLoss = math.random(20, 40)
            player.gold = player.gold - goldLoss
            table.insert(combatLog, "Player was defeated by the " .. monster.name .. " and lost " .. goldLoss .. " gold.")
        else
            player.health = playerHealth
            local goldWon = math.random(30, 50)
            player.gold = player.gold + goldWon
            local expGained = math.max(10, (monster.level - player.level + 3) * 10)
            player.exp = player.exp + expGained
            table.insert(combatLog, "Player won and gained " .. goldWon .. " gold and " .. expGained .. " EXP.")
            if math.random() < 0.4 then
                player.potions = player.potions + 1
                table.insert(combatLog, "Player found a potion.")
            end

            if player.exp >= player.expToNextLevel then
                player.level = player.level + 1
                player.exp = player.exp - player.expToNextLevel
                player.expToNextLevel = player.expToNextLevel + 50
                player.maxHealth = player.maxHealth + 20
                player.health = player.maxHealth
                player.attackMin = player.attackMin + 2
                player.attackMax = player.attackMax + 3
                table.insert(combatLog, "Player leveled up to level " .. player.level .. "!")
            end
        end
        player.health = math.max(0, playerHealth)
    end
end

local function handleCommand(command)
    if combatInProgress then
        return "Combat is in progress. Finish the fight first."
    end

    if encounterPending then
        if command == "fight" then
            encounterPending = false
            startCombat()
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
                player.potions = player.potions + 1
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

    if command == "hunt" then
        if player.health <= 0 then
            return "You can't hunt while you're dead."
        end
        encounterPending = true
        local monsterLevel
        if player.level < 2 then
            monsterLevel = 0
        else
            if math.random() <= 0.7 then
                monsterLevel = math.random(math.max(1, player.level - 3), player.level + 3)
            else
                monsterLevel = player.level + math.random(1, 3)
            end
        end
        monster = {
            name = monsterTemplate.name,
            level = monsterLevel,
            health = 100,
            attackMin = monsterTemplate.baseAttackMin + monsterLevel * 2,
            attackMax = monsterTemplate.baseAttackMax + monsterLevel * 2
        }
        return "You encountered a level " .. monsterLevel .. " " .. monster.name .. ". Type 'fight' to fight or 'run' to run."
    elseif command == "explore" then
        return Wander(command)
    elseif command == "status" then
        return Commands(command)
    elseif command == "rest" then
        return Commands(command)
    elseif command == "potion" then
        return Commands(command)
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
        return "Health: " .. player.health .. "/" .. player.maxHealth .. ", Gold: " .. player.gold .. ", Potions: " .. player.potions .. ", Level: " .. player.level .. ", EXP: " .. player.exp .. "/" .. player.expToNextLevel
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
    end
end

function Options(command)
    if command == "restart" then
        player.health = player.maxHealth
        return "You have been revived. Welcome back!"
    elseif command == "exit" then
        love.event.quit()
    elseif command == "help" then
        return "List of usable commands: hunt, rest, explore, potion, status, restart, and exit"
    end
end

function love.load()
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)
    logHeight = love.graphics.getHeight() - 100
    input = ""
    history = {}
    logScroll = 0
    combatInProgress = false
    combatTimer = 0
    combatLog = {}
end

function love.update(dt)
    if combatInProgress then
        combatTimer = combatTimer + dt
        if combatTimer >= 1 then
            combatTimer = 0
            combatTurnStep()
            for _, log in ipairs(combatLog) do
                table.insert(history, log)
            end
            combatLog = {}
        end
    end
end

function love.draw()
    -- Draw the logs box
    local logBoxX = 10
    local logBoxY = 10
    local logBoxWidth = love.graphics.getWidth() - 20
    local logBoxHeight = logHeight

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", logBoxX, logBoxY, logBoxWidth, logBoxHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setScissor(logBoxX, logBoxY, logBoxWidth, logBoxHeight)
    love.graphics.push()
    love.graphics.translate(0, -logScroll)

    local lineHeight = font:getHeight() + 5
    local textWidth = logBoxWidth - 20

    local totalLogHeight = #history * lineHeight

    for i, log in ipairs(history) do
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("line", logBoxX, logBoxY + logBoxHeight - totalLogHeight + (i - 1) * lineHeight, logBoxWidth, lineHeight)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(log, logBoxX + 5, logBoxY + logBoxHeight - totalLogHeight + (i - 1) * lineHeight, textWidth)
    end

    love.graphics.pop()
    love.graphics.setScissor()

    -- Draw the text input box
    local inputBoxX = 10
    local inputBoxY = love.graphics.getHeight() - 50
    local inputBoxWidth = love.graphics.getWidth() - 20
    local inputBoxHeight = 40

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", inputBoxX, inputBoxY, inputBoxWidth, inputBoxHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("> " .. input, inputBoxX + 5, inputBoxY + 5, inputBoxWidth - 10)
end

function love.keypressed(key)
    if key == "return" and not combatInProgress then
        table.insert(history, handleCommand(input))
        input = ""
    elseif key == "backspace" then
        input = input:sub(1, -2)
    end
end

function love.textinput(t)
    input = input .. t
end
