
-- name: Sodium
-- id: sodium-eagler
-- version: 0.1.0
-- author: UserArham
-- description: Performance-focused settings and FPS HUD for Eaglercraft
-- permissions:
-- homepage: https://eaglercraft.com
-- license: Apache-2.0

local VERSION = "0.1.0"
local PREFIX = "#55CCFF"

-- ==========================================
-- SODIUM SETTINGS
-- ==========================================

settings.toggle("enabled", {
    label = "Sodium Enabled",
    description = "Enable the Sodium performance HUD and settings",
    default = true
})

settings.toggle("fpsHud", {
    label = "FPS Counter",
    description = "Display current FPS",
    default = true
})

settings.toggle("showBranding", {
    label = "Show Branding",
    description = "Display Sodium branding in the HUD",
    default = true
})

settings.toggle("reducedFovEffects", {
    label = "Reduced FOV Effects",
    description = "Reduce camera FOV effects",
    default = true
})

settings.toggle("disableViewBobbing", {
    label = "Disable View Bobbing",
    description = "Disable camera view bobbing",
    default = false
})

settings.slider("renderDistance", {
    label = "Render Distance",
    description = "Preferred render distance in chunks",
    min = 2,
    max = 32,
    step = 1,
    default = 8
})

settings.slider("fpsLimit", {
    label = "FPS Limit",
    description = "Maximum game frame rate; 260 means unlimited",
    min = 10,
    max = 260,
    step = 10,
    default = 260
})

settings.color("hudColor", {
    label = "HUD Color",
    description = "Sodium HUD accent color",
    default = "#55CCFF"
})

-- ==========================================
-- PERFORMANCE SETTINGS
-- ==========================================

local function applySettings()
    if not settings.enabled then
        return
    end

    game.setOption(
        "renderDistance",
        settings.renderDistance
    )

    game.setOption(
        "framerateLimit",
        settings.fpsLimit
    )

    game.setOption(
        "viewBobbing",
        not settings.disableViewBobbing
            and game.option("viewBobbing")
            or false
    )

    if settings.reducedFovEffects then
        game.setOption("fovEffects", 0)
    end
end

-- ==========================================
-- FPS COLOR
-- ==========================================

local function getFPSColor(fps)
    if fps < 30 then
        return "#FF5555"
    elseif fps < 60 then
        return "#FFFF55"
    else
        return "#55FF55"
    end
end

-- ==========================================
-- SODIUM HUD
-- ==========================================

hud.add("sodium_hud", function(ctx)
    if not settings.enabled then
        return
    end

    local fps = game.fps()

    if settings.showBranding then
        ctx:rect(4, 4, 132, 30, "#CC101820")
        ctx:rect(4, 4, 2, 30, settings.hudColor)

        ctx:text(
            "SODIUM EAGLER",
            11,
            8,
            settings.hudColor
        )
    end

    if settings.fpsHud then
        local fpsText = tostring(fps) .. " FPS"

        local y = settings.showBranding and 20 or 5

        ctx:text(
            fpsText,
            11,
            y,
            getFPSColor(fps)
        )
    end
end)

-- ==========================================
-- COMMANDS
-- ==========================================

commands.register(
    "sodium",
    function(args, raw)
        local action = args[1] or "info"

        if action == "on" then
            settings.enabled = true
            applySettings()
            chat.print("Sodium enabled!")

        elseif action == "off" then
            settings.enabled = false
            chat.print("Sodium disabled!")

        elseif action == "settings" then
            settings.open()

        elseif action == "fps" then
            chat.print(
                "Current FPS: " .. tostring(game.fps())
            )

        elseif action == "apply" then
            applySettings()
            chat.print("Sodium settings applied!")

        elseif action == "info" then
            chat.print("Sodium")
            chat.print("Version: " .. VERSION)
            chat.print("Game: " .. tostring(game.version))
            chat.print("/sodium on")
            chat.print("/sodium off")
            chat.print("/sodium fps")
            chat.print("/sodium settings")
            chat.print("/sodium apply")

        else
            chat.print("Unknown Sodium command.")
        end
    end,
    "Sodium performance controls"
)

-- ==========================================
-- SETTING CHANGE HANDLER
-- ==========================================

settings.onChange(function(key, value, old)
    if settings.enabled then
        applySettings()
    end
end)

-- ==========================================
-- MOD INITIALIZATION
-- ==========================================

applySettings()

mod.export = {
    version = VERSION,
    getFPS = function()
        return game.fps()
    end,
    isEnabled = function()
        return settings.enabled
    end
}

chat.print(
    "Sodium " .. VERSION .. " loaded!"
)
