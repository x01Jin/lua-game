function Combat(command)
    if command == "hunt" then
        if encounterPending ==true then
            return "You can only use 'fight' or 'run' in this state."
        elseif player.health <= 0 then
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
    elseif encounterPending == true then
        return "You can only use 'fight' or 'run' in this state."
    end
end

function Wander(command)
    if command == "explore" then
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
            return "You encountered a merchant! Type 'accept' 500 gold - great potion or 'decline' to continue exploring."
        end
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
