local CURRENT_VERSION = '1.0.0'
local VERSION_CHECK_URL = 'https://raw.githubusercontent.com/Lofiith/Versions/main/discord.txt'

CreateThread(function()
    Wait(3000)

    PerformHttpRequest(VERSION_CHECK_URL, function(errorCode, result, headers)
        if errorCode == 200 and result then
            local latestVersion = result:gsub('%s+', '')

            if latestVersion ~= CURRENT_VERSION then
                print(string.format('^8[JX_Discord]^0 ^3[UPDATE]^0: Version ^2%s^0 available (current: ^1%s^0)', latestVersion, CURRENT_VERSION))
                print('^8[JX_Discord]^0 ^3Download:^0 https://github.com/Lofiith/jx_discord')
            else
                print('^8[JX_Discord]^0: You are running the latest version (^2' .. CURRENT_VERSION .. '^0)')
            end
        else
            print('^8[JX_Discord]^0 ^1Version check failed^0 (HTTP ' .. tostring(errorCode) .. ')')
        end
    end, 'GET')
end)
