
-- name: Sodium
-- id: sodium
-- version: 0.2.3
-- author: UserArham
-- description: Performance settings and FPS HUD for Eaglercraft 26.2 and 26.3

-- ============================================
-- ORIGINAL GAME SETTINGS
-- ============================================

local original = {
    renderDistance = game.option("renderDistance"),
    framerateLimit = game.option("framerateLimit"),
    viewBobbing = game.option("viewBobbing"),
    fovEffects = game.option("fovEffects")
}

-- ============================================
-- SETTINGS
-- ============================================

settings.toggle("enabled", {
    label = "Enable Sodium",
    default = true
})

settings.toggle("fpsHud", {
    label = "Show FPS Counter",
    default = true
})

settings.toggle("showBranding", {
    label = "Show Sodium Branding",
    default = true
})

settings.toggle("reduceFov", {
    label = "Reduce FOV Effects",
    default = true
})

settings.toggle("disableBobbing", {
    label = "Disable View Bobbing",
    default = false
})

settings.slider("renderDistance", {
    label = "Render Distance",
    min = 2,
    max = 32,
    step = 1,
    default = 6
})

settings.slider("fpsLimit", {
    label = "FPS Limit",
    min = 10,
    max = 260,
    step = 10,
    default = 120
})

settings.color("hudColor", {
    label = "HUD Color",
    default = 0xFF55CCFF
})

-- ============================================
-- PERFORMANCE STATE
-- ============================================

local state = {
    fps = 0,
    averageFPS = 0,
    frameTime = 0,
    enabled = true,
    sampleTimer = 0
}

-- ============================================
-- FPS COLOR SYSTEM
-- ============================================

local function getFPSColor(fps)
    if fps >= 66 then
        return "#3399FF" -- Blue
    elseif fps >= 50 then
        return "#55DD55" -- Green
    elseif fps >= 25 then
        return "#FFFF00" -- Yellow
    elseif fps >= 18 then
        return "#FF8800" -- Orange
    else
        return "#FF3333" -- Red
    end
end

-- ============================================
-- RESTORE ORIGINAL OPTIONS
-- ============================================

local function restoreOptions()
    if original.renderDistance ~= nil then
        game.setOption("renderDistance", original.renderDistance)
    end

    if original.framerateLimit ~= nil then
        game.setOption("framerateLimit", original.framerateLimit)
    end

    if original.viewBobbing ~= nil then
        game.setOption("viewBobbing", original.viewBobbing)
    end

    if original.fovEffects ~= nil then
        game.setOption("fovEffects", original.fovEffects)
    end
end

-- ============================================
-- APPLY SETTINGS
-- ============================================

local function applySettings()
    if not settings.enabled then
        restoreOptions()
        state.enabled = false
        return
    end

    state.enabled = true

    game.setOption(
        "renderDistance",
        settings.renderDistance
    )

    game.setOption(
        "framerateLimit",
        settings.fpsLimit
    )

    if settings.disableBobbing then
        game.setOption("viewBobbing", false)
    elseif original.viewBobbing ~= nil then
        game.setOption(
            "viewBobbing",
            original.viewBobbing
        )
    end

    if settings.reduceFov then
        game.setOption("fovEffects", 0)
    elseif original.fovEffects ~= nil then
        game.setOption(
            "fovEffects",
            original.fovEffects
        )
    end
end

-- ============================================
-- FPS UPDATE
-- ============================================

local function updatePerformance(dt)
    if not state.enabled then
        return
    end

    if not game.inWorld() or game.isPaused() then
        return
    end

    state.sampleTimer = state.sampleTimer + dt

    -- Update four times per second.
    if state.sampleTimer < 0.25 then
        return
    end

    state.sampleTimer = 0

    local currentFPS = game.fps()

    if currentFPS and currentFPS > 0 then
        state.fps = currentFPS
        state.frameTime = 1000 / currentFPS

        if state.averageFPS == 0 then
            state.averageFPS = currentFPS
        else
            state.averageFPS =
                state.averageFPS * 0.85 +
                currentFPS * 0.15
        end
    end
end

on("frame", function(dt)
    updatePerformance(dt)
end)

-- ============================================
-- FPS HUD
-- ============================================

hud.add("sodium_hud", function(ctx)
    if not settings.enabled then
        return
    end

    if not game.inWorld() then
        return
    end

    local y = 10

    -- Sodium branding
    if settings.showBranding then
        ctx:rect(
            8, 8, 150, 24,
            "#AA101820"
        )

        ctx:text(
            "Sodium",
            14, 13,
            settings.hudColor
        )

        y = 39
    end

    -- FPS counter
    if settings.fpsHud then
        local fpsColor = getFPSColor(state.fps)

        ctx:rect(
            8, y, 150, 43,
            "#AA101820"
        )

        ctx:text(
            "FPS: " .. tostring(state.fps),
            14, y + 5,
            fpsColor
        )

        ctx:text(
            string.format(
                "Frame: %.2f ms",
                state.frameTime
            ),
            14, y + 22,
            "#FFFFFF"
        )
    end
end)

-- ============================================
-- COMMANDS
-- ============================================

commands.register(
    "sodium",
    function(args)
        local action = args[1]

        if action == "on" then
            settings.set("enabled", true)
            chat.print("§bSodium enabled.")

        elseif action == "off" then
            settings.set("enabled", false)
            chat.print("§cSodium disabled.")

        elseif action == "fps" then
            chat.print(
                "§bFPS: §f" .. tostring(state.fps)
            )

            chat.print(
                "§bAverage FPS: §f" ..
                string.format("%.1f", state.averageFPS)
            )

            chat.print(
                "§bFrame Time: §f" ..
                string.format("%.2f ms", state.frameTime)
            )

        elseif action == "settings" then
            settings.open()

        elseif action == "apply" then
            applySettings()
            chat.print("§aSodium settings applied.")

        elseif action == "info" then
            chat.print("§bSodium v0.2.3")
            chat.print("§7Performance settings and FPS HUD")

        else
            chat.print("§bSodium Commands:")
            chat.print("§f/sodium on")
            chat.print("§f/sodium off")
            chat.print("§f/sodium fps")
            chat.print("§f/sodium settings")
            chat.print("§f/sodium apply")
            chat.print("§f/sodium info")
        end
    end,
    "Sodium commands"
)

-- ============================================
-- SETTINGS CHANGE LISTENER
-- ============================================

settings.onChange(function(key, value, old)
    applySettings()
end)

-- ============================================
-- UNLOAD
-- ============================================

on("unload", function()
    restoreOptions()
end)

-- ============================================
-- EXPORTED API
-- ============================================

mod.export = {
    getFPS = function()
        return state.fps
    end,

    getAverageFPS = function()
        return state.averageFPS
    end,

    getFrameTime = function()
        return state.frameTime
    end,

    isEnabled = function()
        return state.enabled
    end,

    getFPSColor = function()
        return getFPSColor(state.fps)
    end,

    apply = function()
        applySettings()
    end
}

-- ============================================
-- INITIALIZATION
-- ============================================

applySettings()

chat.print("§bSodium v0.2.3 loaded!")
chat.print("§7Performance settings initialized.")
