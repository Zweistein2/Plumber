local pipe = nil
local timeSinceLastWrite = 0.0
Plumber = {}
local Plumber_mt = Class(Plumber)
addModEventListener(Plumber)
local stringBuf = {}

local isServer = false

--- giants functions

function Plumber:loadMap(filename)
    isServer = g_server ~= nil and g_currentMission.connectedToDedicatedServer

    if (isServer == false) then
        plumberOpenPipe()
    end
end

function Plumber:update(dt)
	timeSinceLastWrite = timeSinceLastWrite + dt

    if (isServer == false) then
        if (pipe ~= nil) then
            if (timeSinceLastWrite >= 3000.0 and timeSinceLastWrite <= 4000.0) then
                writeFields()
                writePlayers()
                writePlaceables()
                writeFarms()
                writeMetadata()
                writeMods()
                writeMissions()
                writeEconomy()
                writeVehicleSales()
                writeVehicles()
                writeNPCs()
                writeEnvironment()

                timeSinceLastWrite = 0.0
            end
        else
            if (timeSinceLastWrite >= 60000.0) then
                print("no opened pipe found, trying to open new one")
                plumberOpenPipe()
                timeSinceLastWrite = 0
            end
        end
    end
end

function Plumber:deleteMap()
    if (isServer == false) then
        plumberClosePipe()
    end
end

--- Custom functions

-- PipeFunctions

function plumberOpenPipe()
	pipe = io.open("\\\\.\\pipe\\plumber", "w")

	if (pipe ~= nil) then
		print("opened pipe successfully")
	else
		print("error opening pipe")
	end
end

function plumberWriteMessageToPipe(...)
	if (pipe ~= nil) then
        for key, value in ipairs{...} do
            if(type(value) == 'boolean') then
                stringBuf[#stringBuf+1] = tostring(value)
            else
                stringBuf[#stringBuf+1] = value
            end
        end
	end
end

function plumberFlushPipe()
	if (pipe ~= nil) then
        pipe:write(table.concat(stringBuf))
        stringBuf = {}
	end
end

function plumberClosePipe()
    print("Shutdown: Closing opened pipe if there is one")

	if (pipe ~= nil) then
		pipe:close()
	end
end

-- Other Functions

function writeFields()
    if(g_fieldManager ~= nil) then
        plumberWriteMessageToPipe("{\"fields\":[")
        for key, value in ipairs(g_fieldManager.fields) do
            if(key == 1) then
                plumberWriteMessageToPipe("{\"fieldID\": ", key)
            else
                plumberWriteMessageToPipe(",{\"fieldID\": ", key)
            end
            plumberWriteMessageToPipe(",\"areaInHectar\": ", g_fieldManager.fields[key].fieldArea)
            if(g_fieldManager.fields[key].fruitType ~= nil) then
                plumberWriteMessageToPipe(",\"fruitType\": ", g_fieldManager.fields[key].fruitType)
            else
                plumberWriteMessageToPipe(",\"fruitType\": -1")
            end
            plumberWriteMessageToPipe(",\"x\": ", g_fieldManager.fields[key].posX)
            plumberWriteMessageToPipe(",\"z\": ", g_fieldManager.fields[key].posZ)
            plumberWriteMessageToPipe("}")
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writePlayers()
    if(g_currentMission ~= nil and g_farmManager ~= nil) then
        plumberWriteMessageToPipe("{\"players\":[")
        local count = 0
        for key, value in pairs(g_currentMission.players) do
            local found = false;

            if(count == 0) then
                for farmkey, farmvalue in ipairs(g_farmManager.farms) do
                    if(g_farmManager.farms[farmkey].farmId == g_currentMission.players[key].farmId) then
                        for playerkey, playervalue in ipairs(g_farmManager.farms[farmkey].players) do
                            if(g_farmManager.farms[farmkey].players[playerkey].userId == g_currentMission.players[key].userId and g_farmManager.farms[farmkey].players[playerkey].lastNickname ~= nil) then
                                found = true;

                                plumberWriteMessageToPipe("{\"name\":\"", g_farmManager.farms[farmkey].players[playerkey].lastNickname, "\"")
                            end
                        end
                    end
                end
            else
                for farmkey, farmvalue in ipairs(g_farmManager.farms) do
                    if(g_farmManager.farms[farmkey].farmId == g_currentMission.players[key].farmId) then
                        for playerkey, playervalue in ipairs(g_farmManager.farms[farmkey].players) do
                            if(g_farmManager.farms[farmkey].players[playerkey].userId == g_currentMission.players[key].userId and g_farmManager.farms[farmkey].players[playerkey].lastNickname ~= nil) then
                                found = true;

                                plumberWriteMessageToPipe(",{\"name\":\"", g_farmManager.farms[farmkey].players[playerkey].lastNickname, "\"")
                            end
                        end
                    end
                end
            end

            if(found == false) then
                if(count == 0) then
                    plumberWriteMessageToPipe("{\"name\":\"UNKNOWN\"")
                else
                    plumberWriteMessageToPipe(",{\"name\":\"UNKNOWN\"")
                end
            end
            local x,y,z = getWorldTranslation(g_currentMission.players[key].rootNode)
            plumberWriteMessageToPipe(",\"x\":", x)
            plumberWriteMessageToPipe(",\"y\":", y)
            plumberWriteMessageToPipe(",\"z\":", z)
            plumberWriteMessageToPipe(",\"farmId\":", g_currentMission.players[key].farmId)
            plumberWriteMessageToPipe(",\"id\":", g_currentMission.players[key].userId)
            plumberWriteMessageToPipe("}")
            count = count + 1
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writePlaceables()
    if(g_currentMission ~= nil and g_currentMission.placeableSystem ~= nil and g_currentMission.placeableSystem.placeables ~= nil) then
        plumberWriteMessageToPipe("{\"placeables\":[")
        local count = 0
        for key, value in ipairs(g_currentMission.placeableSystem.placeables) do
            if(count == 0) then
                plumberWriteMessageToPipe("{\"name\":\"", g_currentMission.placeableSystem.placeables[key].xmlFile.filename ,"\"")
            else
                plumberWriteMessageToPipe(",{\"name\":\"", g_currentMission.placeableSystem.placeables[key].xmlFile.filename ,"\"")
            end
            plumberWriteMessageToPipe(",\"x\":", g_currentMission.placeableSystem.placeables[key].position.x)
            plumberWriteMessageToPipe(",\"y\":", g_currentMission.placeableSystem.placeables[key].position.y)
            plumberWriteMessageToPipe(",\"z\":", g_currentMission.placeableSystem.placeables[key].position.z)
            plumberWriteMessageToPipe(",\"farmId\":", g_currentMission.placeableSystem.placeables[key].ownerFarmId)
            plumberWriteMessageToPipe(",\"id\":", g_currentMission.placeableSystem.placeables[key].id)
            plumberWriteMessageToPipe(",\"price\":", g_currentMission.placeableSystem.placeables[key].price)
            plumberWriteMessageToPipe(",\"age\":", g_currentMission.placeableSystem.placeables[key].age)
            if(g_currentMission.placeableSystem.placeables[key].spec_silo ~= nil and g_currentMission.placeableSystem.placeables[key].spec_silo.storages ~= nil) then
                plumberWriteMessageToPipe(",\"storage\":[")
                for storagekey, storagevalue in ipairs(g_currentMission.placeableSystem.placeables[key].spec_silo.storages) do
                    if(storagekey == 1) then
                        plumberWriteMessageToPipe("{\"capacity\":", g_currentMission.placeableSystem.placeables[key].spec_silo.storages[storagekey].capacity)
                    else
                        plumberWriteMessageToPipe(",{\"capacity\":", g_currentMission.placeableSystem.placeables[key].spec_silo.storages[storagekey].capacity)
                    end
                    plumberWriteMessageToPipe(",\"costsPerFillLevelAndDay\":", g_currentMission.placeableSystem.placeables[key].spec_silo.storages[storagekey].costsPerFillLevelAndDay)
                    plumberWriteMessageToPipe(",\"fillLevels\":[")
                    if(g_currentMission.placeableSystem.placeables[key].spec_silo.storages[storagekey].fillLevels ~= nil) then
                        local fillcount = 0
                        for fillkey, fillvalue in pairs(g_currentMission.placeableSystem.placeables[key].spec_silo.storages[storagekey].fillLevels) do
                            if(fillcount == 0) then
                                plumberWriteMessageToPipe("{\"fillType\":", fillkey)
                            else
                                plumberWriteMessageToPipe(",{\"fillType\":", fillkey)
                            end
                            plumberWriteMessageToPipe(",\"fillLevel\":", g_currentMission.placeableSystem.placeables[key].spec_silo.storages[storagekey].fillLevels[fillkey])
                            plumberWriteMessageToPipe("}")
                            fillcount = fillcount + 1
                        end
                    end
                    plumberWriteMessageToPipe("]}")
                end
                plumberWriteMessageToPipe("]")
            end
            if(g_currentMission.placeableSystem.placeables[key].spec_sellingStation ~= nil and g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation ~= nil and g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.id ~= nil) then
                plumberWriteMessageToPipe(",\"sellPointId\":", g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.id)
            end
            if(g_currentMission.placeableSystem.placeables[key].spec_sellingStation ~= nil and g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation ~= nil and g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.totalPaid ~= nil) then
                plumberWriteMessageToPipe(",\"totalPaid\":[")
                local fillcount = 0
                for fillkey, fillvalue in pairs(g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.totalPaid) do
                    if(fillcount == 0) then
                        plumberWriteMessageToPipe("{\"fillType\":", fillkey)
                    else
                        plumberWriteMessageToPipe(",{\"fillType\":", fillkey)
                    end
                    plumberWriteMessageToPipe(",\"amount\":", g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.totalPaid[fillkey])
                    plumberWriteMessageToPipe("}")
                    fillcount = fillcount + 1
                end
                plumberWriteMessageToPipe("]")
            end
            if(g_currentMission.placeableSystem.placeables[key].spec_sellingStation ~= nil and g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation ~= nil and g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.totalReceived ~= nil) then
                plumberWriteMessageToPipe(",\"totalReceived\":[")
                local fillcount = 0
                for fillkey, fillvalue in pairs(g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.totalReceived) do
                    if(fillcount == 0) then
                        plumberWriteMessageToPipe("{\"fillType\":", fillkey)
                    else
                        plumberWriteMessageToPipe(",{\"fillType\":", fillkey)
                    end
                    plumberWriteMessageToPipe(",\"amount\":", g_currentMission.placeableSystem.placeables[key].spec_sellingStation.sellingStation.totalReceived[fillkey])
                    plumberWriteMessageToPipe("}")
                    fillcount = fillcount + 1
                end
                plumberWriteMessageToPipe("]")
            end
            plumberWriteMessageToPipe("}")
            count = count + 1
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeFarms()
    if(g_farmManager ~= nil) then
        plumberWriteMessageToPipe("{\"farms\":[")
        for key, value in ipairs(g_farmManager.farms) do
            if(key ~= 1) then
                if(key == 2) then
                    plumberWriteMessageToPipe("{\"farmID\":", g_farmManager.farms[key].farmId)
                else
                    plumberWriteMessageToPipe(",{\"farmID\":", g_farmManager.farms[key].farmId)
                end
                plumberWriteMessageToPipe(",\"loan\":", g_farmManager.farms[key].loan)
                plumberWriteMessageToPipe(",\"loanMax\":", g_farmManager.farms[key].loanMax)
                plumberWriteMessageToPipe(",\"money\":", g_farmManager.farms[key].money)
                plumberWriteMessageToPipe(",\"name\":\"", g_farmManager.farms[key].name, "\"")
                plumberWriteMessageToPipe(",\"players\":[")
                writeFarmPlayers(g_farmManager.farms[key].players)
                plumberWriteMessageToPipe("],\"stats\":[")
                plumberWriteTableToPipe(g_farmManager.farms[key].stats.statistics)
                plumberWriteMessageToPipe("],\"finances\":[")
                plumberWriteTableToPipe(g_farmManager.farms[key].stats.finances)
                plumberWriteMessageToPipe("],\"financeHistory\":[")
                plumberWriteTableToPipe(g_farmManager.farms[key].stats.financesHistory)
                plumberWriteMessageToPipe("]}")
            end
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeFarmPlayers(players)
    for key, value in ipairs(players) do
        if(players[key].lastNickname ~= nil) then
            if(key == 1) then
                plumberWriteMessageToPipe("{\"lastNickname\":\"", players[key].lastNickname, "\"")
            else
                plumberWriteMessageToPipe(",{\"lastNickname\":\"", players[key].lastNickname, "\"")
            end
        else
            if(key == 1) then
                plumberWriteMessageToPipe("{\"lastNickname\":\"UNKNOWN\"")
            else
                plumberWriteMessageToPipe(",{\"lastNickname\":\"UNKNOWN\"")
            end
        end
        plumberWriteMessageToPipe(",\"isFarmManager\":", players[key].isFarmManager)
        plumberWriteMessageToPipe(",\"permissions\":[")
        plumberWriteTableToPipe(players[key].permissions)
        plumberWriteMessageToPipe("]}")
    end
end

function writeMetadata()
    if(g_currentMission ~= nil) then
        plumberWriteMessageToPipe("{\"metadata\":[{")

        plumberWriteMessageToPipe("\"terrainSize\":", g_currentMission.terrainSize)
        plumberWriteMessageToPipe(",\"time\":", g_currentMission.time)
        if(g_currentMission.vehicleXZPosHighPrecisionCompressionParams ~= nil) then
            plumberWriteMessageToPipe(",\"worldOffset\":", g_currentMission.vehicleXZPosHighPrecisionCompressionParams.worldOffset)
            plumberWriteMessageToPipe(",\"worldSize\":", g_currentMission.vehicleXZPosHighPrecisionCompressionParams.worldSize)
        end
        if(g_currentMission.missionInfo ~= nil) then
            plumberWriteMessageToPipe(",\"automaticMotorStartEnabled\":", g_currentMission.missionInfo.automaticMotorStartEnabled)
            plumberWriteMessageToPipe(",\"autoSaveInterval\":", g_currentMission.missionInfo.autoSaveInterval)
            plumberWriteMessageToPipe(",\"difficulty\":", g_currentMission.missionInfo.difficulty)
            plumberWriteMessageToPipe(",\"dirtInterval\":", g_currentMission.missionInfo.dirtInterval)
            plumberWriteMessageToPipe(",\"economicDifficulty\":", g_currentMission.missionInfo.economicDifficulty)
            plumberWriteMessageToPipe(",\"fuelUsage\":", g_currentMission.missionInfo.fuelUsage)
            plumberWriteMessageToPipe(",\"fruitDestruction\":", g_currentMission.missionInfo.fruitDestruction)
            plumberWriteMessageToPipe(",\"growthMode\":", g_currentMission.missionInfo.growthMode)
            plumberWriteMessageToPipe(",\"helperBuyFertilizer\":", g_currentMission.missionInfo.helperBuyFertilizer)
            plumberWriteMessageToPipe(",\"helperBuyFuel\":", g_currentMission.missionInfo.helperBuyFuel)
            plumberWriteMessageToPipe(",\"helperBuySeeds\":", g_currentMission.missionInfo.helperBuySeeds)
            plumberWriteMessageToPipe(",\"helperManureSource\":", g_currentMission.missionInfo.helperManureSource)
            plumberWriteMessageToPipe(",\"helperSlurrySource\":", g_currentMission.missionInfo.helperSlurrySource)
            plumberWriteMessageToPipe(",\"isSnowEnabled\":", g_currentMission.missionInfo.isSnowEnabled)
            plumberWriteMessageToPipe(",\"limeRequired\":", g_currentMission.missionInfo.limeRequired)
            plumberWriteMessageToPipe(",\"mapTitle\":\"", g_currentMission.missionInfo.mapTitle, "\"")
            if(g_currentMission.missionInfo.money ~= nil) then
                plumberWriteMessageToPipe(",\"money\":", g_currentMission.missionInfo.money)
            end
            plumberWriteMessageToPipe(",\"plannedDaysPerPeriod\":", g_currentMission.missionInfo.plannedDaysPerPeriod)
            plumberWriteMessageToPipe(",\"plowingRequiredEnabled\":", g_currentMission.missionInfo.plowingRequiredEnabled)
            plumberWriteMessageToPipe(",\"resetVehicles\":", g_currentMission.missionInfo.resetVehicles)
            plumberWriteMessageToPipe(",\"savegameIndex\":", g_currentMission.missionInfo.savegameIndex)
            plumberWriteMessageToPipe(",\"savegameName\":\"", g_currentMission.missionInfo.savegameName, "\"")
            plumberWriteMessageToPipe(",\"stonesEnabled\":", g_currentMission.missionInfo.stonesEnabled)
            plumberWriteMessageToPipe(",\"stopAndGoBraking\":", g_currentMission.missionInfo.stopAndGoBraking)
            plumberWriteMessageToPipe(",\"timeScale\":", g_currentMission.missionInfo.timeScale)
            plumberWriteMessageToPipe(",\"trafficEnabled\":", g_currentMission.missionInfo.trafficEnabled)
            plumberWriteMessageToPipe(",\"trailerFillLimit\":", g_currentMission.missionInfo.trailerFillLimit)
            plumberWriteMessageToPipe(",\"weedsEnabled\":", g_currentMission.missionInfo.weedsEnabled)
        end

        plumberWriteMessageToPipe("}]}")
        plumberFlushPipe()
    end
end

function writeMods()
    if(g_modIsLoaded ~= nil) then
        local count = 0
        plumberWriteMessageToPipe("{\"mods\":[")
        for loadkey, loadvalue in pairs(g_modIsLoaded) do
            if(loadvalue == true and g_modManager ~= nil) then
                for key, value in pairs(g_modManager.nameToMod) do
                    if(key == loadkey) then
                        if(count == 0) then
                            plumberWriteMessageToPipe("{\"modID\":", g_modManager.nameToMod[key].id)
                        else
                            plumberWriteMessageToPipe(",{\"modID\":", g_modManager.nameToMod[key].id)
                        end
                        plumberWriteMessageToPipe(",\"author\":\"", g_modManager.nameToMod[key].author, "\"")
                        --plumberWriteMessageToPipe(",\"Description\":\"", g_modManager.mods[key].description, "\"")
                        plumberWriteMessageToPipe(",\"modName\":\"", g_modManager.nameToMod[key].modName, "\"")
                        plumberWriteMessageToPipe(",\"title\":\"", g_modManager.nameToMod[key].title, "\"")
                        plumberWriteMessageToPipe(",\"isDLC\":", g_modManager.nameToMod[key].isDLC)
                        plumberWriteMessageToPipe(",\"isMultiplayerSupported\":", g_modManager.nameToMod[key].isMultiplayerSupported)
                        plumberWriteMessageToPipe(",\"version\":\"", g_modManager.nameToMod[key].version, "\"")
                        plumberWriteMessageToPipe("}")
                        count = count + 1
                    end
                end
            end
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeMissions()
    if(g_missionManager ~= nil) then
        plumberWriteMessageToPipe("{\"missions\":[")
        for key, value in ipairs(g_missionManager.missions) do
            if(key == 1) then
                plumberWriteMessageToPipe("{\"completion\":", g_missionManager.missions[key].completion)
            else
                plumberWriteMessageToPipe(",{\"completion\":", g_missionManager.missions[key].completion)
            end
            if(g_missionManager.missions[key].field ~= nil) then
                if(g_missionManager.missions[key].field.fieldId ~= nil) then
                    plumberWriteMessageToPipe(",\"fieldId\":", g_missionManager.missions[key].field.fieldId)
                end
                if(g_missionManager.missions[key].field.fieldArea ~= nil) then
                    plumberWriteMessageToPipe(",\"areaInHectar\":", g_missionManager.missions[key].field.fieldArea)
                end
                if(g_missionManager.missions[key].field.posX ~= nil) then
                    plumberWriteMessageToPipe(",\"x\":", g_missionManager.missions[key].field.posX)
                end
                if(g_missionManager.missions[key].field.posZ ~= nil) then
                    plumberWriteMessageToPipe(",\"z\":", g_missionManager.missions[key].field.posZ)
                end
                if(g_missionManager.missions[key].field.fruitType ~= nil) then
                    plumberWriteMessageToPipe(",\"fruitType\":", g_missionManager.missions[key].field.fruitType)
                end
            end
            if(g_missionManager.missions[key].fieldPercentageDone ~= nil) then
                plumberWriteMessageToPipe(",\"fieldPercentageDone\":", g_missionManager.missions[key].fieldPercentageDone)
            end
            if(g_missionManager.missions[key].moneyMultiplier ~= nil) then
                plumberWriteMessageToPipe(",\"moneyMultiplier\":", g_missionManager.missions[key].moneyMultiplier)
            end
            if(g_missionManager.missions[key].reimbursementPerDifficulty ~= nil) then
                plumberWriteMessageToPipe(",\"reimbursementPerDifficulty\":", g_missionManager.missions[key].reimbursementPerDifficulty)
            else
                plumberWriteMessageToPipe(",\"reimbursementPerDifficulty\":false")
            end
            if(g_missionManager.missions[key].reimbursementPerHa ~= nil) then
                plumberWriteMessageToPipe(",\"reimbursementPerHa\":", g_missionManager.missions[key].reimbursementPerHa)
            end
            if(g_missionManager.missions[key].reward ~= nil) then
                plumberWriteMessageToPipe(",\"reward\":", g_missionManager.missions[key].reward)
            end
            if(g_missionManager.missions[key].type.name ~= nil) then
                plumberWriteMessageToPipe(",\"type\":\"", g_missionManager.missions[key].type.name, "\"")
            end
            if(g_missionManager.missions[key].expectedLiters ~= nil) then
                plumberWriteMessageToPipe(",\"expectedLiters\":", g_missionManager.missions[key].expectedLiters)
            end
            if(g_missionManager.missions[key].depositedLiters ~= nil) then
                plumberWriteMessageToPipe(",\"depositedLiters\":", g_missionManager.missions[key].depositedLiters)
            end
            if(g_missionManager.missions[key].fillType ~= nil) then
                plumberWriteMessageToPipe(",\"fillType\":", g_missionManager.missions[key].fillType)
            end
            if(g_missionManager.missions[key].farmId ~= nil) then
                plumberWriteMessageToPipe(",\"farmId\":", g_missionManager.missions[key].farmId)
            end
            if(g_missionManager.missions[key].sellPoint ~= nil and g_missionManager.missions[key].sellPoint.owningPlaceable ~= nil and g_missionManager.missions[key].sellPoint.owningPlaceable.currentSavegameId ~= nil) then
                plumberWriteMessageToPipe(",\"sellPointPlaceableId\":", g_missionManager.missions[key].sellPoint.owningPlaceable.currentSavegameId)
            elseif(g_missionManager.missions[key].sellingStation ~= nil and g_missionManager.missions[key].sellingStation.owningPlaceable ~= nil and g_missionManager.missions[key].sellingStation.owningPlaceable.currentSavegameId ~= nil) then
                plumberWriteMessageToPipe(",\"sellPointPlaceableId\":", g_missionManager.missions[key].sellingStation.owningPlaceable.currentSavegameId)
            elseif(g_missionManager.missions[key].sellPoint ~= nil and g_missionManager.missions[key].sellPoint.owningPlaceable ~= nil and g_missionManager.missions[key].sellPoint.owningPlaceable.id ~= nil) then
                plumberWriteMessageToPipe(",\"sellPointPlaceableId\":", g_missionManager.missions[key].sellPoint.owningPlaceable.id)
            elseif(g_missionManager.missions[key].sellingStation ~= nil and g_missionManager.missions[key].sellingStation.owningPlaceable ~= nil and g_missionManager.missions[key].sellingStation.owningPlaceable.id ~= nil) then
                plumberWriteMessageToPipe(",\"sellPointPlaceableId\":", g_missionManager.missions[key].sellingStation.owningPlaceable.id)
            end
            if(g_missionManager.missions[key].rewardPerHa ~= nil) then
                plumberWriteMessageToPipe(",\"rewardPerHa\":", g_missionManager.missions[key].rewardPerHa)
            end
            if(g_missionManager.missions[key].spawnedVehicles ~= nil) then
                plumberWriteMessageToPipe(",\"spawnedVehicles\":", g_missionManager.missions[key].spawnedVehicles)
            else
                plumberWriteMessageToPipe(",\"spawnedVehicles\":false")
            end
            if(g_missionManager.missions[key].success ~= nil) then
                plumberWriteMessageToPipe(",\"success\":", g_missionManager.missions[key].success)
            else
                plumberWriteMessageToPipe(",\"success\":false")
            end
            if(g_missionManager.missions[key].contractDay ~= nil) then
                plumberWriteMessageToPipe(",\"contractDay\":", g_missionManager.missions[key].contractDay)
            end
            if(g_missionManager.missions[key].contractDuration ~= nil) then
                plumberWriteMessageToPipe(",\"contractDuration\":", g_missionManager.missions[key].contractDuration)
            end
            if(g_missionManager.missions[key].contractTime ~= nil) then
                plumberWriteMessageToPipe(",\"contractTime\":", g_missionManager.missions[key].contractTime)
            end
            if(g_missionManager.missions[key].contractLiters ~= nil) then
                plumberWriteMessageToPipe(",\"contractLiters\":", g_missionManager.missions[key].contractLiters)
            end
            if(g_missionManager.missions[key].deliveredLiters ~= nil) then
                plumberWriteMessageToPipe(",\"deliveredLiters\":", g_missionManager.missions[key].deliveredLiters)
            end
            if(g_missionManager.missions[key].vehicleUseCost ~= nil) then
                plumberWriteMessageToPipe(",\"vehicleUseCost\":", g_missionManager.missions[key].vehicleUseCost)
            end
            if(g_missionManager.missions[key].vehiclesToLoad ~= nil) then
                plumberWriteMessageToPipe(",\"leasingVehicles\":[")
                for vehiclekey, vehiclevalue in ipairs(g_missionManager.missions[key].vehiclesToLoad) do
                    if(vehiclekey == 1) then
                        plumberWriteMessageToPipe("{\"vehicleNumber\":", vehiclekey)
                    else
                        plumberWriteMessageToPipe(",{\"vehicleNumber\":", vehiclekey)
                    end
                    plumberWriteMessageToPipe(",\"fileName\":\"", g_missionManager.missions[key].vehiclesToLoad[vehiclekey].filename, "\"")
                    plumberWriteMessageToPipe("}")
                end
                plumberWriteMessageToPipe("]")
            end
            plumberWriteMessageToPipe("}")
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeEconomy()
    if(g_fillTypeManager ~= nil) then
        local count = 0
        plumberWriteMessageToPipe("{\"economy\":[")
        for key, value in ipairs(g_fillTypeManager.fillTypes) do
            if(g_fillTypeManager.fillTypes[key].showOnPriceTable) then
                if(count == 0) then
                    plumberWriteMessageToPipe("{\"name\":\"", g_fillTypeManager.fillTypes[key].name, "\"")
                else
                    plumberWriteMessageToPipe(",{\"name\":\"", g_fillTypeManager.fillTypes[key].name, "\"")
                end
                plumberWriteMessageToPipe(",\"history\":[")
                plumberWriteTableToPipe(g_fillTypeManager.fillTypes[key].economy.history)
                plumberWriteMessageToPipe("]}")
                count = count + 1
            end
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeVehicleSales()
    if(g_currentMission ~= nil and g_currentMission.vehicleSaleSystem ~= nil and g_currentMission.vehicleSaleSystem.items ~= nil) then
        plumberWriteMessageToPipe("{\"vehicleSales\":[")

        for key, value in ipairs(g_currentMission.vehicleSaleSystem.items) do
            if(key == 1) then
                plumberWriteMessageToPipe("{\"name\":\"", g_currentMission.vehicleSaleSystem.items[key].xmlFilename, "\"")
            else
                plumberWriteMessageToPipe(",{\"name\":\"", g_currentMission.vehicleSaleSystem.items[key].xmlFilename, "\"")
            end
            plumberWriteMessageToPipe(",\"age\":", g_currentMission.vehicleSaleSystem.items[key].age)
            plumberWriteMessageToPipe(",\"damage\":", g_currentMission.vehicleSaleSystem.items[key].damage)
            plumberWriteMessageToPipe(",\"price\":", g_currentMission.vehicleSaleSystem.items[key].price)
            if(g_currentMission.vehicleSaleSystem.items[key].timeLeft ~= nil) then
                plumberWriteMessageToPipe(",\"timeLeft\":", g_currentMission.vehicleSaleSystem.items[key].timeLeft)
            end
            plumberWriteMessageToPipe(",\"wear\":", g_currentMission.vehicleSaleSystem.items[key].wear)
            plumberWriteMessageToPipe(",\"operatingTime\":", g_currentMission.vehicleSaleSystem.items[key].operatingTime)
            plumberWriteMessageToPipe("}")
        end

        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeVehicles()
    if(g_currentMission ~= nil and g_currentMission.vehicles ~= nil) then
        plumberWriteMessageToPipe("{\"vehicles\":[")

        for key, value in ipairs(g_currentMission.vehicles) do
            if(key == 1) then
                plumberWriteMessageToPipe("{\"name\":\"", g_currentMission.vehicles[key].xmlFile.filename, "\"")
            else
                plumberWriteMessageToPipe(",{\"name\":\"", g_currentMission.vehicles[key].xmlFile.filename, "\"")
            end
            plumberWriteMessageToPipe(",\"brand\":\"", g_currentMission.vehicles[key].brand.title, "\"")
            plumberWriteMessageToPipe(",\"age\":", g_currentMission.vehicles[key].age)
            plumberWriteMessageToPipe(",\"price\":", g_currentMission.vehicles[key].price)
            plumberWriteMessageToPipe(",\"category\":\"", g_currentMission.vehicles[key].typeDesc, "\"")
            plumberWriteMessageToPipe(",\"ownerFarmId\":", g_currentMission.vehicles[key].ownerFarmId)
            plumberWriteMessageToPipe(",\"operatingTime\":", g_currentMission.vehicles[key].operatingTime)
            if(g_currentMission.vehicles[key].currentSavegameId ~= nil) then
                plumberWriteMessageToPipe(",\"id\":", g_currentMission.vehicles[key].currentSavegameId)
            end
            local x,y,z = getWorldTranslation(g_currentMission.vehicles[key].rootNode)
            plumberWriteMessageToPipe(",\"x\":", x)
            plumberWriteMessageToPipe(",\"y\":", y)
            plumberWriteMessageToPipe(",\"z\":", z)
            if(g_currentMission.vehicles[key].spec_fillUnit ~= nil) then
                plumberWriteMessageToPipe(",\"fillUnits\":[")
                local fillCounter = 0;
                for fillkey, fillvalue in ipairs(g_currentMission.vehicles[key].spec_fillUnit.fillUnits) do
                    if(g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].fillType ~= 1) then
                        if(fillCounter == 0) then
                            plumberWriteMessageToPipe("{\"fillType\":", g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].fillType)
                        else
                            plumberWriteMessageToPipe(",{\"fillType\":", g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].fillType)
                        end
                        plumberWriteMessageToPipe(",\"fillLevel\":", g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].fillLevel)
                        plumberWriteMessageToPipe(",\"capacity\":", g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].capacity)
                        if(g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].unitText ~= nil) then
                            plumberWriteMessageToPipe(",\"unitText\":\"", g_currentMission.vehicles[key].spec_fillUnit.fillUnits[fillkey].unitText, "\"")
                        else
                            plumberWriteMessageToPipe(",\"unitText\":\"l\"")
                        end
                        plumberWriteMessageToPipe("}")
                        fillCounter = fillCounter + 1;
                    end
                end
                plumberWriteMessageToPipe("]")
            end
            plumberWriteMessageToPipe("}")
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeNPCs()
    if(g_npcManager ~= nil) then
        plumberWriteMessageToPipe("{\"npcs\":[")
        for key, value in ipairs(g_npcManager.indexToNpc) do
            if(key == 1) then
                plumberWriteMessageToPipe("{\"title\":\"", g_npcManager.indexToNpc[key].title, "\"")
            else
                plumberWriteMessageToPipe(",{\"title\":\"", g_npcManager.indexToNpc[key].title, "\"")
            end
            plumberWriteMessageToPipe(",\"finishedMissions\":", g_npcManager.indexToNpc[key].finishedMissions)
            plumberWriteMessageToPipe("}")
        end
        plumberWriteMessageToPipe("]}")
        plumberFlushPipe()
    end
end

function writeEnvironment()
    if(g_currentMission ~= nil and g_currentMission.environment ~= nil) then
        plumberWriteMessageToPipe("{\"environment\":[")
        plumberWriteMessageToPipe("{\"currentDay\":", g_currentMission.environment.currentDay)
        plumberWriteMessageToPipe(",\"currentDayInPeriod\":", g_currentMission.environment.currentDayInPeriod)
        plumberWriteMessageToPipe(",\"currentDayInSeason\":", g_currentMission.environment.currentDayInSeason)
        plumberWriteMessageToPipe(",\"currentHour\":", g_currentMission.environment.currentHour)
        plumberWriteMessageToPipe(",\"currentMinute\":", g_currentMission.environment.currentMinute)
        plumberWriteMessageToPipe(",\"currentMonotonicDay\":", g_currentMission.environment.currentMonotonicDay)
        plumberWriteMessageToPipe(",\"currentPeriod\":", g_currentMission.environment.currentPeriod)
        plumberWriteMessageToPipe(",\"currentSeason\":", g_currentMission.environment.currentSeason)
        plumberWriteMessageToPipe(",\"currentVisualDayInSeason\":", g_currentMission.environment.currentVisualDayInSeason)
        plumberWriteMessageToPipe(",\"currentVisualPeriod\":", g_currentMission.environment.currentVisualPeriod)
        plumberWriteMessageToPipe(",\"currentVisualSeason\":", g_currentMission.environment.currentVisualSeason)
        plumberWriteMessageToPipe(",\"currentYear\":", g_currentMission.environment.currentYear)
        plumberWriteMessageToPipe(",\"dayTime\":", g_currentMission.environment.dayTime)
        plumberWriteMessageToPipe(",\"daysPerPeriod\":", g_currentMission.environment.daysPerPeriod)

        if(g_currentMission.environment.weather ~= nil and g_currentMission.environment.weather.forecastItems ~= nil) then
            plumberWriteMessageToPipe(",\"forecast\":[")
            for key, value in ipairs(g_currentMission.environment.weather.forecastItems) do
                if(key == 1) then
                    plumberWriteMessageToPipe("{\"duration\":", g_currentMission.environment.weather.forecastItems[key].duration)
                else
                    plumberWriteMessageToPipe(",{\"duration\":", g_currentMission.environment.weather.forecastItems[key].duration)
                end
                plumberWriteMessageToPipe(",\"season\":", g_currentMission.environment.weather.forecastItems[key].season)
                plumberWriteMessageToPipe(",\"type\":", g_currentMission.environment.weather.forecastItems[key].objectIndex)
                plumberWriteMessageToPipe(",\"startDay\":", g_currentMission.environment.weather.forecastItems[key].startDay)
                plumberWriteMessageToPipe(",\"startDayTime\":", g_currentMission.environment.weather.forecastItems[key].startDayTime)
                plumberWriteMessageToPipe(",\"variationIndex\":", g_currentMission.environment.weather.forecastItems[key].variationIndex)
                plumberWriteMessageToPipe("}")
            end
            plumberWriteMessageToPipe("]")
        end
        plumberWriteMessageToPipe("}]}")
        plumberFlushPipe()
    end
end

function plumberWriteTableToPipe(table)
    if(table ~= nil) then
        local count = 0

        for key, value in pairs(table) do
            if(type(value) == 'table') then
                if(count == 0) then
                    plumberWriteMessageToPipe("{\"", key, "\": [")
                else
                    plumberWriteMessageToPipe(",{\"", key, "\": [")
                end
                plumberWriteTableToPipe(value)
                plumberWriteMessageToPipe("]}")
            else
                if(type(value) == 'string') then
                    if(count == 0) then
                        plumberWriteMessageToPipe("{\"", key, "\":\"", value, "\"")
                    else
                        plumberWriteMessageToPipe(",{\"", key, "\":\"", value, "\"")
                    end
                else
                    if(count == 0) then
                        plumberWriteMessageToPipe("{\"", key, "\":", value)
                    else
                        plumberWriteMessageToPipe(",{\"", key, "\":", value)
                    end
                end
                plumberWriteMessageToPipe("}")
            end
            count = count + 1
        end
    end
end