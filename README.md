# JX Discord API

A lightweight, optimized FiveM Discord integration script that provides seamless Discord API functionality for your server.

## Features

- ✅ **Discord Requirements**: Enforce Discord linking and server membership
- ✅ **Player Data**: Get avatars, usernames, roles, and Discord IDs
- ✅ **Role Checking**: Verify if players have specific roles
- ✅ **Webhook Logging**: Rich connection logs with player Discord info
- ✅ **Auto Cache**: Automatic caching with refresh on connect
- ✅ **Rate Limiting**: Built-in protection against API spam
- ✅ **Lightweight**: Optimized for performance

## Installation

1. **Download** and place in your `resources` folder
2. **Rename** folder to `jx_discord` (or keep as `JX_Discord`)
3. **Add** to your `server.cfg`:
   ```
   ensure jx_discord
   ```

## Configuration

Edit `config.lua`:

```lua
Config = {}

-- Discord Bot Configuration (Server-Side Only)
Config.Token = 'YOUR_BOT_TOKEN_HERE'          -- Discord Bot Token
Config.Guild = 'YOUR_GUILD_ID_HERE'           -- Discord Server ID

-- Discord Requirements
Config.RequireDiscord = true                  -- Kick players without Discord
Config.RequireInGuild = true                  -- Kick players not in Discord server
Config.KickMessage = 'Join our Discord: discord.gg/yourserver'

-- Auto Cache Management
Config.RefreshCacheOnConnect = true           -- Refresh player data on connect

-- Webhook Configuration
Config.LogWebhookURL = 'YOUR_WEBHOOK_URL'     -- Connection logs webhook
```

## Setting Up Discord Bot

1. **Create Application**: Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. **Create Bot**: In your application, go to "Bot" section
3. **Get Token**: Copy the bot token to `Config.Token`
4. **Bot Permissions**: Give your bot these permissions:
   - View Channels
   - Read Message History
5. **Get Guild ID**: Enable Developer Mode in Discord → Right-click your server → Copy ID
6. **Invite Bot**: Use OAuth2 URL Generator with the permissions above

## Exports

### Basic Player Info

#### `GetPlayerDiscordId(source)`
Returns the player's Discord ID immediately (no callback).

```lua
local discordId = exports.jx_discord:GetPlayerDiscordId(source)
if discordId then
    print("Player Discord ID: " .. discordId)
else
    print("Player doesn't have Discord linked")
end
```

---

#### `GetPlayerAvatar(source, callback)`
Gets the player's Discord avatar URL.

```lua
exports.jx_discord:GetPlayerAvatar(source, function(success, avatarUrl)
    if success and avatarUrl then
        print("Avatar: " .. avatarUrl)
        -- Use avatarUrl for UI, etc.
    else
        print("No avatar found or error occurred")
    end
end)
```

---

#### `GetPlayerUsername(source, callback)`
Gets the player's Discord username.

```lua
exports.jx_discord:GetPlayerUsername(source, function(success, username)
    if success and username then
        print("Discord Username: " .. username)
    else
        print("Failed to get username")
    end
end)
```

---

### Role Management

#### `GetPlayerRoles(source, callback)`
Gets an array of all role names the player has.

```lua
exports.jx_discord:GetPlayerRoles(source, function(success, roles)
    if success and roles then
        print("Player has " .. #roles .. " roles:")
        for _, roleName in ipairs(roles) do
            print("- " .. roleName)
        end
    else
        print("Failed to get roles")
    end
end)
```

---

#### `HasPlayerRole(source, roleNameOrId, callback)`
Checks if a player has a specific role by name OR role ID.

```lua
-- Check by role name
exports.jx_discord:HasPlayerRole(source, "VIP", function(hasRole)
    if hasRole then
        print("Player is VIP!")
        -- Give VIP benefits
    else
        print("Player is not VIP")
    end
end)

-- Check by role ID  
exports.jx_discord:HasPlayerRole(source, "123456789012345678", function(hasRole)
    if hasRole then
        print("Player has the specific role!")
    end
end)
```

---

### Complete Player Data

#### `GetPlayerInfo(source, callback)`
Gets all player Discord information in one call (most efficient).

```lua
exports.jx_discord:GetPlayerInfo(source, function(success, data)
    if success and data then
        print("Discord ID: " .. data.id)
        print("Username: " .. data.username)
        print("Avatar: " .. (data.avatar or "No avatar"))
        print("Role Count: " .. data.roleCount)
        print("Roles: " .. table.concat(data.roles, ", "))
    else
        print("Failed to get player info")
    end
end)
```

**Returns:**
```lua
{
    id = "123456789012345678",           -- Discord ID
    username = "PlayerName",             -- Discord username  
    avatar = "https://cdn.discord...",   -- Avatar URL (or nil)
    roles = {"Admin", "VIP", "Member"},  -- Array of role names
    roleCount = 3                        -- Number of roles
}
```

---

## Usage Examples

### Permission System
```lua
-- Check if player is staff (by role name)
exports.jx_discord:HasPlayerRole(source, "Staff", function(isStaff)
    if isStaff then
        -- Allow staff commands
        TriggerClientEvent('openStaffMenu', source)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {"You need Staff role to use this command"}
        })
    end
end)

-- Check by role ID (more reliable)
exports.jx_discord:HasPlayerRole(source, "987654321098765432", function(isAdmin)
    if isAdmin then
        -- Allow admin commands
        TriggerClientEvent('openAdminPanel', source)
    end
end)
```

### VIP System
```lua
-- Check multiple VIP roles
RegisterCommand('vip', function(source, args)
    exports.jx_discord:GetPlayerRoles(source, function(success, roles)
        if success then
            local isVIP = false
            local vipRoles = {"VIP", "Premium", "Donator"}
            
            for _, playerRole in ipairs(roles) do
                for _, vipRole in ipairs(vipRoles) do
                    if playerRole == vipRole then
                        isVIP = true
                        break
                    end
                end
            end
            
            if isVIP then
                -- Give VIP benefits
                TriggerClientEvent('giveVIPCar', source)
            end
        end
    end)
end)
```

### Player Info Display
```lua
RegisterCommand('discordinfo', function(source, args)
    exports.jx_discord:GetPlayerInfo(source, function(success, data)
        if success then
            TriggerClientEvent('chat:addMessage', source, {
                args = {
                    "Your Discord Info:",
                    "Username: " .. data.username,
                    "Roles: " .. table.concat(data.roles, ", ")
                }
            })
        end
    end)
end)
```

## Webhook Features

When `Config.LogWebhookURL` is configured, the script sends embeds when players connect:

- **Player avatar** as thumbnail
- **Discord username**
- **FiveM player name**  
- **Role names** (comma-separated)
- **Role IDs** (in separate field)
- **Role count**
- **Discord ID**
- **Connection timestamp**

## Performance Notes

- **Caching**: Player data is cached for 5 minutes to reduce API calls
- **Rate Limiting**: 1-second cooldown per player to prevent spam
- **Auto Refresh**: Cache refreshes on player connect if enabled
- **Minimal API Calls**: Efficient HTTP request management

## Troubleshooting

### Common Issues

**"Player kicked - No Discord linked"**
- Player needs to link Discord to FiveM
- Check if `Config.RequireDiscord` is enabled

**"Player kicked - Not in Discord server"**  
- Player must join your Discord server
- Verify `Config.Guild` ID is correct
- Bot must be in the server with proper permissions

**"HTTP Error: 401"**
- Invalid bot token in `Config.Token`
- Bot token may have been regenerated

**"HTTP Error: 403"**
- Bot missing permissions
- Bot not in the Discord server
- Invalid Guild ID

**"HTTP Error: 429"**  
- Rate limited by Discord
- Script has built-in rate limiting to prevent this

### Debug Steps

1. **Check Console**: Look for colored `[JX_Discord]` messages
2. **Verify IDs**: Ensure Guild ID and Bot Token are correct  
3. **Bot Permissions**: Confirm bot has "View Channels" permission
4. **Test Exports**: Use commands to test exports individually

## Support

- **Discord**: [https://discord.gg/VuMcnbmEby]
- **Documentation**: This README

---

**Made with ❤️ for the FiveM community**
