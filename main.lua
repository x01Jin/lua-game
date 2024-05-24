local love = require("love")
local player = require("player")
local save_load = require("save_load")
local combat = require("combat")
local handleCommand = require("commands")

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
    if combat.isInProgress() then
        combatTimer = combatTimer + dt
        if combatTimer >= 1 then
            combatTimer = 0
            combat.turnStep(monster)
            for _, log in ipairs(combat.getLog()) do
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
    if key == "return" and not combat.isInProgress() then
        table.insert(history, handleCommand(input))
        input = ""
    elseif key == "backspace" then
        input = input:sub(1, -2)
    end
end

function love.textinput(t)
    input = input .. t
end
