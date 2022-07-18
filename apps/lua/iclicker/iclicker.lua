------------------------------------------------------------------
--  IClicker, audible indicators lua app for ac by Halvhjearne	--
------------------------------------------------------------------
--  this is a free app and may not be used in any commercial	--
--  way without written permission from Halvhjearne				--
------------------------------------------------------------------

-- hard set defaults if no defaults are saved yet (pls only change values or script will break)
local settings = {
	["Volume"] = 0.2, -- from 0.0 to 1.0 above or under will be reset to 0.2
	["Delay"] = 0.357, -- from 0.1 to 0.7 above or under will be reset to 0.357
	["playRate"] = 1, -- will always be reset to 1 for now
	["EnableSync"] = false, -- true / false
	["EnableWip"] = true,
	["EnableHB"] = true,
	["EnableEA"] = false,
	["EnableEB"] = false,
	["EnableEC"] = false,
	["EnableED"] = false,
	["EnableEE"] = false,
	["EnableEF"] = false
}

--[[
-------------------------------------------------------------------------------------------------
|	To add/change sound files and menu names:													|
|																								|
|	First add a name to soundNames table, then add an ON and an OFF sound to SFiles table.		|
|																								|
|	It is VERY important that soundNames and SFiles has the same ammount of elements or			|
|	the script might fail. (so if soundNames has 6 names, SFiles must have 6 sets of files)		|
|																								|
|	Dont forget to keep it sequential, first name in soundNames refers to the first set	of 		|
|	files in SFiles, second name in soundNames refers to second set of files in SFiles etc.		|
|																								|
|	Most formats will work like flac, ogg and many others, but some systems may only support	|
|	wav and mp3.																				|
-------------------------------------------------------------------------------------------------
--]]

-- Sound names in menus
local soundNames = {
-- here we set the number in the menu 1 is first etc.
	[1] = 'Default',	-- here we add the name we want shown in menu
	[2] = 'Generic',
	[3] = 'Audi',
	[4] = 'Ford Focus',
	[5] = 'Opel Corsa',
	[6] = 'Bus'	-- notice last one does not have a ","
}

-- names of ON and Off sound files incl. extension (.wav, .mp3, .flac, .ogg etc)
local SFiles = {
	-- here we set same number as the menu sound has in soundNames table
	[1] = {			-- here we can add the name of the ON sound file
		["ON"] = 'defaulton.flac',
					-- here we can add the name of the OFF sound file
		["OFF"] = 'defaultoff.flac'	-- notice second one does not have a ","
	},
	[2] = {
		["ON"] = '2GENERICon.flac',
		["OFF"] = '2GENERICoff.flac'
	},
	[3] = {
		["ON"] = 'audion.flac',
		["OFF"] = 'audioff.flac'
	},
	[4] = {
		["ON"] = 'fordfocuson.flac',
		["OFF"] = 'fordfocusoff.flac'
	},
	[5] = {
		["ON"] = 'opelcorsaon.flac',
		["OFF"] = 'opelcorsaoff.flac'
	},
	[6] = {
		["ON"] = 'BUSon.flac',
		["OFF"] = 'BUSoff.flac'
	}	-- notice last one does not have a ","
}

--[[
-------------------------------------------------------------------------------------------------
|	Dont change anything below this point (unless you know what you are doing)					|
-------------------------------------------------------------------------------------------------
--]]

local SFileVals = {
	["Turn"] = 1,
	["Wiper"] = 1,
	["HB"] = 1,
	["EA"] = 1,
	["EB"] = 1,
	["EC"] = 1,
	["ED"] = 1,
	["EE"] = 1,
	["EF"] = 1
}

local vercode = ac.getPatchVersionCode()
local dir = ac.getFolder(ac.FolderID.Documents)..'/Assetto Corsa/cfg/extension/iclicker'
local filename = dir..'/cars/'..ac.getCarID(0)..'.cfg'
local defaultsfilename = dir..'/defaults.cfg'

if io.fileExists(defaultsfilename) and not io.fileExists(filename) then
	local data = ac.INIConfig.load(defaultsfilename)
	for k,v in pairs(settings) do
		settings[k] = data:get('DEFAULTS', k, v)
	end
	for k,v in pairs(SFileVals) do
		SFileVals[k] = data:get('SOUNDS', k, v)
	end
end

if io.fileExists(filename) then
	local data = ac.INIConfig.load(filename)
	for k,v in pairs(settings) do
		settings[k] = data:get('DEFAULTS', k, v)
	end
	for k,v in pairs(SFileVals) do
		SFileVals[k] = data:get('SOUNDS', k, v)
	end
end

local counter = 0
local timeVar = -1
local EnableDebug = false

local doClickOff = {
	["Turn"] = false,
	["Wiper"] = false,
	["HB"] = false,
	["EA"] = false,
	["EB"] = false,
	["EC"] = false,
	["ED"] = false,
	["EE"] = false,
	["EF"] = false,
	["Test"] = false
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

-- some error checking of arrays/tables
local savedTxt = ''
local check1 = 0
local check2 = 0
local check4 = false
for i in pairs(soundNames) do
	check1 = check1 + 1
end
if check1 > 0 then
	local check3 = 0
	for x in pairs(SFiles) do
		check3 = 0
		for i in pairs(SFiles[x]) do
			check3 = check3 + 1
		end
		if check3 ~= 2 then
			check4 = true
			break
		end
		check2 = check2 + 1
	end
	if check1 ~= check2 or check4 then
		if check4 then
			savedTxt = 'ERROR: missing entry in sound file array!'
		else
			savedTxt = 'ERROR: not same amount of entries in sound arrays?'
		end
	end
	for k,v in pairs(SFileVals) do
		if v > check1 then
			SFileVals[k] = 1
		end
	end
else
	savedTxt = 'ERROR: no sound files in arrays?'
end

local car = ac.getCar(0)
local delaySlider = refnumber(settings.Delay)
local VolSlider = refnumber(settings.Volume*100)
local RateSlider = refnumber(settings.playRate*100)
local INDdropdown = refnumber(SFileVals.Turn)
local WIPdropdow = refnumber(SFileVals.Wiper)
local HBdropdown = refnumber(SFileVals.HB)
local EAdropdown = refnumber(SFileVals.EA)
local EBdropdown = refnumber(SFileVals.EB)
local ECdropdown = refnumber(SFileVals.EC)
local EDdropdown = refnumber(SFileVals.ED)
local EEdropdown = refnumber(SFileVals.EE)
local EFdropdown = refnumber(SFileVals.EF)
local TESTdropdown = refnumber(1)

-- prevent first click delay?
local myPlayer = ui.MediaPlayer():setAutoPlay(true):setVolume(0)
--if not myPlayer:supportedAsync() then
--	savedTxt = 'OS does not support the media player!'
--end

local function fncPlayMedia (Sfile,vv,prv)
	myPlayer:setSource('')
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

function script.ICMainSettings(dt)
	ui.icon('IClicker.png', vec2(14,14), rgbm(0, 1, 0, 1))
	ui.sameLine(0, 5)
	ui.header('Soundfx Selector:')
	ui.separator()
	ui.bullet()
	ui.sameLine(0, 15)
	if ui.combo('Indicator', INDdropdown, soundNames) then
		SFileVals.Turn = INDdropdown.value
	end
	if settings.EnableWip then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Wiper', WIPdropdow, soundNames) then
			SFileVals.Wiper = WIPdropdow.value
		end
	end
	if settings.EnableHB then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Highbeam', HBdropdown, soundNames) then
			SFileVals.HB = HBdropdown.value
		end
	end
	if settings.EnableEA then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Extra A', EAdropdown, soundNames) then
			SFileVals.EA = EAdropdown.value
		end
	end
	if settings.EnableEB then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Extra B', EBdropdown, soundNames) then
			SFileVals.EB = EBdropdown.value
		end
	end
	if settings.EnableEC then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Extra C', ECdropdown, soundNames) then
			SFileVals.EC = ECdropdown.value
		end
	end
	if settings.EnableED then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Extra D', EDdropdown, soundNames) then
			SFileVals.ED = EDdropdown.value
		end
	end
	if settings.EnableEE then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Extra E', EEdropdown, soundNames) then
			SFileVals.EE = EEdropdown.value
		end
	end
	if settings.EnableEF then
		ui.bullet()
		ui.sameLine(0, 15)
		if ui.combo('Extra F', EFdropdown, soundNames) then
			SFileVals.EF = EFdropdown.value
		end
	end
	ui.separator()
	ui.bullet()
	ui.sameLine(0, 15)
	ui.combo('Test Click', TESTdropdown, soundNames)
	if ui.itemHovered() then
		ui.setTooltip('Select a soundfx to test')
	end
	ui.dummy(vec2(2,0))
	ui.sameLine(0, 229)
	if ui.checkbox("Click Test", doClickOff.Test) then
		if ui.keyboardButtonDown(ui.KeyIndex.Control) and ui.keyboardButtonDown(ui.KeyIndex.Shift) then
			EnableDebug = not EnableDebug
		else
			doClickOff.Test = not doClickOff.Test
			local files = SFiles[TESTdropdown.value]
			if doClickOff.Test then
				fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			else
				fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			end
		end
	end
	if ui.itemHovered() then
		ui.setTooltip('Test selected soundfx')
	end
	ui.separator()
	if EnableDebug then
--		ui.dummy(vec2(0,0))
--		ui.text(string.format('%s: %s', table.indexOf(settings,1),settings.settings.playRate))
		if ui.slider('Play rate', RateSlider, 20, 100, 'Rate: %.2f%%') then
			settings.playRate = tonumber(string.format("%.2f", (RateSlider.value/100)))
--			ac.setMessage(RateSlider.value,settings.playRate)
		end
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
--		ui.bulletText('CPU occupancy: '..ac.getSim().cpuOccupancy)
--		ui.bulletText('connected cars: '..tostring(ac.getSim().connectedCars))
		ui.bulletText('soundNames: '..check1..' - SFiles: '..check2..' - Files check OK: '..tostring(not check4))
-------------------------------------------------------------------------------
--	testing use of soundbanks
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
-------------------------------------------------------------------------------
--		ui.bulletText(string.format("car.turningLightsActivePhase: %s", car.turningLightsActivePhase))
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
		if vercode > 2053 then
			ac.setMessage('Sync may not work yet','... and it may break the script!')
		end
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableSync = not settings.EnableSync
	end
	if ui.itemHovered() then
		if vercode < 2053 then ui.setTooltip('Not working yet (disables indicator soundfx)!') end
	end
	if not settings.EnableSync then
		local delayHz = tonumber(string.format("%.4f", (1/delaySlider.value)))
		if ui.slider('Delay/Frequency', delaySlider, 0.1, 0.7, 'T: %.4fms/F: '..delayHz..'Hz') then
			settings.Delay = delaySlider.value
		end
		if ui.itemHovered() then
			ui.setTooltip('Delay/Frequency of indicator clicks')
		end
	end
	ui.separator()
	if ui.slider('Volume', VolSlider, 0, 100, 'Volume: %.2f%%') then
		settings.Volume = (VolSlider.value/100)
	end
	ui.separator()
	if ui.checkbox("Wiper Clicks", settings.EnableWip) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableWip = not settings.EnableWip
		if doClickOff.Wiper then
			doClickOff.Wiper = false
		end
	end
	ui.sameLine(0, 25)
	if ui.checkbox("Highbeam Clicks", settings.EnableHB) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableHB = not settings.EnableHB
		if doClickOff.HB then
			doClickOff.HB = false
		end
	end
	if ui.checkbox("Extra A Clicks", settings.EnableEA) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableEA = not settings.EnableEA
		if doClickOff.EA then
			doClickOff.EA = false
		end
	end
	ui.sameLine(0, 15)
	if ui.checkbox("Extra B Clicks", settings.EnableEB) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableEB = not settings.EnableEB
		if doClickOff.EB then
			doClickOff.EB = false
		end
	end
	ui.sameLine(0, 15)
	if ui.checkbox("Extra C Clicks", settings.EnableEC) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableEC = not settings.EnableEC
		if doClickOff.EC then
			doClickOff.EC = false
		end
	end
	if ui.checkbox("Extra D Clicks", settings.EnableED) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableED = not settings.EnableED
		if doClickOff.ED then
			doClickOff.ED = false
		end
	end
	ui.sameLine(0, 15)
	if ui.checkbox("Extra E Clicks", settings.EnableEE) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableEE = not settings.EnableEE
		if doClickOff.EE then
			doClickOff.EE = false
		end
	end
	ui.sameLine(0, 15)
	if ui.checkbox("Extra F Clicks", settings.EnableEF) then
		fncPlayMedia ('Unbenannt2.flac',settings.Volume,1)
		settings.EnableEF = not settings.EnableEF
		if doClickOff.EF then
			doClickOff.EF = false
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
	ui.labelText('* IClicker by Halvhjearne!',savedTxt)
end

function script.update(dt)
--	ac.setMessage(counter,ac.getPatchVersionCode())
	local IsindicatorsOn = car.turningLeftLights or car.turningRightLights
-- no need to include hazards?
--	local IsindicatorsOn = car.turningLeftLights or car.turningRightLights or car.hazardLights
	if settings.EnableSync then
		IsindicatorsOn = false
--		Will this work in next patch?
		if vercode > 2053 then
			IsindicatorsOn = car.turningLightsActivePhase
		end
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
		local wiperMode = car.wiperMode
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
		local IsEAOn = car.extraA
		local files = SFiles[SFileVals.EA]
		if IsEAOn and not doClickOff.EA then
			fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			doClickOff.EA = true
		end
		if not IsEAOn and doClickOff.EA then
			fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			doClickOff.EA = false
		end
	end
	if settings.EnableEB then 
		local IsEBOn = car.extraB
		local files = SFiles[SFileVals.EB]
		if IsEBOn and not doClickOff.EB then
			fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			doClickOff.EB = true
		end
		if not IsEBOn and doClickOff.EB then
			fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			doClickOff.EB = false
		end
	end
	if settings.EnableEC then 
		local IsECOn = car.extraC
		local files = SFiles[SFileVals.EC]
		if IsECOn and not doClickOff.EC then
			fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			doClickOff.EC = true
		end
		if not IsECOn and doClickOff.EC then
			fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			doClickOff.EC = false
		end
	end
	if settings.EnableED then 
		local IsEDOn = car.extraD
		local files = SFiles[SFileVals.ED]
		if IsEDOn and not doClickOff.ED then
			fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			doClickOff.ED = true
		end
		if not IsEDOn and doClickOff.ED then
			fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			doClickOff.ED = false
		end
	end
	if settings.EnableEE then 
		local IsEEOn = car.extraE
		local files = SFiles[SFileVals.EE]
		if IsEEOn and not doClickOff.EE then
			fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			doClickOff.EE = true
		end
		if not IsEEOn and doClickOff.EE then
			fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			doClickOff.EE = false
		end
	end
	if settings.EnableEF then 
		local IsEFOn = car.extraF
		local files = SFiles[SFileVals.EF]
		if IsEFOn and not doClickOff.EF then
			fncPlayMedia (files.ON,settings.Volume,settings.playRate)
			doClickOff.EF = true
		end
		if not IsEFOn and doClickOff.EF then
			fncPlayMedia (files.OFF,settings.Volume,settings.playRate)
			doClickOff.EF = false
		end
	end
	counter = counter + dt
	return false
end
