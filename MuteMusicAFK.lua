-- Initialize saved variables
MuteMusicAFKDB = MuteMusicAFKDB or {}

local frame = CreateFrame("Frame")
local muteTimer = nil
local savedMusicSetting = nil

-- Helper function for addon messages
local function AddonMessage(msg)
    print("|cFF00FF00[Mute Music AFK]|r " .. msg)
end

frame:RegisterEvent("PLAYER_CAMPING")
frame:RegisterEvent("LOGOUT_CANCEL")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_CAMPING" then
        -- Only proceed if player is actually AFK (auto-logout, not manual logout)
        if UnitIsAFK("player") then
            -- Check current music setting
            savedMusicSetting = GetCVar("Sound_EnableMusic")

            -- Only proceed if music is currently ENABLED
            -- If user already has music disabled, respect that and do nothing
            if savedMusicSetting == "1" then
                -- Notify user
                AddonMessage(
                    "AFK logout detected. Music will be muted in 19 seconds to silence the login screen. Cancel logout to prevent this.")

                -- Start 19 second timer to mute music (1 second before logout)
                muteTimer = C_Timer.After(19, function()
                    SetCVar("Sound_EnableMusic", "0")
                    -- Mark that we auto-muted and save what it was
                    MuteMusicAFKDB.autoMuted = true
                    MuteMusicAFKDB.savedSetting = savedMusicSetting
                    muteTimer = nil
                end)
            end
            -- If music already disabled, do nothing
        end
        -- If not AFK, do nothing (manual logout)
    elseif event == "LOGOUT_CANCEL" then
        -- Option 1: Cancel the mute timer if still pending
        if muteTimer then
            muteTimer:Cancel()
            muteTimer = nil
            savedMusicSetting = nil
        end
        -- Reset the variable
        MuteMusicAFKDB.autoMuted = false
        MuteMusicAFKDB.savedSetting = nil
    elseif event == "PLAYER_LOGIN" then
        -- Option 2: User logged back in, check if we auto-muted
        if MuteMusicAFKDB.autoMuted and MuteMusicAFKDB.savedSetting then
            -- Restore music to what it was before we muted
            SetCVar("Sound_EnableMusic", MuteMusicAFKDB.savedSetting)
            -- Notify user
            AddonMessage("Your last logout was automatic. Music has been re-enabled.")
            -- Reset variables to default
            MuteMusicAFKDB.autoMuted = false
            MuteMusicAFKDB.savedSetting = nil
        end
    end
end)
