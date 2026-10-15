-- Zomboid Moodle Focus v0.1.0 for Project Zomboid Build 42.
-- Mouse hover shows a large moodle card. Controller access is deliberately
-- routed through the existing Back/View radial menu so no gameplay D-pad
-- binding is replaced.
require "ISUI/ISPanelJoypad"
require "ISUI/ISBackButtonWheel"

ZMF = ZMF or {}
ZMF.version = "0.1.0"
ZMF.panels = ZMF.panels or {}

local PANEL_WIDTH = 470
local PANEL_HEIGHT = 168
local LARGE_ICON = 96

-- This order mirrors zombie.ui.MoodleTextureSet in Build 42. The texture
-- filenames come from that shipped class; MoodleType and text remain vanilla.
local MOODLES = {
    { key = "ENDURANCE",     icon = "Status_DifficultyBreathing" },
    { key = "TIRED",         icon = "Mood_Sleepy" },
    { key = "HUNGRY",        icon = "Status_Hunger" },
    { key = "PANIC",         icon = "Mood_Panicked" },
    { key = "SICK",          icon = "Mood_Nauseous" },
    { key = "BORED",         icon = "Mood_Bored" },
    { key = "UNHAPPY",       icon = "Mood_Sad" },
    { key = "BLEEDING",      icon = "Status_Bleeding" },
    { key = "WET",           icon = "Status_Wet" },
    { key = "HAS_A_COLD",    icon = "Mood_Ill" },
    { key = "ANGRY",         icon = "Mood_Angry" },
    { key = "STRESS",        icon = "Mood_Stressed" },
    { key = "THIRST",        icon = "Status_Thirst" },
    { key = "INJURED",       icon = "Status_InjuredMinor" },
    { key = "PAIN",          icon = "Mood_Pained" },
    { key = "HEAVY_LOAD",    icon = "Status_HeavyLoad" },
    { key = "DRUNK",         icon = "Mood_Drunk" },
    { key = "DEAD",          icon = "Mood_Dead" },
    { key = "ZOMBIE",        icon = "Mood_Zombified" },
    { key = "NOXIOUS_SMELL", icon = "Mood_NoxiousSmell" },
    -- Build 42 reuses the hunger artwork for the positive Well Fed moodle.
    { key = "FOOD_EATEN",    icon = "Status_Hunger" },
    { key = "HYPERTHERMIA",  icon = "Status_TemperatureHot" },
    { key = "HYPOTHERMIA",   icon = "Status_TemperatureLow" },
    { key = "WINDCHILL",     icon = "Status_Windchill" },
    { key = "CANT_SPRINT",   icon = "Status_MovementRestricted" },
    { key = "UNCOMFORTABLE", icon = "Mood_Discomfort" },
}

local ICON_SIZES = { 128, 112, 96, 80, 64, 48, 32 }
local textureCache = {}

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function playerFor(playerNum)
    if not getSpecificPlayer then return nil end
    return getSpecificPlayer(playerNum)
end

local function textureFor(entry)
    if textureCache[entry.icon] ~= nil then
        return textureCache[entry.icon] or nil
    end
    local texture = nil
    for _, size in ipairs(ICON_SIZES) do
        local path = "media/ui/Moodles/" .. size .. "/" .. entry.icon .. ".png"
        texture = safeCall(function() return getTexture(path) end, nil)
        if texture then break end
    end
    textureCache[entry.icon] = texture or false
    return texture
end

local function activeMoodles(playerNum)
    local player = playerFor(playerNum)
    local moodles = player and player:getMoodles()
    local result = {}
    if not moodles or not MoodleType then return result end

    for _, definition in ipairs(MOODLES) do
        local moodleType = safeCall(function() return MoodleType[definition.key] end, nil)
        local level = moodleType and safeCall(function()
            return moodles:getMoodleLevel(moodleType)
        end, 0) or 0
        if level and level > 0 then
            result[#result + 1] = {
                definition = definition,
                moodleType = moodleType,
                level = level,
                title = safeCall(function()
                    return moodles:getMoodleDisplayString(moodleType)
                end, definition.key),
                description = safeCall(function()
                    return moodles:getMoodleDescriptionString(moodleType)
                end, ""),
                goodBadNeutral = safeCall(function()
                    return moodles:getGoodBadNeutral(moodleType)
                end, 0),
            }
        end
    end
    return result
end

local function wrapText(text, font, maxWidth)
    local lines = {}
    text = tostring(text or ""):gsub("<br>", "\n")
    for paragraph in (text .. "\n"):gmatch("(.-)\n") do
        local line = ""
        for word in paragraph:gmatch("%S+") do
            local candidate = line == "" and word or (line .. " " .. word)
            local width = getTextManager():MeasureStringX(font, candidate)
            if width > maxWidth and line ~= "" then
                lines[#lines + 1] = line
                line = word
            else
                line = candidate
            end
        end
        if line ~= "" then lines[#lines + 1] = line end
    end
    return lines
end

ZMFMoodlePanel = ISPanelJoypad:derive("ZMFMoodlePanel")

function ZMFMoodlePanel:refreshMoodles()
    self.activeMoodles = activeMoodles(self.playerNum)
    if #self.activeMoodles == 0 then
        self.selected = 1
    else
        self.selected = math.max(1, math.min(self.selected or 1, #self.activeMoodles))
    end
end

function ZMFMoodlePanel:positionNearMoodles(rowIndex)
    local screenLeft = getPlayerScreenLeft(self.playerNum)
    local screenTop = getPlayerScreenTop(self.playerNum)
    local screenWidth = getPlayerScreenWidth(self.playerNum)
    local screenHeight = getPlayerScreenHeight(self.playerNum)
    local moodleUI = UIManager and UIManager.getMoodleUI and UIManager.getMoodleUI(self.playerNum)
    local moodleX = moodleUI and safeCall(function() return moodleUI:getAbsoluteX() end,
        screenLeft + screenWidth - 64) or (screenLeft + screenWidth - 64)
    local moodleY = moodleUI and safeCall(function() return moodleUI:getAbsoluteY() end,
        screenTop + 24) or (screenTop + 24)
    local iconSize = moodleUI and safeCall(function() return moodleUI:getWidth() end, 48) or 48
    if iconSize < 24 or iconSize > 160 then iconSize = 48 end
    local pitch = iconSize + 10
    local x = math.max(screenLeft + 8, moodleX - PANEL_WIDTH - 14)
    local y = moodleY + ((rowIndex or 1) - 1) * pitch
    y = math.max(screenTop + 8, math.min(y, screenTop + screenHeight - PANEL_HEIGHT - 8))
    self:setX(x)
    self:setY(y)
end

function ZMFMoodlePanel:prerender()
    self:refreshMoodles()
    ISPanelJoypad.prerender(self)

    if #self.activeMoodles == 0 then
        self:drawText(getText("UI_ZMF_NoActive"), 18, 22, 1, 1, 1, 1, UIFont.Large)
        if self.controllerMode then
            self:drawText(getText("UI_ZMF_ControllerHint"), 18, self.height - 27,
                0.75, 0.75, 0.75, 1, UIFont.Small)
        end
        return
    end

    local moodle = self.activeMoodles[self.selected]
    local texture = textureFor(moodle.definition)
    self:drawRect(12, 18, LARGE_ICON + 8, LARGE_ICON + 8, 0.45, 0.05, 0.05, 0.05)
    self:drawRectBorder(12, 18, LARGE_ICON + 8, LARGE_ICON + 8, 0.9, 0.75, 0.75, 0.75)
    if texture then
        self:drawTextureScaled(texture, 16, 22, LARGE_ICON, LARGE_ICON, 1, 1, 1, 1)
    end

    local textX = 132
    self:drawText(tostring(moodle.title), textX, 18, 1, 1, 1, 1, UIFont.Large)
    self:drawText(tostring(self.selected) .. " / " .. tostring(#self.activeMoodles),
        self.width - 62, 21, 0.72, 0.72, 0.72, 1, UIFont.Small)

    local lines = wrapText(moodle.description, UIFont.Small, self.width - textX - 16)
    local lineHeight = getTextManager():getFontHeight(UIFont.Small) + 2
    for index = 1, math.min(#lines, 5) do
        self:drawText(lines[index], textX, 51 + (index - 1) * lineHeight,
            0.9, 0.9, 0.9, 1, UIFont.Small)
    end

    if self.controllerMode then
        self:drawText(getText("UI_ZMF_ControllerHint"), 14, self.height - 25,
            0.75, 0.75, 0.75, 1, UIFont.Small)
    end
end

function ZMFMoodlePanel:onJoypadDirUp()
    self:refreshMoodles()
    if #self.activeMoodles == 0 then return end
    self.selected = self.selected - 1
    if self.selected < 1 then self.selected = #self.activeMoodles end
    self:positionNearMoodles(self.selected)
end

function ZMFMoodlePanel:onJoypadDirDown()
    self:refreshMoodles()
    if #self.activeMoodles == 0 then return end
    self.selected = self.selected + 1
    if self.selected > #self.activeMoodles then self.selected = 1 end
    self:positionNearMoodles(self.selected)
end

function ZMFMoodlePanel:closeController()
    self.controllerMode = false
    self.hoverMode = false
    self:setVisible(false)
    self:removeFromUIManager()
    if getJoypadFocus and getJoypadFocus(self.playerNum) == self then
        setJoypadFocus(self.playerNum, nil)
    end
end

function ZMFMoodlePanel:onJoypadDown(button)
    if button == Joypad.AButton or button == Joypad.BButton or button == Joypad.Back then
        self:closeController()
    end
end

function ZMFMoodlePanel:new(playerNum)
    local o = ISPanelJoypad:new(0, 0, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum
    o.selected = 1
    o.activeMoodles = {}
    o.controllerMode = false
    o.hoverMode = false
    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.88 }
    o.borderColor = { r = 0.72, g = 0.72, b = 0.72, a = 0.95 }
    o.moveWithMouse = false
    return o
end

local function panelFor(playerNum)
    local panel = ZMF.panels[playerNum]
    if panel then return panel end
    panel = ZMFMoodlePanel:new(playerNum)
    panel:initialise()
    panel:setVisible(false)
    ZMF.panels[playerNum] = panel
    return panel
end

function ZMF.openForPlayer(playerNum)
    local panel = panelFor(playerNum)
    panel.controllerMode = true
    panel.hoverMode = false
    panel:refreshMoodles()
    panel:positionNearMoodles(panel.selected)
    panel:addToUIManager()
    panel:setVisible(true)
    setJoypadFocus(playerNum, panel)
end

local function hoveredMoodle(playerNum, active)
    if #active == 0 or not getMouseX or not getMouseY then return nil end
    local moodleUI = UIManager and UIManager.getMoodleUI and UIManager.getMoodleUI(playerNum)
    if not moodleUI then return nil end
    local visible = safeCall(function() return moodleUI:isReallyVisible() end, true)
    if visible == false then return nil end

    local x = safeCall(function() return moodleUI:getAbsoluteX() end, nil)
    local y = safeCall(function() return moodleUI:getAbsoluteY() end, nil)
    local size = safeCall(function() return moodleUI:getWidth() end, 48)
    if x == nil or y == nil then return nil end
    if size < 24 or size > 160 then size = 48 end

    local mouseX = getMouseX()
    local mouseY = getMouseY()
    if mouseX < x - 4 or mouseX > x + size + 4 or mouseY < y then return nil end
    local pitch = size + 10
    local relativeY = mouseY - y
    local index = math.floor(relativeY / pitch) + 1
    local insideRow = relativeY - (index - 1) * pitch
    if index < 1 or index > #active or insideRow > size + 4 then return nil end
    return index
end

function ZMF.onTick()
    -- Mouse is a single shared cursor, so hover belongs to player zero. Other
    -- local players still use the radial/controller path independently.
    local panel = panelFor(0)
    if panel.controllerMode then return end

    local active = activeMoodles(0)
    local index = hoveredMoodle(0, active)
    if index then
        panel.activeMoodles = active
        panel.selected = index
        panel.hoverMode = true
        panel:positionNearMoodles(index)
        if not panel:getIsVisible() then
            panel:addToUIManager()
            panel:setVisible(true)
        end
    elseif panel.hoverMode then
        panel.hoverMode = false
        panel:setVisible(false)
        panel:removeFromUIManager()
    end
end

-- Extend the existing Back/View wheel instead of replacing any D-pad input.
if not ZMF.wheelAddHook then
    ZMF.previousWheelAddCommands = ISBackButtonWheel.addCommands
    ZMF.wheelAddHook = function(self, ...)
        ZMF.previousWheelAddCommands(self, ...)
        local icon = textureFor(MOODLES[3]) or getTexture("media/ui/Heart2_On.png")
        self:addSlice(getText("UI_ZMF_Radial"), icon, ZMF.openForPlayer, self.playerNum)
    end
    ISBackButtonWheel.addCommands = ZMF.wheelAddHook
end

if Events and Events.OnTick then Events.OnTick.Add(ZMF.onTick) end
print("[ZomboidMoodleFocus] v" .. ZMF.version .. " hover card and Back/View radial entry installed")
