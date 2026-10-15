package.preload["ISUI/ISPanelJoypad"] = function() return true end
package.preload["ISUI/ISBackButtonWheel"] = function() return true end

ISPanelJoypad = {}
function ISPanelJoypad:derive(name)
    local class = { Type = name, SuperType = self }
    setmetatable(class, { __index = self })
    class.__index = class
    return class
end
function ISPanelJoypad:new(x, y, width, height)
    return setmetatable({ x=x, y=y, width=width, height=height, visible=false }, { __index=self })
end
function ISPanelJoypad:initialise() end
function ISPanelJoypad:setVisible(value) self.visible=value end
function ISPanelJoypad:getIsVisible() return self.visible end
function ISPanelJoypad:addToUIManager() self.added=true end
function ISPanelJoypad:removeFromUIManager() self.added=false end
function ISPanelJoypad:setX(value) self.x=value end
function ISPanelJoypad:setY(value) self.y=value end
function ISPanelJoypad:prerender() end
function ISPanelJoypad:drawRect() end
function ISPanelJoypad:drawRectBorder() end
function ISPanelJoypad:drawText() end
function ISPanelJoypad:drawTextureScaled() end

ISBackButtonWheel = { slices={} }
function ISBackButtonWheel:addCommands() self.slices={} end
function ISBackButtonWheel:addSlice(text, texture, callback, argument)
    self.slices[#self.slices+1] = {text=text,texture=texture,callback=callback,argument=argument}
end

Joypad = { AButton=1, BButton=2, Back=9 }
local hungry = { id="HUNGRY" }
local thirst = { id="THIRST" }
MoodleType = { HUNGRY=hungry, THIRST=thirst }

local levels = { [hungry]=2, [thirst]=1 }
local moodles = {}
function moodles:getMoodleLevel(moodleType) return levels[moodleType] or 0 end
function moodles:getMoodleDisplayString(moodleType) return moodleType.id .. " title" end
function moodles:getMoodleDescriptionString(moodleType) return moodleType.id .. " description" end
function moodles:getGoodBadNeutral() return 2 end

local player = { getMoodles=function() return moodles end }
getSpecificPlayer = function(index) if index==0 then return player end end
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return 1920 end
getPlayerScreenHeight = function() return 1080 end

local mouseX, mouseY = 1810, 12
getMouseX = function() return mouseX end
getMouseY = function() return mouseY end
local moodleUI = {
    getAbsoluteX=function() return 1800 end,
    getAbsoluteY=function() return 10 end,
    getWidth=function() return 48 end,
    isReallyVisible=function() return true end,
}
UIManager = { getMoodleUI=function(index) assert(index==0); return moodleUI end }
getTexture = function(path) return {path=path} end
getText = function(key) return key end
UIFont = { Large="large", Small="small" }
getTextManager = function()
    return {
        MeasureStringX=function(_,_,text) return #text * 7 end,
        getFontHeight=function() return 14 end,
    }
end

local focus = nil
setJoypadFocus = function(index, target) assert(index==0); focus=target end
getJoypadFocus = function(index) assert(index==0); return focus end

local tick = nil
Events = { OnTick={Add=function(callback) tick=callback end} }

assert(loadfile("Contents/mods/ZomboidMoodleFocus/42/media/lua/client/ZMF_MoodleFocus.lua"))()
assert(type(tick)=="function")

local wheel = setmetatable({playerNum=0,slices={}}, {__index=ISBackButtonWheel})
wheel:addCommands()
assert(#wheel.slices==1 and wheel.slices[1].text=="UI_ZMF_Radial")
wheel.slices[1].callback(wheel.slices[1].argument)

local panel = ZMF.panels[0]
assert(panel and panel.controllerMode and panel.visible and focus==panel)
panel:refreshMoodles()
assert(#panel.activeMoodles==2 and panel.activeMoodles[1].moodleType==hungry)
panel:onJoypadDirDown()
assert(panel.selected==2)
panel:onJoypadDirUp()
assert(panel.selected==1)
panel:onJoypadDown(Joypad.BButton)
assert(not panel.visible and not panel.controllerMode and focus==nil)

tick()
assert(panel.visible and panel.hoverMode and panel.selected==1)
mouseX=100
tick()
assert(not panel.visible and not panel.hoverMode)

print("OK: radial entry, controller cycling, close behavior and mouse hover card")
