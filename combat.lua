local combat = {}
local player = require("player")
local monsterModule = require("monster")

local combatLog = {}
local combatTimer = 0
local combatInProgress = false
local combatTurn = 1
local playerHealth
local monsterHealth

function combat.start(monster)
    playerHealth = player.health
    monsterHealth = monster.health
    combatLog = {}
    combatTimer = 0
    combatInProgress = true
    combatTurn = 1
end

function combat.turnStep(monster)
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

function combat.isInProgress()
    return combatInProgress
end

function combat.getLog()
    return combatLog
end

return combat
