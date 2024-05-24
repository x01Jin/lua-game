local monsterTemplate = {
    name = "Monster",
    baseAttackMin = 3,
    baseAttackMax = 5
}

local function createMonster(level)
    return {
        name = "Monster",
        level = level,
        health = 100,
        attackMin = monsterTemplate.baseAttackMin + level * 2,
        attackMax = monsterTemplate.baseAttackMax + level * 2
    }
end

local function createRareMonster(level)
    return {
        name = "Rare Monster",
        level = level,
        health = 200,
        attackMin = monsterTemplate.baseAttackMin + level * 3,
        attackMax = monsterTemplate.baseAttackMax + level * 3,
        isRare = true
    }
end

return {
    createMonster = createMonster,
    createRareMonster = createRareMonster
}
