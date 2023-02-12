------------------------------------------------------------------
--  IClicker, audible indicators lua app for ac by Halvhjearne    --
------------------------------------------------------------------
--  this is a free app and may not be used in any commercial    --
--  way without written permission from Halvhjearne                --
------------------------------------------------------------------

-- hard set defaults if no defaults are saved yet (pls only change values or script will break)
local settings = {
    Volume = 0.2, -- from 0.0 to 1.0 above or under will be reset to 0.2
    Delay = 0.357, -- from 0.1 to 0.7 above or under will be reset to 0.357
    playRate = 1, -- will always be reset to 1 for now
    EnableSync = false, -- true / false
    EnableWip = true,
    EnableHB = true,
    EnableEA = false,
    EnableEB = false,
    EnableEC = false,
    EnableED = false,
    EnableEE = false,
    EnableEF = false,
    EnableDebug = false
}

--[[
-------------------------------------------------------------------------------------------------
|    To add/change sound files and menu names:                                                   |
|                                                                                                |
|    The script is intended to use very small/short sound clips, so dont try to add sound clips  |
|    that are too long.                                                                          |
|    First add an ON and an OFF sound to SFiles table, then add the name you want shown in the   |
|    dropdowns under NAME and it should show up.                                                 |
|                                                                                                |
|    Dont forget to keep the index sequential.                                                   |
|                                                                                                |
|    Most formats will work like flac, ogg and many others, but some systems may only support    |
|    wav and mp3.                                                                                |
-------------------------------------------------------------------------------------------------
--]]

-- names of ON and Off sound files incl. extension (.wav, .mp3, .flac, .ogg etc)
local SFiles = {
    -- added part for no soundfx
    [0] = {
        ON = '',
        OFF = '',
        NAME = 'None',
    },
    -- here we set same a number, make sure to keep it sequential.
    [1] = {  -- here we can add the filename of the ON sound file
        ON = 'defaulton.flac',
              -- here we can add the filename of the OFF sound file
        OFF = 'defaultoff.flac',
               -- here we add the name we want to shown in the menu
        NAME = 'Default'
    },
    [2] = {
        ON = '2GENERICon.flac',
        OFF = '2GENERICoff.flac',
        NAME = 'Generic'
    },
    [3] = {
        ON = 'audion.flac',
        OFF = 'audioff.flac',
        NAME = 'Audi'
    },
    [4] = {
        ON = 'fordfocuson.flac',
        OFF = 'fordfocusoff.flac',
        NAME = 'Ford Focus'
    },
    [5] = {
        ON = 'opelcorsaon.flac',
        OFF = 'opelcorsaoff.flac',
        NAME = 'Opel Corsa'
    },
    [6] = {
        ON = 'BUSon.flac',
        OFF = 'BUSoff.flac',
        NAME = 'Bus',
    },
}

--[[
-------------------------------------------------------------------------------------------------
|    Dont change anything below this point (unless you know what you are doing)                    |
-------------------------------------------------------------------------------------------------
--]]

local soundNames = {}
local sndfxnum = 0
for i in pairs(SFiles) do
    soundNames[i] = SFiles[i].NAME
    sndfxnum = sndfxnum+1
end

local SFileVals = {
    Turn = 1,
    Wiper = 1,
    HB = 1,
    EA = 1,
    EB = 1,
    EC = 1,
    ED = 1,
    EE = 1,
    EF = 1
}

-- dont run on old version of csp
local vercode = ac.getPatchVersionCode()
if vercode < 2000 then
    return nil
end

--dont run for cars with no ext_config.ini
if not io.fileExists(ac.getFolder(ac.FolderID.ContentCars)..'/'..ac.getCarID(0)..'/extension/ext_config.ini') then
    if not io.fileExists(ac.getFolder(ac.FolderID.ExtCfgSys)..'/cars/loaded/'..ac.getCarID(0)..'.ini') then
        return nil
    end
end

local dir = ac.getFolder(ac.FolderID.Documents)..'/Assetto Corsa/cfg/extension/iclicker'
local filename = dir..'/cars/'..ac.getCarID(0)..'.cfg'
local defaultsfilename = dir..'/defaults.cfg'


local loadfile = ''
if io.fileExists(defaultsfilename) then
    loadfile = defaultsfilename
end
if io.fileExists(filename) then
    loadfile = filename
end
if loadfile ~= '' then
    local data = ac.INIConfig.load(loadfile)
    for k,v in pairs(settings) do
        settings[k] = data:get('DEFAULTS', k, v)
    end
    for k,v in pairs(SFileVals) do
        SFileVals[k] = data:get('SOUNDS', k, v)
    end
end

local counter = 0
local timeVar = -1

local doClickOff = {
    Turn = false,
    Wiper = false,
    HB = false,
    EA = false,
    EB = false,
    EC = false,
    ED = false,
    EE = false,
    EF = false,
    Test = false
}

--checks for possible value problems and resets them in case they are "out of bounds"
--if settings.playRate > 0.2 or settings.playRate < 1 then
if settings.playRate ~= 1 then
    settings.playRate = 1
end
if settings.Volume > 1 or settings.Volume < 0 then
    settings.Volume = 0.2
end
if settings.Delay > 0.7 or settings.Delay < 0.1 then
    settings.Delay = 0.357
end

local valerrTxt = ''
local savedTxt = ''
local allgood = true
for key, value in pairs(SFileVals) do
    if value > sndfxnum or value < 0 then
        SFileVals[key] = 1
        allgood = false
        valerrTxt = valerrTxt+tostring(key)..' = '..tostring(value)..'?\n'
    end
end

local car = ac.getCar(0)
local TESTdropdown = 1

-- prevent first click delay?
ui.MediaPlayer():setAutoPlay(true):setVolume(0)
--if not myPlayer:supportedAsync() then
--    savedTxt = 'OS does not support the media player!'
--end

local function fncPlayMedia (Sfile,vv,prv)
    if Sfile == '' then return end
    local myPlayer = ui.MediaPlayer():setAutoPlay(true):setVolume(vv)
    myPlayer:setSource(Sfile):setAutoPlay(true):setVolume(vv):setPlaybackRate(prv)
end

local function FncSetAndSave (carFile)
    local theFile = defaultsfilename
    if carFile then
        theFile = filename
    end
    local data = ac.INIConfig.load(theFile)
    settings.Delay = tonumber(string.format("%.4f", settings.Delay))
    settings.Volume = tonumber(string.format("%.4f", settings.Volume))
    if io.fileExists(theFile) then
        io.deleteFile(theFile)
        data = ac.INIConfig.load(theFile)
    else
        if not io.dirExists(dir..'/cars/') then
            io.createDir(dir..'/cars/')
        end
    end
    for k,v in pairs(settings) do
        data:setAndSave('DEFAULTS', k, v)
    end
    for k,v in pairs(SFileVals) do
        data:setAndSave('SOUNDS', k, v)
    end
end
local testvar = true
function script.ICMainSettings(dt)
    ui.icon('IClicker.png', vec2(14,14), rgbm(0, 1, 0, 1))
    ui.sameLine(0, 5)
    ui.header('SoundFX Selector:')
    ui.separator()
    ui.bullet()
    ui.sameLine(0, 15)
    SFileVals.Turn = ui.combo('Indicator FX', SFileVals.Turn, soundNames)
    if settings.EnableWip then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.Wiper = ui.combo('Wiper FX', SFileVals.Wiper, soundNames)
    end
    if settings.EnableHB then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.HB = ui.combo('Highbeam FX', SFileVals.HB, soundNames)
    end
    if settings.EnableEA then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.EA = ui.combo('Extra A FX', SFileVals.EA, soundNames)
    end
    if settings.EnableEB then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.EB = ui.combo('Extra B FX', SFileVals.EB, soundNames)
    end
    if settings.EnableEC then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.EC = ui.combo('Extra C FX', SFileVals.EC, soundNames)
    end
    if settings.EnableED then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.ED = ui.combo('Extra D FX', SFileVals.ED, soundNames)
    end
    if settings.EnableEE then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.EE = ui.combo('Extra E FX', SFileVals.EE, soundNames)
    end
    if settings.EnableEF then
        ui.bullet()
        ui.sameLine(0, 15)
        SFileVals.EF = ui.combo('Extra F FX', SFileVals.EF, soundNames)
    end
    ui.separator()
    ui.bullet()
    ui.sameLine(0, 15)
    TESTdropdown = ui.combo('Test Click FX', TESTdropdown, soundNames)
    if ui.itemHovered() then
        ui.setTooltip('Select a soundFX to test')
    end
    ui.dummy(vec2(2,0))
    ui.sameLine(0, 229)
    if ui.checkbox("Click Test", doClickOff.Test) then
        if ui.keyboardButtonDown(ui.KeyIndex.Control) and ui.keyboardButtonDown(ui.KeyIndex.Shift) then
            settings.EnableDebug = not settings.EnableDebug
        else
            doClickOff.Test = not doClickOff.Test
            local files = SFiles[TESTdropdown]
            if doClickOff.Test then
                fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            else
                fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            end
        end
    end
    if ui.itemHovered() then
        ui.setTooltip('Test selected soundFX')
    end
    ui.separator()
    if settings.EnableDebug then
        settings.playRate = tonumber(string.format("%.2f", (ui.slider('Play rate', settings.playRate*100, 20, 100, 'Rate: %.2f%%')/100)))
        ui.separator()
        for k,v in pairs(SFileVals) do
            local txt = 'Off'
            if doClickOff[k] then
                txt = 'On'
            end
            ui.bulletText(string.format('%s: %s - %s - %s, %s', k, txt, v,SFiles[v].ON,SFiles[v].OFF))
        end
        ui.bulletText('Test: '..tostring(doClickOff.Test))
        ui.bulletText('Counter: '..tonumber(string.format("%.4f", counter)))
        ui.bulletText('car.wiperMode: '..car.wiperMode)
        ui.bulletText('car.wiperMode: '..math.floor(car.wiperMode, 0.1))
--        ui.bulletText('CPU occupancy: '..ac.getSim().cpuOccupancy)
--        ui.bulletText('connected cars: '..tostring(ac.getSim().connectedCars))
        ui.bulletText('SFiles: '..tostring(sndfxnum)..' - SFileVals error: '..tostring(allgood)..'\n'..valerrTxt)
-------------------------------------------------------------------------------
--    testing use of soundbanks
        ui.separator()
        if ui.button('Open driver door') then
            if testvar then
                ac.setDriverDoorOpen(car, true)
                testvar = false
            else
                ac.setDriverDoorOpen(car, false)
                testvar = true
            end
        end
        ui.separator()
        if ui.button('TEST') then
            ac.loadSoundbank("extension/lua/new-modes/economy-run/sfx/nord_altta.bank")
            local sound = ac.AudioEvent("nord_altta/finish", false)
            sound:setPosition(ac.getCameraPosition(), car.look, nil, car.velocity)
            sound.inAutoLoopMode = false
            sound.volume = 0.8
            sound.cameraInteriorMultiplier = 1.0
            sound.cameraExteriorMultiplier = 0.75
            sound.cameraTrackMultiplier = 0.75
            sound:start()
        end
        ui.separator()

--        for index, section in iniConfig:iterate('LIGHT') do
--            print('Color: '..iniConfig:get(section, 'COLOR', 'red'))
--        end
-------------------------------------------------------------------------------
--        ui.bulletText(string.format("car.turningLightsActivePhase: %s", car.turningLightsActivePhase))
    end
end

function script.ICMain(dt)
--ui.windowSize().x
    local Csize = ui.calcItemWidth()
    if Csize < 355 then
        local num = 355
        if Csize > 255 then num = Csize + 100 end
        ui.pushItemWidth(num)
    else
        ui.pushItemWidth(Csize + 100)
    end
    ui.icon('IClicker.png', vec2(14,14), rgbm(0, 1, 0, 1))
    ui.sameLine(0, 5)
    ui.header('Main Settings:')
    ui.separator()
    if ui.checkbox("Sync Clicks to indicator lights", settings.EnableSync) then
--        ac.setMessage('Sync may not work yet','... and it may break the script!')
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableSync = not settings.EnableSync
    end
    if ui.itemHovered() then
        if vercode <= 2076 then ui.setTooltip('Not working yet! (will disable indicator soundFX)') end
    end
    if not settings.EnableSync then
        local delayHz = tonumber(string.format("%.4f", (1/settings.Delay)))
        settings.Delay = ui.slider('Delay/Frequency', settings.Delay, 0.1, 0.7, 'T: %.4fms/F: '..delayHz..'Hz')
        if ui.itemHovered() then
            ui.setTooltip('Delay/Frequency of indicator clicks')
        end
    end
    ui.separator()
    settings.Volume = ui.slider('Volume', settings.Volume*100, 0, 100, 'Volume: %.2f%%')/100
    ui.separator()
    if ui.checkbox("Wiper Clicks", settings.EnableWip) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableWip = not settings.EnableWip
        if doClickOff.Wiper then
            doClickOff.Wiper = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Volume of indicator clicks')
        end
    end
    ui.sameLine(0, 25)
    if ui.checkbox("Highbeam Clicks", settings.EnableHB) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableHB = not settings.EnableHB
        if doClickOff.HB then
            doClickOff.HB = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when highbeams is enabled/disabled')
        end
    end
    if ui.checkbox("Extra A Clicks", settings.EnableEA) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableEA = not settings.EnableEA
        if doClickOff.EA then
            doClickOff.EA = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when Extra A is enabled/disabled')
        end
    end
    ui.sameLine(0, 15)
    if ui.checkbox("Extra B Clicks", settings.EnableEB) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableEB = not settings.EnableEB
        if doClickOff.EB then
            doClickOff.EB = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when Extra B is enabled/disabled')
        end
    end
    ui.sameLine(0, 15)
    if ui.checkbox("Extra C Clicks", settings.EnableEC) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableEC = not settings.EnableEC
        if doClickOff.EC then
            doClickOff.EC = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when Extra C is enabled/disabled')
        end
    end
    if ui.checkbox("Extra D Clicks", settings.EnableED) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableED = not settings.EnableED
        if doClickOff.ED then
            doClickOff.ED = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when Extra D is enabled/disabled')
        end
    end
    ui.sameLine(0, 15)
    if ui.checkbox("Extra E Clicks", settings.EnableEE) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableEE = not settings.EnableEE
        if doClickOff.EE then
            doClickOff.EE = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when Extra E is enabled/disabled')
        end
    end
    ui.sameLine(0, 15)
    if ui.checkbox("Extra F Clicks", settings.EnableEF) then
        fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
        settings.EnableEF = not settings.EnableEF
        if doClickOff.EF then
            doClickOff.EF = false
        end
        if ui.itemHovered() then
            ui.setTooltip('Clicks when Extra F is enabled/disabled')
        end
    end
    ui.separator()
    if ui.button('Save car settings') then
        fncPlayMedia ('Woosh.mp3',settings.Volume,1)
        FncSetAndSave (true)
        savedTxt = 'Car settings saved!'
    end
    if ui.itemHovered() then
        ui.setTooltip('Saves settings that will load for this car only (skips default settings)')
    end
    ui.dummy(vec2(0,0))
    if ui.button('Save default settings') then
        fncPlayMedia ('Woosh.mp3',settings.Volume,1)
        FncSetAndSave (false)
        savedTxt = 'Default settings saved!'
    end
    if ui.itemHovered() then
        ui.setTooltip('Saves settings that will load for all cars (if no car settings are saved)')
    end
    ui.separator()
    local minsize = 125
    if Csize > minsize then
        local offset = 55
        local num = Csize-minsize
        if num < minsize then num = minsize end
        if Csize-offset > minsize then num = Csize-offset end
        ui.pushItemWidth(num)
    else
        ui.pushItemWidth(minsize)
    end
    ui.bulletText(car.acceleration)
    ui.labelText('* IClicker by Halvhjearne!',savedTxt)
end

function script.update(dt)
--    ac.setMessage('turningLights: '..tostring(car.turningLeftLights or car.turningRightLights),'turningLightsActivePhase: '..tostring(car.turningLightsActivePhase))
-- no need to include hazards
    local IsindicatorsOn = car.turningLeftLights or car.turningRightLights
    if settings.EnableSync and vercode > 2076 then
        IsindicatorsOn = car.turningLightsActivePhase and (car.turningLeftLights or car.turningRightLights)
        local files = SFiles[SFileVals.Turn]
        if IsindicatorsOn and not doClickOff.Turn then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.Turn = true
        end
        if not IsindicatorsOn and doClickOff.Turn then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.Turn = false
        end
    else
        if IsindicatorsOn then
            if counter >= (timeVar + settings.Delay) then
                local files = SFiles[SFileVals.Turn]
                if doClickOff.Turn then
                    fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
                    doClickOff.Turn = false
                else
                    fncPlayMedia (files.ON,settings.Volume,settings.playRate)
                    doClickOff.Turn = true
                end
                timeVar = counter
            end
        else
            if doClickOff.Turn then
                if counter >= (timeVar + settings.Delay) then
                    local files = SFiles[SFileVals.Turn]
                    fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
                    doClickOff.Turn = false
                    timeVar = counter - settings.Delay
                end
            end
        end
    end
    if settings.EnableWip then
        local wiperMode = math.floor(car.wiperMode, 0.1)
        local files = SFiles[SFileVals.Wiper]
        if wiperMode ~= 0 and not doClickOff.Wiper then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.Wiper = true
        end
        if wiperMode == 0 and doClickOff.Wiper then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.Wiper = false
        end
    end
    if settings.EnableHB then
        local IsHBOn = not car.lowBeams and car.headlightsActive
        local files = SFiles[SFileVals.HB]
        if IsHBOn and not doClickOff.HB then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.HB = true
        end
        if not IsHBOn and doClickOff.HB then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.HB = false
        end
    end
    if settings.EnableEA then 
        local files = SFiles[SFileVals.EA]
        if car.extraA and not doClickOff.EA then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.EA = true
        end
        if not car.extraA and doClickOff.EA then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.EA = false
        end
    end
    if settings.EnableEB then 
        local files = SFiles[SFileVals.EB]
        if car.extraB and not doClickOff.EB then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.EB = true
        end
        if not car.extraB and doClickOff.EB then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.EB = false
        end
    end
    if settings.EnableEC then 
        local files = SFiles[SFileVals.EC]
        if car.extraC and not doClickOff.EC then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.EC = true
        end
        if not car.extraC and doClickOff.EC then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.EC = false
        end
    end
    if settings.EnableED then 
        local files = SFiles[SFileVals.ED]
        if car.extraD and not doClickOff.ED then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.ED = true
        end
        if not car.extraD and doClickOff.ED then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.ED = false
        end
    end
    if settings.EnableEE then 
        local files = SFiles[SFileVals.EE]
        if car.extraE and not doClickOff.EE then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.EE = true
        end
        if not car.extraE and doClickOff.EE then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.EE = false
        end
    end
    if settings.EnableEF then 
        local files = SFiles[SFileVals.EF]
        if car.extraF and not doClickOff.EF then
            fncPlayMedia (files.ON,settings.Volume,settings.playRate)
            doClickOff.EF = true
        end
        if not car.extraF and doClickOff.EF then
            fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
            doClickOff.EF = false
        end
    end
    counter = counter + dt
    return false
end
