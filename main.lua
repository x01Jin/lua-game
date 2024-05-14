-- soriano alexander james
-- 
local player = {
    health = 100,
    maxHealth = 100,
    gold = 0,
    potions = 0,
    level = 1,
    exp = 0,
    expToNextLevel = 100,
    attackMin = 10,
    attackMax = 20
}

-- si bogart
local monsterTemplate = {
    name = "Goblin",
    baseAttackMin = 8,
    baseAttackMax = 15
}

local monster
local combatLog = {}
local combatTimer = 0
local combatInProgress = false
local combatTurn = 1
local playerHealth
local monsterHealth

local encounterPending = false
local history = {}
local input = ""
local logScroll = 0
local logHeight = 400

-- reset shit
local function startCombat()
    playerHealth = player.health
    monsterHealth = monster.health
    combatLog = {}
    combatTimer = 0
    combatInProgress = true
    combatTurn = 1
end

-- turn based functionality
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
            player.health = playerHealth -- Update player's health after fucking
            local goldWon = math.random(30, 50)
            player.gold = player.gold + goldWon
            local expGained = math.max(10, (monster.level - player.level + 3) * 10)
            player.exp = player.exp + expGained
            table.insert(combatLog, "Player won and gained " .. goldWon .. " gold and " .. expGained .. " EXP.")
            if math.random() < 0.4 then
                player.potions = player.potions + 1
                table.insert(combatLog, "Player found a potion.")
            end

            -- Check for level up shit
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

        -- Update player's health after fuckery
        player.health = math.max(0, playerHealth)
    end
end

-- the fucking commands 
local function handleCommand(command)
    if command == "hunt" then
        if player.health <= 0 then
            return "You can't hunt while you're dead."
        end
        encounterPending = true
        local monsterLevel
        if player.level < 3 then
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
    elseif command == "fight" then
        if not encounterPending then
            return "There is no monster to fight."
        end
        encounterPending = false
        startCombat()
        return "Combat started against level " .. monster.level .. " " .. monster.name .. "!"
    elseif command == "run" then
        if not encounterPending then
            return "There is no monster to run from."
        end
        encounterPending = false
        return "You ran away from the level " .. monster.level .. " " .. monster.name .. "."
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
    elseif command == "explore" then
        if player.health <= 0 then
            return "You can't explore while you're dead."
        end
        local result = math.random(1, 100)
        if result <= 50 then
            return "You found nothing while exploring."
        elseif result <= 70 then
            local goldFound = math.random(10, 30)
            player.gold = player.gold + goldFound
            return "You found " .. goldFound .. " gold while exploring."
        elseif result <= 90 then
            player.potions = player.potions + 1
            return "You found a potion while exploring."
        else
            return "You encountered a merchant while exploring. Type 'accept' to buy a great potion for 500 gold or 'decline' to continue exploring."
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
    elseif command == "status" then
        return "Health: " .. player.health .. "/" .. player.maxHealth .. ", Gold: " .. player.gold .. ", Potions: " .. player.potions .. ", Level: " .. player.level .. ", EXP: " .. player.exp .. "/" .. player.expToNextLevel
    elseif command == "accept" then
        if player.gold >= 500 then
            player.gold = player.gold - 500
            player.potions = player.potions + 1
            return "You bought a great potion for 500 gold."
        else
            return "You don't have enough gold to buy the great potion."
        end
    elseif command == "decline" then
        return "You declined the merchant's offer."
    elseif command == "restart" then
        player.health = player.maxHealth
        return "You have been revived. Welcome back!"
    elseif command == "exit" then
        love.event.quit()
    elseif command == "help" then
        return "List of usable commands: hunt, fight, run, rest, explore, potion, status, accept, decline, restart, exit.\nInstructions: Hunt monsters based on your level, fight or run from encounters, rest to heal or get ambushed, explore for rewards, use potions for health, manage gold, and interact with merchants."
    else
        return "Invalid command."
    end
end

-- Love2D shittery
function love.load()
    love.graphics.setFont(love.graphics.newFont(14))
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
            -- Auto-scroll to the bottom (but still shit, needs fixing)
            logScroll = math.max(0, #history * 20 - logHeight)
        end
    end
end

function love.draw()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, 10, love.graphics.getWidth() - 20, logHeight)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setScissor(10, 10, love.graphics.getWidth() - 20, logHeight)
    love.graphics.push()
    love.graphics.translate(0, -logScroll)
    love.graphics.printf(table.concat(history, "\n"), 15, 15, love.graphics.getWidth() - 30)
    love.graphics.pop()
    love.graphics.setScissor()

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, love.graphics.getHeight() - 50, love.graphics.getWidth() - 20, 40)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("> " .. input, 15, love.graphics.getHeight() - 40, love.graphics.getWidth() - 30)
end

function love.keypressed(key)
    if key == "return" and not combatInProgress then
        table.insert(history, handleCommand(input))
        input = ""
        logScroll = math.max(0, #history * 20 - logHeight)
    elseif key == "backspace" then
        input = input:sub(1, -2)
    elseif key == "up" then
        logScroll = math.max(0, logScroll - 20)
    elseif key == "down" then
        logScroll = math.min(#history * 20 - logHeight, logScroll + 20)
    end
end

function love.textinput(t)
    input = input .. t
end
