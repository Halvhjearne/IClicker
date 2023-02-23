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
    EnableSync = false, -- true / false
    Turnsoundfx = 1,
    menuvolume = 0.2,
    speedwarning = false,
    warningspeed = 110,
    warningloop = false,
    warningdelay = 2,
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

local car = ac.getCar(0)
local sim = ac.getSim()
local TESTdropdown = 1
local savedTxt = ''
local testvar = true
local counter = 0
local timeVar = -1
local timeVar2 = 0
local HAZARDS_G_THRESHOLD = 10

local doClickOff = {
    Turn = false,
    Wiper = false,
    HB = false,
    LB = false,
    EA = false,
    EB = false,
    EC = false,
    ED = false,
    EE = false,
    EF = false,
    Test = false,
    Speed = false
}

local menusnd = {
    woosh = 'Woosh.mp3',
    donk = 'Unbenannt2.flac'
}

local soundNames = {}
local sndfxnum = 0
for i in pairs(SFiles) do
    soundNames[i] = SFiles[i].NAME
    sndfxnum = sndfxnum+1
end

local sndsettings = {
    [0] = {soundfx=1,volume=0.2,name='Wiper',sname='Wiper',command='wiperMode'},
    [1] = {soundfx=1,volume=0.2,name='Highbeam',sname='HB',command=''},
    [2] = {soundfx=1,volume=0.2,name='Lowbeam',sname='LB',command='headlightsActive'},
    [3] = {soundfx=1,volume=0.2,name='Extra A',sname='EA',command='extraA'},
    [4] = {soundfx=1,volume=0.2,name='Extra B',sname='EB',command='extraB'},
    [5] = {soundfx=1,volume=0.2,name='Extra C',sname='EC',command='extraC'},
    [6] = {soundfx=1,volume=0.2,name='Extra D',sname='ED',command='extraD'},
    [7] = {soundfx=1,volume=0.2,name='Extra E',sname='EE',command='extraE'},
    [8] = {soundfx=1,volume=0.2,name='Extra F',sname='EF',command='extraF'},
    [9] = {soundfx=1,volume=0.0,name='Speed',sname='Speed',command=''},
    [10] = {soundfx=1,volume=0.2,name='Test',sname='Test',command=''},
}

-- dont run on old version of csp
local vercode = ac.getPatchVersionCode()
if vercode < 2000 then
    return nil
end

--dont run for cars with no ext_config.ini
local ext_cfg = ac.getFolder(ac.FolderID.ContentCars)..'/'..ac.getCarID(0)..'/extension/ext_config.ini'
if not io.fileExists(ext_cfg) then
    if not io.fileExists(ac.getFolder(ac.FolderID.ExtCfgSys)..'/cars/loaded/'..ac.getCarID(0)..'.ini') then
        return nil
    end
end

local dir = ac.getFolder(ac.FolderID.ExtCfgUser)..'/iclicker'
local filename = dir..'/cars/'..ac.getCarID(0)..'.cfg'
local defaultsfilename = dir..'/defaults.cfg'

local loadfile = ''
if io.fileExists(filename) then
    loadfile = filename
elseif io.fileExists(defaultsfilename) then
    loadfile = defaultsfilename
end

local valerrTxt = ''
if loadfile ~= '' then
    local data = ac.INIConfig.load(loadfile)
    for k,v in pairs(settings) do
        settings[k] = data:get('DEFAULTS', k, v)
    end
    for i = 0, 9 do
        sndsettings[i].soundfx = data:get('SOUNDS', sndsettings[i].sname, 1)
        if sndsettings[i].soundfx > sndfxnum then
            sndsettings[i].soundfx = 1
            valerrTxt = valerrTxt+sndsettings[i].name..' = '..sndsettings[i].soundfx..'?\n'
        end
        sndsettings[i].volume = data:get('VOLUME', sndsettings[i].sname, sndsettings[i].volume)
        if sndsettings[i].volume > 1 or sndsettings[i].volume < 0 then
            sndsettings[i].volume = 0.2
        end
    end
end

--checks for possible value problems and resets them in case they are "out of bounds"

if settings.Volume > 1 or settings.Volume < 0 then
    settings.Volume = 0.2
end
if settings.menuvolume > 1 or settings.menuvolume < 0 then
    settings.menuvolume = 0.2
end
if settings.Delay > 0.7 or settings.Delay < 0.1 then
    settings.Delay = 0.357
end

-- prevent first click delay?
local snd = ui.MediaPlayer():setAutoPlay(true):setVolume(0)
--if not myPlayer:supportedAsync() then
--    savedTxt = 'OS does not support the media player!'
--end

local function fncPlayMedia (Sfile,vv)
    if Sfile == '' then return false end
    if vv > 0.01 then
        local myPlayer = ui.MediaPlayer():setAutoPlay(true):setVolume(vv)
        myPlayer:setSource(Sfile):setAutoPlay(true):setVolume(vv):setPlaybackRate(1)
        return myPlayer
    else
        return nil
    end
end

local function FncSetAndSave (carFile)
    local theFile = defaultsfilename
    if carFile then
        theFile = filename
    end
    local data = ac.INIConfig.load(theFile)
    settings.Delay = tonumber(string.format("%.4f", settings.Delay))
    settings.Volume = tonumber(string.format("%.4f", settings.Volume))
    settings.menuvolume = tonumber(string.format("%.4f", settings.menuvolume))
    if io.fileExists(theFile) then
        io.deleteFile(theFile)
        data = ac.INIConfig.load(theFile)
    else
        if not io.dirExists(dir..'/cars/') then
            io.createDir(dir..'/cars/')
        end
    end
    for k,v in pairs(settings) do
        if k ~= 'EnableDebug' then
            data:setAndSave('DEFAULTS', k, v)
        end
    end
    for i = 0, 9 do
        data:setAndSave('SOUNDS', sndsettings[i].sname, sndsettings[i].soundfx)
        local volume = tonumber(string.format("%.4f", sndsettings[i].volume))
        data:setAndSave('VOLUME', sndsettings[i].sname, volume)
    end
    fncPlayMedia (menusnd.woosh,settings.menuvolume)
    return true
end

function script.ICMainSettings(dt)
    ui.icon('IClicker.png', vec2(16,16), rgbm(0, 1, 0, 1))
    ui.sameLine(0, 5)
    ui.header('Other settings:')
    ui.separator()
    ui.bulletText('Menu FX')
    if ui.checkbox("##Test00", false) then
        fncPlayMedia (menusnd.donk,settings.menuvolume)
    end
    if ui.itemHovered() then ui.setTooltip('Test volume of menu sounds') end
    ui.sameLine(0, 5)
    settings.menuvolume = ui.slider('##menuVolume', settings.menuvolume*100, 0, 100, 'Volume: %.0f%%')/100
    if ui.itemHovered() then ui.setTooltip('Volume of menu sounds (0 = Off)') end
    ui.separator()
    ui.bulletText('Sync indicator clicks')
    if ui.checkbox('##Sync', settings.EnableSync) then
        fncPlayMedia (menusnd.donk,settings.menuvolume)
        if vercode > 2076 then
            settings.EnableSync = not settings.EnableSync
        else
            ac.setMessage('Sync is disabled for now!','Update CSP version (version > 2076) to enable this')
            settings.EnableSync = false
        end
    end
    if ui.itemHovered() then
        if vercode > 2076 then
            ui.setTooltip('Sync clicks to indicator lights')
        else
            ui.setTooltip('Update CSP to enable this!')
        end
    end
    if not settings.EnableSync then
        ui.sameLine(0,5)
        local delayHz = tonumber(string.format("%.4f", (1/settings.Delay)))
        settings.Delay = ui.slider('##DelayFrequency', settings.Delay, 0.1, 0.7, 'T: %.4fms/F: '..delayHz..'Hz')
        if ui.itemHovered() then ui.setTooltip('Delay/Frequency of indicator clicks') end
    end
    ui.separator()
    ui.bulletText('Speed Warning')
    local txt = '- Disabled'
    if settings.speedwarning then
        txt = '##SpeedWarning'
    end
    if ui.checkbox(txt, settings.speedwarning) then
        settings.speedwarning = not settings.speedwarning
        fncPlayMedia (menusnd.donk,settings.menuvolume)
    end
    if ui.itemHovered() then ui.setTooltip('Warning when speed exceed x Km/h') end
    if settings.speedwarning then
        ui.sameLine(0,5)
        settings.warningspeed = ui.slider('##SpeedWarnslide', settings.warningspeed, 1, 500, 'Speed: %.0f% Km/h')
        if ui.itemHovered() then ui.setTooltip('Warning sound when speed exceed x Km/h') end
        ui.dummy(0)
        ui.sameLine(0,27)
        sndsettings[9].soundfx = ui.combo('##SpeedWarncombo'..sndsettings[9].sname, sndsettings[9].soundfx, soundNames)
        if ui.itemHovered() then ui.setTooltip('Select soundFX for speed warning') end
        ui.dummy(0)
        ui.sameLine(0,26)
        sndsettings[9].volume = ui.slider('##SpeedWarnVolume', sndsettings[9].volume*100, 0, 100, 'Volume: %.0f%%')/100
        if ui.itemHovered() then ui.setTooltip('Volume of Speed warning (0 = Off)') end
        if settings.warningloop then
            ui.dummy(0)
            ui.sameLine(0,26)
            settings.warningdelay = ui.slider('##WarningDelay', settings.warningdelay, 0.1, 10, 'Delay: %.1f sec')
            if ui.itemHovered() then ui.setTooltip('Delay between warning sounds') end
        end
        ui.dummy(0)
        ui.sameLine(0,26)
        if ui.checkbox('Loop warning', settings.warningloop) then
            settings.warningloop = not settings.warningloop
            fncPlayMedia (menusnd.donk,settings.menuvolume)
        end
        if ui.itemHovered() then ui.setTooltip('Will loop the speed warning over and over..') end
    end
    ui.separator()
    ui.header('Hazards G-forces "problem" fix:')
    ui.bullet()
    ui.sameLine(0,14)
    HAZARDS_G_THRESHOLD = ui.slider('##HAZARDS_G_THRESHOLD', HAZARDS_G_THRESHOLD, 0, 20, '%.2f')
    if ui.itemHovered() then ui.setTooltip('Change Hazards G Force Threshold (hold shift &: right click to set, middle click to remove)\nFix for hazards by changing/removing HAZARDS_G_THRESHOLD from the cars ext_config.ini\n\nCAUTION:\nONLY use this if your hazards are going nuts when breaking!!') end
    if ui.mouseClicked(1) and ui.keyboardButtonDown(16) then
        if io.fileExists(ext_cfg) then
            local data = ac.INIConfig.load(ext_cfg)
            data:setAndSave('INSTRUMENTS', 'HAZARDS_G_THRESHOLD', HAZARDS_G_THRESHOLD)
            fncPlayMedia (menusnd.woosh,settings.menuvolume)
        end
    end
    if ui.mouseClicked(2) and ui.keyboardButtonDown(16) then
        if io.fileExists(ext_cfg) then
            local data = ac.INIConfig.load(ext_cfg)
            data:setAndSave('INSTRUMENTS', 'HAZARDS_G_THRESHOLD', nil)
            fncPlayMedia (menusnd.woosh,settings.menuvolume)
        end
    end
    ui.separator()
    if settings.EnableDebug then
        local txt = 'Off'
        if doClickOff.Turn then
            txt = 'On'
        end
        ui.bulletText(string.format('Indicator: %s - %s - %s, %s', txt, settings.Turnsoundfx, SFiles[settings.Turnsoundfx].ON, SFiles[settings.Turnsoundfx].OFF))
        for i = 0, 9 do
            local ssett = sndsettings[i]
            txt = 'Off'
            if doClickOff[ssett.sname] then
                txt = 'On'
            end
            ui.bulletText(string.format('%s: %s - %s - %s, %s', ssett.name, txt, ssett.soundfx,SFiles[ssett.soundfx].ON,SFiles[ssett.soundfx].OFF))
        end
        txt = 'Off'
        if doClickOff.Test then
            txt = 'On'
        end
        ui.bulletText(string.format('Test: %s - %s - %s, %s', txt, TESTdropdown, SFiles[TESTdropdown].ON, SFiles[TESTdropdown].OFF))
        ui.bulletText('Counter: '..tonumber(string.format("%.4f", counter)))
        ui.bulletText('car.wiperProgress: '..car.wiperProgress)
        ui.bulletText('car.wiperMode: '..car.wiperMode)
--        ui.bulletText('CPU occupancy: '..ac.getSim().cpuOccupancy)
--        ui.bulletText('connected cars: '..tostring(ac.getSim().connectedCars))
        ui.bulletText('SFiles: '..tostring(sndfxnum)..' - SFileVals error: '..tostring(valerrTxt ~= '')..'\n'..valerrTxt)
-------------------------------------------------------------------------------
--    testing use of soundbanks
        ui.separator()
        if ui.button('Open/Close driver door') then
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
        local carnum = 0
        if sim.focusedCar > 0 then carnum = sim.focusedCar end
        ui.bullet()ui.sameLine(0,15)ui.copyable(ac.getCarName(carnum))
        ui.bullet()ui.sameLine(0,15)ui.copyable(ac.getCarID(carnum))

--        for index, section in iniConfig:iterate('LIGHT') do
--            print('Color: '..iniConfig:get(section, 'COLOR', 'red'))
--        end
-------------------------------------------------------------------------------
--        ui.bulletText(string.format("car.turningLightsActivePhase: %s", car.turningLightsActivePhase))
    end
end

local padding = {[0]=35,[1]=10,[2]=14,[3]=25,[4]=25,[5]=25,[6]=24,[7]=26,[8]=26,[9]=16,[10]=16}
local arr = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='Speed'}

function script.ICMain(dt)
--ui.windowSize().x

    ui.icon('IClicker.png', vec2(16,16), rgbm(0, 1, 0, 1))
    ui.sameLine(0, 5)
    ui.header('Settings:')

    ui.separator()
    ui.bulletText('Indicator FX')
    ui.sameLine(0,16)
    settings.Turnsoundfx = ui.combo('##IndicatorFX', settings.Turnsoundfx, soundNames)
    if ui.itemHovered() then ui.setTooltip('Select soundFX for indicators') end
    ui.sameLine(0,5)
    settings.Volume = ui.slider('##Volume00', settings.Volume*100, 0, 100, 'Volume: %.0f%%')/100
    if ui.itemHovered() then ui.setTooltip('Volume of Indicator clicks (0 = Off)') end

    ui.separator()
    for i = 0, 10 do
        if i ~= 9 then

            ui.bulletText(sndsettings[i].name..' FX')

            ui.sameLine(0,padding[i])
            if i==10 then
                if ui.checkbox("##Click Test", doClickOff.Test) then
                    if ui.keyboardButtonDown(ui.KeyIndex.Control) and ui.keyboardButtonDown(ui.KeyIndex.Shift) then
                        settings.EnableDebug = not settings.EnableDebug
                    else
                        doClickOff.Test = not doClickOff.Test
                        local files = SFiles[sndsettings[i].soundfx]
                        if doClickOff.Test then
                            fncPlayMedia (files.ON,sndsettings[i].volume)
                        else
                            fncPlayMedia (files.OFF,sndsettings[i].volume)
                        end
                    end
                end
                if ui.itemHovered() then
                    ui.setTooltip('Test selected soundFX')
                end
                ui.sameLine(0,5)
            end

            sndsettings[i].soundfx = ui.combo('##combo'..sndsettings[i].sname, sndsettings[i].soundfx, soundNames)
            if ui.itemHovered() then ui.setTooltip('Select soundFX for '..sndsettings[i].name) end
            ui.sameLine(0,5)
            sndsettings[i].volume = ui.slider('##Vol'..sndsettings[i].sname, sndsettings[i].volume*100, 0, 100, 'Volume: %.0f%%')/100
            if ui.itemHovered() then ui.setTooltip('Volume of '..sndsettings[i].name..' clicks (0 = Off)') end
            ui.separator()
        end
    end
    if ui.button('Save car settings') then
        FncSetAndSave (true)
        savedTxt = 'Car settings saved for '..ac.getCarName(0)..'!'
    end
    if ui.itemHovered() then ui.setTooltip('Saves settings that will load for this car only (skips default settings)') end
    ui.sameLine(0,5)
    if ui.button('Save default settings') then
        FncSetAndSave (false)
        savedTxt = 'Default settings saved!'
    end
    if ui.itemHovered() then ui.setTooltip('Saves settings that will load for all cars (if no car settings are saved)') end
    ui.sameLine(0,10)
    local colour = rgbm(1,1,1,0)
    if car.turningLeftLights and doClickOff.Turn then colour = rgbm(0,2,0,2) end
    ui.icon(ui.Icons.ArrowLeft,vec2(20,20),colour)
    ui.sameLine(0,5)
    colour = rgbm(1,1,1,0)
    if car.turningRightLights and doClickOff.Turn then colour = rgbm(0,1,0,1) end
    ui.icon(ui.Icons.ArrowRight,vec2(20,20),colour)
    colour = rgbm(1,1,1,0)
    if not car.lowBeams and car.headlightsActive then colour = rgbm(0,1,0,1) end
    ui.sameLine(0,5)
    colour = rgbm(1,1,1,0)
    if car.headlightsActive and not car.lowBeams  then colour = rgbm(0,1,0,1) end
    ui.textColored('HB',colour)
    colour = rgbm(1,1,1,0)
    if car.headlightsActive then colour = rgbm(0,1,0,1) end
    ui.sameLine(0,5)
    ui.textColored('LB',colour)
    for i = 0, 6 do
        colour = rgbm(1,1,1,0)
        if i == 6 then
            if car.speedKmh >= settings.warningspeed then
                colour = rgbm(0,1,0,1)
            end
        else
            if car['extra'..arr[i]] then
                colour = rgbm(0,1,0,1)
            end
        end
        ui.sameLine(0,5)
        ui.textColored(arr[i],colour)
    end
    colour = rgbm(1,1,1,0)
    if car.wiperMode > 0 then colour = rgbm(0,1,0,1) end
    ui.sameLine(0,5)
    ui.textColored('W '..car.wiperMode,colour)
    ui.separator()
    ui.pushFont(5)
    ui.labelText('','* IClicker by Halvhjearne!')
    ui.popFont()
    ui.sameLine(0,0)
    ui.text(savedTxt)
    if ui.itemHovered() then savedTxt = '' end
end

function script.update(dt)
--    ac.setMessage('turningLights: '..tostring(car.turningLeftLights or car.turningRightLights),'turningLightsActivePhase: '..tostring(car.turningLightsActivePhase))
-- no need to include hazards
    local IsindicatorsOn = car.turningLeftLights or car.turningRightLights
    local files = SFiles[settings.Turnsoundfx]
    if settings.EnableSync and vercode > 2076 then
        IsindicatorsOn = car.turningLightsActivePhase and (car.turningLeftLights or car.turningRightLights)
        if IsindicatorsOn and not doClickOff.Turn then
            fncPlayMedia (files.ON,settings.Volume)
            doClickOff.Turn = true
        end
        if not IsindicatorsOn and doClickOff.Turn then
            fncPlayMedia (files.OFF,settings.Volume)
            doClickOff.Turn = false
        end
    else
        if IsindicatorsOn then
            if counter >= (timeVar + settings.Delay) then
                if doClickOff.Turn then
                    fncPlayMedia (files.OFF,settings.Volume)
                    doClickOff.Turn = false
                else
                    fncPlayMedia (files.ON,settings.Volume)
                    doClickOff.Turn = true
                end
                timeVar = counter
            end
        else
            if doClickOff.Turn then
                if counter >= (timeVar + settings.Delay) then
                    fncPlayMedia (files.OFF,settings.Volume)
                    doClickOff.Turn = false
                    timeVar = counter - settings.Delay
                end
            end
        end
    end
    for i = 0, 9 do
        if sndsettings[i].volume > 0 then
            local files = SFiles[sndsettings[i].soundfx]
            local stm = false
            if i == 0 then
                stm = car.wiperMode ~= 0
            elseif i == 1 then
                stm = not car.lowBeams and car.headlightsActive
            elseif i == 9 then
                stm = car.speedKmh >= settings.warningspeed
                if doClickOff.Speed and settings.warningloop then
                    if snd:ended() then
                        if timeVar2 == 0 then
                            timeVar2 = counter
                        end
                    end
                    if counter >= timeVar2+settings.warningdelay then
                        snd:play()
                        timeVar2 = 0
                    end
                end
            else
                stm = car[sndsettings[i].command]
            end
            if stm and not doClickOff[sndsettings[i].sname] then
                if i == 9 then
                    snd = fncPlayMedia (files.ON,sndsettings[i].volume)
                else
                    fncPlayMedia (files.ON,sndsettings[i].volume)
                end
                doClickOff[sndsettings[i].sname] = true
            end
            if not stm and doClickOff[sndsettings[i].sname] then
                fncPlayMedia (files.OFF,sndsettings[i].volume)
                doClickOff[sndsettings[i].sname] = false
                if i == 9 then
                    timeVar2 = 0
                end
            end
        end
    end
    counter = counter + dt
end

-- this can cause headaches
-- [INSTRUMENTS]
-- FUEL_SPLASH_MULT=-0
-- HAZARDS_G_THRESHOLD=1.2
