local ADDON_NAME = "LootCompetition"
local addonTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title")
addonTitle = addonTitle:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

LootCompetitionDB = LootCompetitionDB or {
    debug = false,
};

local category;
function RegisterLootCompetitionSettings()
    category = Settings.RegisterVerticalLayoutCategory(addonTitle);
    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "LC_DEBUG",
            "debug",
            LootCompetitionDB,
            Settings.VarType.Boolean,
            "Enable Debug Mode",
            Settings.Default.False
        );

        setting:SetValueChangedCallback(function(_, value)
            local message = value and "Debug mode |cff00ff00enabled|r" or "Debug mode |cffff0000disabled|r";
            print("|cffe6c619" .. addonTitle .. ":|r " .. message);
        end);

        Settings.CreateCheckbox(category, setting);
    end

    Settings.RegisterAddOnCategory(category);
end

RegisterLootCompetitionSettings()