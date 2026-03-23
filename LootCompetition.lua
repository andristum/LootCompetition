LootCompetitionDB = LootCompetitionDB or {
    debug = false,
};

local function IsDebugEnabled()
    return LootCompetitionDB.debug or false
end

local function DebugPrint(...)
    if IsDebugEnabled() then
        print("[LootCompetition Debug]:", ...)
    end
end

local TierTokens = {
    WARRIOR     = "Plate",
    DEATHKNIGHT = "Plate",
    PALADIN     = "Plate",
    ROGUE       = "Leather",
    MONK        = "Leather",
    DRUID       = "Leather",
    DEMONHUNTER = "Leather",
    HUNTER      = "Mail",
    SHAMAN      = "Mail",
    EVOKER      = "Mail",
    MAGE        = "Cloth",
    WARLOCK     = "Cloth",
    PRIEST      = "Cloth",
}

local ClassColors = {
    WARRIOR     = "C69B6D",
    ROGUE       = "FFF468",
    MONK        = "00FF98",
    EVOKER      = "33937F",
    DEATHKNIGHT = "C41E3A",
    DEMONHUNTER = "A330C9",
    WARLOCK     = "8788EE",
    DRUID       = "FF7C0A",
    HUNTER      = "AAD372",
    MAGE        = "3FC7EB",
    PALADIN     = "F48CBA",
    PRIEST      = "FFFFFF",
    SHAMAN      = "0070DD",
}

local CompetitionColors = {
    [1] = "ff8000",
    [2] = "a335ee",
    [3] = "0070dd",
    [4] = "1eff00",
    [5] = "9d9d9d",
}
local CompetitionColorFallback = "9d9d9d"

-- UTILITY FUNCTIONS

local function GetPlayerClass()
    local _, class = UnitClass("player")
    DebugPrint("Player class detected:", class)
    return class
end

local function GetClassColor(class)
    return ClassColors[class] or "FFFFFF"
end

local function FormatClassName(class)
    local color = GetClassColor(class)
    local displayName = LOCALIZED_CLASS_NAMES_MALE[class] or class
    return "|cff" .. color .. displayName .. "|r"
end

local function FormatCompetitionLabel(label, count)
    if not count or count <= 0 then
        DebugPrint("No competition count to format.")
        return nil
    end
    local hex = CompetitionColors[count] or CompetitionColorFallback
    return "|cff" .. hex .. label .. "|r"
end

local function GetLootDrops(groupSize)
    if groupSize < 10 then
        return 1
    end
    return math.floor(groupSize / 5)
end
local function GetCompetitionColorIndex(competitionPerDrop)
    if competitionPerDrop < 1.0 then
        return 1  -- Legendary
    elseif competitionPerDrop < 1.2 then
        return 2  -- Epic
    elseif competitionPerDrop < 1.5 then
        return 3  -- Rare
    elseif competitionPerDrop < 2.5 then
        return 4  -- Uncommon
    else
        return 5  -- Common
    end
end

-- TIER COMPETITION
local function GetTierCompetitionForGroup(resultID)
    DebugPrint("Getting tier competition for group with resultID:", resultID)
    local info = C_LFGList.GetSearchResultInfo(resultID)
    if not info or (info.numMembers or 0) == 0 then
        DebugPrint("No group info or members found.")
        return 0, {}, 0
    end

    local playerClass = GetPlayerClass()
    local playerToken = TierTokens[playerClass]
    if not playerToken then
        DebugPrint("Player token not found for class:", playerClass)
        return 0, {}, 0
    end

    local competitors = {}
    local count = 0

    for i = 1, info.numMembers do
        local member = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
        if member and member.classFilename then
            local class = member.classFilename
            if TierTokens[class] == playerToken then
                count = count + 1
                table.insert(competitors, FormatClassName(class))
            end
        end
    end

    DebugPrint("Total tier competition count:", count, "Group size:", info.numMembers)
    return count, competitors, info.numMembers
end

-- TOOLTIP HOOK
hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
    DebugPrint("Setting tooltip for resultID:", resultID)
    if not resultID then return end

    local info = C_LFGList.GetSearchResultInfo(resultID)
    if not info or not info.activityIDs then
        DebugPrint("No activity IDs found for group.")
        return
    end

    local activityInfo = C_LFGList.GetActivityInfoTable(info.activityIDs[1])
    
    if not activityInfo or activityInfo.categoryID ~= 3 then
        DebugPrint("Group is not a raid. Skipping tooltip.")
        return
    end

    tooltip:AddLine(" ")

    local count, competitors, groupSize = GetTierCompetitionForGroup(resultID)

    if count > 0 then
        local lootDrops = GetLootDrops(groupSize)
        local competitionPerDrop = count / lootDrops
        local colorIndex = GetCompetitionColorIndex(competitionPerDrop)
        local formattedLabel = FormatCompetitionLabel("", colorIndex)
        
        local colorLabels = {
            [1] = "Excellent",
            [2] = "Very Good",
            [3] = "Good",
            [4] = "Fair",
            [5] = "Poor",
        }
        local labelText = colorLabels[colorIndex] or "Unknown"
        
        tooltip:AddLine(("Possible Tier Competition: %s (%d competitors, %d drops)"):format(
            "|cff" .. CompetitionColors[colorIndex] .. labelText .. "|r", count, lootDrops
        ), 1, 0.85, 0)

        local classCounts = {}
        for _, className in ipairs(competitors) do
            classCounts[className] = (classCounts[className] or 0) + 1
        end

        for className, classCount in pairs(classCounts) do
            if classCount > 1 then
                tooltip:AddLine(("   %d %s"):format(classCount, className), 1, 0.85, 0)
            else
                tooltip:AddLine(("      %s"):format(className), 1, 0.85, 0)
            end
        end
    else
        tooltip:AddLine("Possible Tier Competition: |cff" .. CompetitionColors[1] .. "None", 1, 0.85, 0)
    end

    tooltip:Show()
end)