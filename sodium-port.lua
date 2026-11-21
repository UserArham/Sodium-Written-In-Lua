
-- name: Sodium
-- id: sodium
-- version: 0.3.1
-- author: UserArham
-- description: Performance optimization and FPS monitoring

-- ============================================
-- SODIUM 0.3.1
-- ============================================

local VERSION = "0.3.1"
local MAX_LOG_SAMPLES = 600
local SAMPLE_INTERVAL = 1.0

-- ============================================
-- ORIGINAL SETTINGS
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

settings.toggle("adaptiveRenderDistance", {
    label = "Adaptive Render Distance",
    default = false
})

settings.slider("renderDistance", {
    label = "Maximum Render Distance",
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
    default = "#55CCFF"
})

-- ============================================
-- PERFORMANCE STATE
-- ============================================

local state = {
    fps = 0,
    averageFPS = 0,
    minFPS = nil,
    maxFPS = 0,
    frameTime = 0,

    enabled = true,
    sampleTimer = 0,

    adaptiveDistance = settings.renderDistance,
    lowSamples = 0,
    highSamples = 0,

    logCount = 0,
    profile = "balanced"
}

local performanceLog = {}

-- ============================================
-- FPS COLORS
-- ============================================

local function getFPSColor(fps)
    if fps >= 66 then
        return "#3399FF"
    elseif fps >= 50 then
        return "#55DD55"
    elseif fps >= 25 then
        return "#FFFF00"
    elseif fps >= 18 then
        return "#FF8800"
    else
        return "#FF3333"
    end
end

-- ============================================
-- RESTORE ORIGINAL SETTINGS
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

    if not settings.adaptiveRenderDistance then
        game.setOption(
            "renderDistance",
            settings.renderDistance
        )
    else
        game.setOption(
            "renderDistance",
            state.adaptiveDistance
        )
    end

    game.setOption(
        "framerateLimit",
        settings.fpsLimit
    )

    if settings.disableBobbing then
        game.setOption("viewBobbing", false)
    elseif original.viewBobbing ~= nil then
        game.setOption("viewBobbing", original.viewBobbing)
    end

    if settings.reduceFov then
        game.setOption("fovEffects", 0)
    elseif original.fovEffects ~= nil then
        game.setOption("fovEffects", original.fovEffects)
    end
end

-- ============================================
-- OPTIMIZATION PROFILES
-- ============================================

local function setProfile(profile)
    if profile == "low" then
        settings.set("adaptiveRenderDistance", false)
        settings.set("renderDistance", 4)
        settings.set("fpsLimit", 120)
        settings.set("reduceFov", true)
        settings.set("disableBobbing", true)

        state.profile = "low"

    elseif profile == "balanced" then
        settings.set("adaptiveRenderDistance", true)
        settings.set("renderDistance", 8)
        settings.set("fpsLimit", 120)
        settings.set("reduceFov", true)
        settings.set("disableBobbing", false)

        state.adaptiveDistance = 6
        state.profile = "balanced"

    elseif profile == "high" then
        settings.set("adaptiveRenderDistance", false)
        settings.set("renderDistance", 16)
        settings.set("fpsLimit", 260)
        settings.set("reduceFov", false)
        settings.set("disableBobbing", false)

        state.profile = "high"

    else
        return false
    end

    applySettings()
    return true
end

-- ============================================
-- ADAPTIVE RENDER DISTANCE
-- ============================================

local function updateAdaptiveDistance()
    if not settings.adaptiveRenderDistance then
        return
    end

    local target = settings.renderDistance
    local current = state.adaptiveDistance

    if state.averageFPS < 25 then
        state.lowSamples = state.lowSamples + 1
        state.highSamples = 0

        if state.lowSamples >= 3 then
            if current > 2 then
                current = current - 1
                state.adaptiveDistance = current

                game.setOption("renderDistance", current)
            end

            state.lowSamples = 0
        end

    elseif state.averageFPS >= 60 then
        state.highSamples = state.highSamples + 1
        state.lowSamples = 0

        if state.highSamples >= 8 then
            if current < target then
                current = current + 1
                state.adaptiveDistance = current

                game.setOption("renderDistance", current)
            end

            state.highSamples = 0
        end

    else
        state.lowSamples = 0
        state.highSamples = 0
    end
end

-- ============================================
-- PERFORMANCE LOG
-- ============================================

local function addPerformanceSample()
    local sample = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        fps = state.fps,
        averageFPS = state.averageFPS,
        frameTime = state.frameTime,
        renderDistance = game.option("renderDistance") or 0,
        fpsLimit = game.option("framerateLimit") or 0
    }

    performanceLog[#performanceLog + 1] = sample

    if #performanceLog > MAX_LOG_SAMPLES then
        table.remove(performanceLog, 1)
    end

    state.logCount = #performanceLog
end

local function csvEscape(value)
    local text = tostring(value)
    text = string.gsub(text, '"', '""')
    return '"' .. text .. '"'
end

local function createCSV()
    local lines = {}

    lines[#lines + 1] =
        "Timestamp,FPS,Average FPS,Frame Time (ms),Render Distance,FPS Limit"

    for _, sample in ipairs(performanceLog) do
        lines[#lines + 1] = table.concat({
            csvEscape(sample.timestamp),
            csvEscape(sample.fps),
            csvEscape(string.format("%.2f", sample.averageFPS)),
            csvEscape(string.format("%.2f", sample.frameTime)),
            csvEscape(sample.renderDistance),
            csvEscape(sample.fpsLimit)
        }, ",")
    end

    return table.concat(lines, "\n")
end

local function downloadPerformanceLog()
    if #performanceLog == 0 then
        chat.print("§cSodium: No performance data collected yet.")
        return
    end

    local filename =
        "sodium-performance-" ..
        os.date("%Y%m%d-%H%M%S") ..
        ".csv"

    files.save(
        filename,
        createCSV(),
        "text/csv"
    )

    chat.print("§aSodium: Performance log exported.")
    chat.print("§7Samples: " .. tostring(#performanceLog))
    chat.print("§7File: " .. filename)
end

-- ============================================
-- PERFORMANCE SAMPLING
-- ============================================

local function updatePerformance(dt)
    if not state.enabled then
        return
    end

    if not game.inWorld() or game.isPaused() then
        return
    end

    state.sampleTimer = state.sampleTimer + (tonumber(dt) or 0)

    if state.sampleTimer < SAMPLE_INTERVAL then
        return
    end

    state.sampleTimer = 0

    local currentFPS = game.fps()

    if not currentFPS or currentFPS <= 0 then
        return
    end

    currentFPS = math.floor(currentFPS + 0.5)

    state.fps = currentFPS
    state.frameTime = 1000 / currentFPS

    if state.minFPS == nil or currentFPS < state.minFPS then
        state.minFPS = currentFPS
    end

    if currentFPS > state.maxFPS then
        state.maxFPS = currentFPS
    end

    if state.averageFPS == 0 then
        state.averageFPS = currentFPS
    else
        state.averageFPS =
            state.averageFPS * 0.85 +
            currentFPS * 0.15
    end

    updateAdaptiveDistance()
    addPerformanceSample()
end

on("frame", function(dt)
    updatePerformance(dt)
end)

-- ============================================
-- GAMEPLAY HUD
-- ============================================

hud.add("sodium_hud", function(ctx)
    if not settings.enabled or not game.inWorld() then
        return
    end

    if not settings.fpsHud and not settings.showBranding then
        return
    end

    local y = 10

    if settings.showBranding then
        ctx:rect(8, 8, 165, 24, "#AA101820")

        -- Gameplay branding is simply Sodium.
        ctx:text("Sodium", 14, 13, settings.hudColor)

        y = 39
    end

    if settings.fpsHud then
        ctx:rect(8, y, 165, 78, "#AA101820")

        ctx:text(
            "FPS: " .. tostring(state.fps),
            14, y + 5,
            getFPSColor(state.fps)
        )

        ctx:text(
            string.format("Average: %.1f", state.averageFPS),
            14, y + 22,
            "#FFFFFF"
        )

        ctx:text(
            string.format("Frame: %.2f ms", state.frameTime),
            14, y + 39,
            "#FFFFFF"
        )

        ctx:text(
            "Render: " .. tostring(game.option("renderDistance") or "?"),
            14, y + 56,
            "#FFFFFF"
        )
    end
end)

-- ============================================
-- /OPTIMIZE COMMAND
-- ============================================

commands.register(
    "optimize",
    function(args)
        local action = args[1]

        if action == "apply" then
            applySettings()
            chat.print("§aSodium optimizations applied.")

        elseif action == "low" then
            if setProfile("low") then
                chat.print("§aLow performance profile applied.")
            end

        elseif action == "balanced" then
            if setProfile("balanced") then
                chat.print("§aBalanced performance profile applied.")
            end

        elseif action == "high" then
            if setProfile("high") then
                chat.print("§aHigh render-distance profile applied.")
            end

        elseif action == "reset" then
            restoreOptions()
            state.profile = "custom"
            chat.print("§eOriginal game options restored.")

        elseif action == "status" then
            chat.print("§bSodium Optimization Status")
            chat.print("§7Profile: §f" .. state.profile)
            chat.print("§7Render Distance: §f" ..
                tostring(game.option("renderDistance")))
            chat.print("§7FPS Limit: §f" ..
                tostring(game.option("framerateLimit")))
            chat.print("§7Adaptive Distance: §f" ..
                tostring(settings.adaptiveRenderDistance))

        else
            chat.print("§bSodium Optimization Commands:")
            chat.print("§f/optimize apply")
            chat.print("§f/optimize low")
            chat.print("§f/optimize balanced")
            chat.print("§f/optimize high")
            chat.print("§f/optimize reset")
            chat.print("§f/optimize status")
        end
    end,
    "Sodium optimization commands"
)

-- ============================================
-- /PERFORMANCE COMMAND
-- ============================================

commands.register(
    "performance",
    function(args)
        local action = args[1]

        if action == "log" then
            downloadPerformanceLog()

        elseif action == "clear" then
            performanceLog = {}
            state.logCount = 0
            chat.print("§aSodium performance log cleared.")

        elseif action == "status" then
            chat.print("§bSodium Performance Status")
            chat.print("§7FPS: §f" .. tostring(state.fps))
            chat.print("§7Average: §f" ..
                string.format("%.1f", state.averageFPS))
            chat.print("§7Minimum: §f" .. tostring(state.minFPS or 0))
            chat.print("§7Maximum: §f" .. tostring(state.maxFPS))
            chat.print("§7Frame Time: §f" ..
                string.format("%.2f ms", state.frameTime))
            chat.print("§7Samples: §f" .. tostring(state.logCount))

        elseif action == "auto" then
            local mode = args[2]

            if mode == "on" then
                settings.set("adaptiveRenderDistance", true)
                chat.print("§aAdaptive render distance enabled.")

            elseif mode == "off" then
                settings.set("adaptiveRenderDistance", false)
                chat.print("§cAdaptive render distance disabled.")

            else
                chat.print("§7Usage: /performance auto on|off")
            end

        else
            chat.print("§bPerformance Commands:")
            chat.print("§f/performance log")
            chat.print("§f/performance clear")
            chat.print("§f/performance status")
            chat.print("§f/performance auto on")
            chat.print("§f/performance auto off")
        end
    end,
    "Sodium performance commands"
)

-- ============================================
-- /SODIUM COMMAND
-- ============================================

commands.register(
    "sodium",
    function(args)
        local action = args[1]

        if action == "on" then
            settings.set("enabled", true)
            applySettings()
            chat.print("§aSodium enabled.")

        elseif action == "off" then
            settings.set("enabled", false)
            applySettings()
            chat.print("§cSodium disabled.")

        elseif action == "settings" then
            settings.open()

        elseif action == "apply" then
            applySettings()
            chat.print("§aSodium settings applied.")

        elseif action == "version" then
            chat.print("§bSodium " .. VERSION)

        else
            chat.print("§bSodium Commands:")
            chat.print("§f/sodium on")
            chat.print("§f/sodium off")
            chat.print("§f/sodium settings")
            chat.print("§f/sodium apply")
            chat.print("§f/sodium version")
        end
    end,
    "Sodium commands"
)

-- ============================================
-- SETTINGS CHANGE LISTENER
-- ============================================

settings.onChange(function(key, value, old)
    if key == "renderDistance" then
        state.adaptiveDistance = value
        state.lowSamples = 0
        state.highSamples = 0
    end

    if key == "adaptiveRenderDistance" then
        state.adaptiveDistance = settings.renderDistance
        state.lowSamples = 0
        state.highSamples = 0
    end

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

    getMinimumFPS = function()
        return state.minFPS
    end,

    getMaximumFPS = function()
        return state.maxFPS
    end,

    getFrameTime = function()
        return state.frameTime
    end,

    getFPSColor = function()
        return getFPSColor(state.fps)
    end,

    getLogCount = function()
        return state.logCount
    end,

    isEnabled = function()
        return state.enabled
    end,

    apply = function()
        applySettings()
    end
}

-- ============================================
-- INITIALIZATION
-- ============================================

applySettings()

chat.print("§bSodium v" .. VERSION .. " loaded!")
chat.print("§7Use /optimize for optimization profiles.")
chat.print("§7Use /performance for performance tools.")
