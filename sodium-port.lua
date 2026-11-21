
-- name: Sodium
-- id: sodium-eagler
-- version: 0.1.1
-- author: UserArham
-- description: Performance-focused settings and FPS HUD for Eaglercraft
-- homepage: https://eaglercraft.com
-- license: Apache-2.0

local VERSION = "0.1.1"

-- ==========================================
-- SODIUM SETTINGS
-- ==========================================

settings.toggle("enabled", {
    label = "Sodium Enabled",
    description = "Enable or disable Sodium",
    default = true
})

settings.toggle("fpsHud", {
    label = "FPS Counter",
    description = "Display current FPS",
    default = true
})

settings.toggle("showBranding", {
    label = "Show Branding",
    description = "Display Sodium branding",
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
    description = "260 means unlimited",
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
-- SAVE ORIGINAL GAME OPTIONS
-- ==========================================

local originalOptions = {
    renderDistance = game.option("renderDistance"),
    framerateLimit = game.option("framerateLimit"),
    viewBobbing = game.option("viewBobbing"),
    fovEffects = game.option("fovEffects")
}

-- ==========================================
-- RESTORE ORIGINAL OPTIONS
-- ==========================================

local function restoreOptions()
    game.setOption(
        "renderDistance",
        originalOptions.renderDistance
    )

    game.setOption(
        "framerateLimit",
        originalOptions.framerateLimit
    )

    game.setOption(
        "viewBobbing",
        originalOptions.viewBobbing
    )

    game.setOption(
        "fovEffects",
        originalOptions.fovEffects
    )
end

-- ==========================================
-- APPLY SODIUM SETTINGS
-- ==========================================

local function applySettings()

    if not settings.enabled then
        restoreOptions()
        return
    end

    -- Render distance
    game.setOption(
        "renderDistance",
        settings.renderDistance
    )

    -- FPS limit
    game.setOption(
        "framerateLimit",
        settings.fpsLimit
    )

    -- View bobbing
    if settings.disableViewBobbing then
        game.setOption("viewBobbing", false)
    else
        game.setOption(
            "viewBobbing",
            originalOptions.viewBobbing
        )
    end

    -- FOV effects
    if settings.reducedFovEffects then
        game.setOption("fovEffects", 0)
    else
        game.setOption(
            "fovEffects",
            originalOptions.fovEffects
        )
    end
end

-- ==========================================
-- FPS COLOR
-- ==========================================

local function getFPSColor(fps)

    if fps < 30 then
        return "#FFFF5555"

    elseif fps < 60 then
        return "#FFFFFF55"

    else
        return "#FF55FF55"
    end
end

-- ==========================================
-- SODIUM HUD
-- ==========================================

hud.add("sodium_hud", function(ctx)

    if not settings.enabled then
        return
    end

    if not settings.fpsHud
        and not settings.showBranding then
        return
    end

    local fps = game.fps()
    local hudColor = settings.hudColor

    -- Branding background
    if settings.showBranding then

        ctx:rect(
            4, 4,
            132, 30,
            "#CC101820"
        )

        ctx:rect(
            4, 4,
            2, 30,
            hudColor
        )

        ctx:text(
            "SODIUM",
            11, 8,
            hudColor
        )

    end

    -- FPS counter
    if settings.fpsHud then

        local fpsText = tostring(fps) .. " FPS"

        local y = 5

        if settings.showBranding then
            y = 20
        end

        ctx:text(
            fpsText,
            11,
            y,
            getFPSColor(fps)
        )

    end

end)

-- ==========================================
-- SODIUM COMMAND
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
            applySettings()

            chat.print("Sodium disabled!")
            chat.print("Original game options restored.")

        elseif action == "fps" then

            chat.print(
                "Current FPS: " .. tostring(game.fps())
            )

        elseif action == "settings" then

            settings.open()

        elseif action == "apply" then

            applySettings()

            chat.print("Sodium settings applied!")

        elseif action == "info" then

            chat.print("Sodium Eagler Edition")
            chat.print("Version: " .. VERSION)
            chat.print("Game: " .. tostring(game.version))
            chat.print("/sodium on")
            chat.print("/sodium off")
            chat.print("/sodium fps")
            chat.print("/sodium settings")
            chat.print("/sodium apply")

        else

            chat.print("Unknown Sodium command.")
            chat.print("Use /sodium for help.")

        end

    end,

    "Sodium performance controls"
)

-- ==========================================
-- SETTINGS CHANGE HANDLER
-- ==========================================

settings.onChange(function(key, value, old)

    applySettings()

end)

-- ==========================================
-- MOD EXPORTS
-- ==========================================

mod.export = {

    version = VERSION,

    getFPS = function()
        return game.fps()
    end,

    isEnabled = function()
        return settings.enabled
    end,

    getRenderDistance = function()
        return game.option("renderDistance")
    end,

    apply = function()
        applySettings()
    end

}

-- ==========================================
-- INITIALIZATION
-- ==========================================

applySettings()

chat.print(
    "Sodium " .. VERSION .. " loaded!"
)
