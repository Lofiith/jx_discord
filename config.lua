-- config is server sided, modders wont be able to dump
Config = {}

-- Discord Bot Configuration (Server-Side Only)
Config.Token = '' -- Your Discord Bot Token
Config.Guild = '' -- Your Discord Guild/Server ID

-- Configurations
Config.RequireDiscord = false -- Kick players without Discord
Config.RequireInGuild = false -- Kick players not in the Discord server
Config.KickMessage = 'You must be in our Discord server to play. Join: discord.gg/jxscripts'
Config.RefreshCacheOnConnect = true -- Refresh player data when they connect
Config.CacheTimeout = 300 -- Cache Discord data for 300 seconds (5 minutes)


-- Webhook Configuration
Config.LogWebhookURL = '' -- Discord Webhook URL for connection logs
