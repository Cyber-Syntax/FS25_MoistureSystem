---
-- CombineExtension
-- Manages moisture tracking lifecycle in combines
---

MSCombineExtension = {}

---
-- Extended to reset moisture tracking when tank is emptied
-- @param superFunc: Original function
-- @param fillUnitIndex: The fill unit that changed
-- @param fillLevelDelta: Change in fill level
-- @param fillTypeIndex: Type of fill
-- @param toolType: Tool type
-- @param fillPositionData: Position data
-- @param appliedDelta: Actually applied delta
---
function MSCombineExtension:onFillUnitFillLevelChanged(superFunc, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType,
                                                       fillPositionData, appliedDelta)
    -- Call original function
    if superFunc ~= nil then
        superFunc(self, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
    end

    if not g_currentMission.MoistureSystem.missionStarted then
        return
    end

    -- Only handle on server
    if not self.isServer then
        return
    end

    local moistureSystem = g_currentMission.MoistureSystem
    if not moistureSystem:shouldTrackFillType(fillTypeIndex) then
        return
    end

    local spec = self.spec_combine
    if spec == nil then
        return
    end

    -- Check if this is the main fill unit or buffer
    if fillUnitIndex ~= spec.fillUnitIndex and fillUnitIndex ~= spec.bufferFillUnitIndex then
        return
    end

    -- If fill level is now zero or near zero, clear moisture tracking for this fillType
    local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
    if fillLevel <= 0.001 then
        if moistureSystem and self.uniqueId and fillTypeIndex then
            -- Clear moisture for this specific fillType
            moistureSystem:setObjectMoisture(self.uniqueId, fillTypeIndex, nil)
        end
    end
end

---
-- Extended to track dropped straw with moisture from current location
-- @param superFunc: Original function
-- @param workArea: Work area data
-- @return litersToDrop, droppedLiters (always 1, 1 from original)
---
function MSCombineExtension:processCombineSwathArea(superFunc, workArea)
    local spec = self.spec_combine

    local droppedLitersBefore = spec and spec.workAreaParameters and spec.workAreaParameters.droppedLiters or 0

    local result1, result2 = superFunc(self, workArea)

    if g_currentMission.MoistureSystem.missionStarted and self.isServer and spec ~= nil then
        local droppedLitersAfter = spec.workAreaParameters.droppedLiters or 0
        local actualDropped = droppedLitersAfter - droppedLitersBefore

        if actualDropped > 0 then
            local moistureSystem = g_currentMission.MoistureSystem

            local fruitDesc = g_fruitTypeManager:getFruitTypeByFillTypeIndex(spec.workAreaParameters.dropFillType)
            if fruitDesc ~= nil and fruitDesc.windrowLiterPerSqm ~= nil then
                local windrowFillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitDesc.index)

                if windrowFillType == FillType.STRAW then
                    local sx, sy, sz = getWorldTranslation(workArea.start)
                    local wx, wy, wz = getWorldTranslation(workArea.width)
                    local hx, hy, hz = getWorldTranslation(workArea.height)

                    local centerX = (sx + wx + hx) / 3
                    local centerZ = (sz + wz + hz) / 3
                    local moisture = moistureSystem:getMoistureAtPosition(centerX, centerZ)

                    g_currentMission.groundPropertyTracker:addPile(
                        sx, sz, wx, wz, hx, hz,
                        windrowFillType,
                        actualDropped,
                        { moisture = moisture }
                    )
                end
            end
        end
    end

    return result1, result2
end

-- Hook into Combine specialization
Combine.onFillUnitFillLevelChanged = Utils.overwrittenFunction(
    Combine.onFillUnitFillLevelChanged,
    MSCombineExtension.onFillUnitFillLevelChanged
)

Combine.processCombineSwathArea = Utils.overwrittenFunction(
    Combine.processCombineSwathArea,
    MSCombineExtension.processCombineSwathArea
)
