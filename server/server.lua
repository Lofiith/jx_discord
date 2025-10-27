local playerCache = {}
local rateLimit = {}
local guildRoles = {}

-- Helper: Get Discord ID
local function getDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.match(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    return nil
end

local function isRateLimited(discordId)
    if not rateLimit[discordId] then return false end
    return (GetGameTimer() - rateLimit[discordId]) < 1000
end

-- Webhook sender
local function sendWebhook(webhookUrl, data)
    if not webhookUrl or webhookUrl == '' then return end
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode(data), {
        ['Content-Type'] = 'application/json'
    })
end

-- HTTP GET to Discord API
local function makeRequest(endpoint, callback)
    PerformHttpRequest("https://discord.com/api/v10" .. endpoint, function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            callback(true, data)
        else
            print(string.format('^8[JX_Discord] ^1[ERROR]^0: HTTP request failed (%s)', err))
            callback(false, nil)
        end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. Config.Token,
        ['Content-Type'] = 'application/json'
    })
end

-- Get Discord user info
local function getDiscordUser(discordId, callback)
    if playerCache[discordId] and playerCache[discordId].user and
        (GetGameTimer() - playerCache[discordId].lastUpdate) < (Config.CacheTimeout * 1000) then
        callback(true, playerCache[discordId].user)
        return
    end

    makeRequest("/users/" .. discordId, function(success, data)
        if success then
            if not playerCache[discordId] then playerCache[discordId] = {} end

            local avatar = data.avatar and ("https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. data.avatar .. ".png") or nil

            playerCache[discordId].user = {
                id = data.id,
                username = data.username,
                avatar = avatar,
                discriminator = data.discriminator
            }
            playerCache[discordId].lastUpdate = GetGameTimer()

            callback(true, playerCache[discordId].user)
        else
            callback(false, nil)
        end
    end)
end

-- Get guild member info
local function getGuildMember(discordId, callback)
    if playerCache[discordId] and playerCache[discordId].member and
        (GetGameTimer() - playerCache[discordId].lastUpdate) < (Config.CacheTimeout * 1000) then
        callback(true, playerCache[discordId].member)
        return
    end

    makeRequest("/guilds/" .. Config.Guild .. "/members/" .. discordId, function(success, data)
        if success then
            if not playerCache[discordId] then playerCache[discordId] = {} end

            playerCache[discordId].member = {
                roles = data.roles or {},
                nick = data.nick,
                joined_at = data.joined_at
            }
            playerCache[discordId].lastUpdate = GetGameTimer()

            callback(true, playerCache[discordId].member)
        else
            callback(false, nil)
        end
    end)
end

local function updateGuildRoles()
    makeRequest("/guilds/" .. Config.Guild .. "/roles", function(success, data)
        if success then
            guildRoles = {}
            for _, role in pairs(data) do
                guildRoles[role.id] = role.name
            end
            print(string.format('^8[JX_Discord] ^2[SUCCESS]^0: Guild roles updated (^2%s^0 roles cached)', #data))
        end
    end)
end

local function logPlayerConnection(playerName, discordId)
    getDiscordUser(discordId, function(userSuccess, userData)
        getGuildMember(discordId, function(memberSuccess, memberData)
            local roleNames = {}
            local roleCount = 0

            if memberSuccess and memberData.roles then
                roleCount = #memberData.roles
                for _, roleId in pairs(memberData.roles) do
                    if guildRoles[roleId] then
                        table.insert(roleNames, guildRoles[roleId])
                    end
                end
            end

            print(string.format('^8[JX_Discord] ^3[INFO]^0: %s connected with %s roles', playerName, roleCount))

            if Config.LogWebhookURL ~= '' and userSuccess then
                sendWebhook(Config.LogWebhookURL, {
                    embeds = {{
                        title = "🎮 Player Connected",
                        color = 0xE82546, -- Hex color E82546
                        thumbnail = {
                            url = userData.avatar or "https://cdn.discordapp.com/embed/avatars/0.png"
                        },
                        description = string.format(
                            "> **Player:** %s\n> **Discord:** %s\n> **Role Count:** %s\n> **Discord ID:** `%s`\n\n**Roles:** %s",
                            playerName,
                            userData.username,
                            roleCount,
                            discordId,
                            (#roleNames > 0 and table.concat(roleNames, ", ") or "None")
                        ),
                        footer = {
                            text = "JX_Discord • Connection Log",
                            icon_url = "https://cdn-icons-png.flaticon.com/512/906/906361.png"
                        },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                })
            end
        end)
    end)
end

-- Player connecting event
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local source = source
    local discordId = getDiscordId(source)

    deferrals.defer()
    deferrals.update("Checking Discord status...")

    if Config.RequireDiscord and not discordId then
        deferrals.done(Config.KickMessage)
        print(string.format('^8[JX_Discord] ^3[WARN]^0: %s kicked - No Discord linked', playerName))
        return
    end

    if not discordId then
        deferrals.done()
        return
    end

    if Config.RequireInGuild then
        deferrals.update("Verifying Discord server membership...")
        getGuildMember(discordId, function(success, memberData)
            if not success then
                deferrals.done(Config.KickMessage)
                print(string.format('^8[JX_Discord] ^3[WARN]^0: %s kicked - Not in Discord server', playerName))
                return
            end
            logPlayerConnection(playerName, discordId)
            deferrals.done()
        end)
    else
        logPlayerConnection(playerName, discordId)
        deferrals.done()
    end
end)

-- Initialization
CreateThread(function()
    if Config.Token == '' or Config.Guild == '' then
        print('^8[JX_Discord] ^1[ERROR]^0: Token or Guild ID not configured! Please edit config.lua')
        return
    end

    updateGuildRoles()
    print('^8[JX_Discord] ^2[SUCCESS]^0: Initialized successfully')

    while true do
        Wait(600000) -- every 10 minutes
        updateGuildRoles()
    end
end)

-- Exports
exports('GetPlayerDiscordId', getDiscordId)

exports('GetPlayerAvatar', function(source, callback)
    local discordId = getDiscordId(source)
    if not discordId then return callback(false, nil) end
    if isRateLimited(discordId) then return callback(false, "Rate limited") end

    rateLimit[discordId] = GetGameTimer()
    if Config.RefreshCacheOnConnect then playerCache[discordId] = nil end

    getDiscordUser(discordId, function(success, userData)
        callback(success, success and userData.avatar or nil)
    end)
end)

exports('GetPlayerUsername', function(source, callback)
    local discordId = getDiscordId(source)
    if not discordId then return callback(false, nil) end
    if isRateLimited(discordId) then return callback(false, "Rate limited") end

    rateLimit[discordId] = GetGameTimer()
    getDiscordUser(discordId, function(success, userData)
        callback(success, success and userData.username or nil)
    end)
end)

exports('GetPlayerRoles', function(source, callback)
    local discordId = getDiscordId(source)
    if not discordId then return callback(false, nil) end
    if isRateLimited(discordId) then return callback(false, "Rate limited") end

    rateLimit[discordId] = GetGameTimer()
    getGuildMember(discordId, function(success, memberData)
        if not success then return callback(false, nil) end
        local roleNames = {}
        for _, roleId in pairs(memberData.roles) do
            if guildRoles[roleId] then table.insert(roleNames, guildRoles[roleId]) end
        end
        callback(true, roleNames)
    end)
end)

exports('HasPlayerRole', function(source, roleNameOrId, callback)
    local discordId = getDiscordId(source)
    if not discordId or isRateLimited(discordId) then return callback(false) end

    rateLimit[discordId] = GetGameTimer()
    getGuildMember(discordId, function(success, memberData)
        if not success then return callback(false) end
        for _, roleId in pairs(memberData.roles) do
            if guildRoles[roleId] == roleNameOrId or roleId == roleNameOrId then
                return callback(true)
            end
        end
        callback(false)
    end)
end)

exports('GetPlayerInfo', function(source, callback)
    local discordId = getDiscordId(source)
    if not discordId or isRateLimited(discordId) then return callback(false, nil) end

    rateLimit[discordId] = GetGameTimer()
    getDiscordUser(discordId, function(success, userData)
        if not success then return callback(false, nil) end
        getGuildMember(discordId, function(memberSuccess, memberData)
            local roleNames = {}
            if memberSuccess then
                for _, roleId in pairs(memberData.roles) do
                    if guildRoles[roleId] then table.insert(roleNames, guildRoles[roleId]) end
                end
            end
            callback(true, {
                id = userData.id,
                username = userData.username,
                avatar = userData.avatar,
                roles = roleNames,
                roleCount = #roleNames
            })
        end)
    end)
end)
