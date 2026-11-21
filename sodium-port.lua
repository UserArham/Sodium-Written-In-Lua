
-- name: Sodium
-- id: sodium
-- version: 0.3.2
-- author: UserArham
-- description: Performance settings, FPS monitoring, and optimization tools for Eaglercraft.
-- permissions:

--------------------------------------------------
-- SODIUM v0.3.2
-- Eaglercraft 26.2 / 26.3
-- Zeus Lua 5.4
--------------------------------------------------

local MOD_NAME = "Sodium"
local MOD_VERSION = "0.3.2"

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

settings.toggle("enabled", {
    label = "Enable Sodium",
    description = "Enable or disable Sodium.",
    default = true
})

settings.toggle("fpsHud", {
    label = "Show FPS HUD",
    description = "Display your current FPS.",
    default = true
})

settings.toggle("showBranding", {
    label = "Show Sodium branding",
    description = "Display Sodium on the HUD.",
    default = true
})

settings.toggle("reduceFov", {
    label = "Reduce FOV effects",
    description = "Reduce field of view effects.",
    default = false
})

settings.toggle("disableBobbing", {
    label = "Disable view bobbing",
    description = "Disable camera view bobbing.",
    default = false
})

settings.toggle("adaptiveRenderDistance", {
    label = "Adaptive render distance",
    description = "Adjust render distance based on FPS.",
    default = false
})

settings.slider("renderDistance", {
    label = "Target render distance",
    description = "Render distance used by Sodium optimization presets.",
    min = 2,
    max = 32,
    step = 1,
    default = 12
})

settings.slider("fpsLimit", {
    label = "FPS limit",
    description = "Target frame rate limit.",
    min = 10,
    max = 260,
    step = 10,
    default = 260
})

settings.color("hudColor", {
    label = "HUD color",
    description = "Color used for Sodium branding.",
    default = "#FFFFFF"
})

--------------------------------------------------
-- SETTINGS ACCESS
--------------------------------------------------

local function getSetting(key, fallback)
    local value = settings.get(key)

    if value == nil then
        return fallback
    end

    return value
end

local function isEnabled()
    return getSetting("enabled", true)
end

--------------------------------------------------
-- FPS COLOR SYSTEM
--------------------------------------------------

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

--------------------------------------------------
-- PERFORMANCE DATA
--------------------------------------------------

local currentFPS = 0
local minimumFPS = nil
local maximumFPS = 0
local totalFPS = 0
local sampleCount = 0

local performanceLog = {}
local MAX_LOG_ENTRIES = 600

local lastSampleTime = 0
local adaptiveTimer = 0
local autoOptimize = false

local function getAverageFPS()
    if sampleCount == 0 then
        return 0
    end

    return math.floor(totalFPS / sampleCount + 0.5)
end

local function getMinimumFPS()
    return minimumFPS or 0
end

local function getMaximumFPS()
    return maximumFPS
end

--------------------------------------------------
-- TIME FORMATTING
--------------------------------------------------

local function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

--------------------------------------------------
-- FPS MEASUREMENT
--------------------------------------------------

local function recordFPS()
    if not game.inWorld() then
        return
    end

    local fps = game.fps()

    if type(fps) ~= "number" then
        return
    end

    fps = math.max(0, math.floor(fps))

    currentFPS = fps
    minimumFPS = math.min(minimumFPS or fps, fps)
    maximumFPS = math.max(maximumFPS, fps)

    totalFPS = totalFPS + fps
    sampleCount = sampleCount + 1

    local entry = {
        time = getTimestamp(),
        fps = fps
    }

    table.insert(performanceLog, entry)

    if #performanceLog > MAX_LOG_ENTRIES then
        table.remove(performanceLog, 1)
    end
end

--------------------------------------------------
-- REFRESH FPS
--------------------------------------------------

local function refreshFPS()
    currentFPS = game.inWorld() and game.fps() or 0

    minimumFPS = nil
    maximumFPS = 0
    totalFPS = 0
    sampleCount = 0

    performanceLog = {}
    lastSampleTime = os.clock()

    if game.inWorld() then
        local fps = math.max(0, math.floor(currentFPS))

        minimumFPS = fps
        maximumFPS = fps
        totalFPS = fps
        sampleCount = 1

        table.insert(performanceLog, {
            time = getTimestamp(),
            fps = fps
        })
    end

    chat.print("[Sodium] FPS measurements refreshed.")
end

--------------------------------------------------
-- PERFORMANCE LOG EXPORT
--------------------------------------------------

local function exportPerformanceLog()
    local lines = {}

    table.insert(lines, "Sodium Performance Log")
    table.insert(lines, "Version: " .. MOD_VERSION)
    table.insert(lines, "Date: " .. getTimestamp())
    table.insert(lines, "")
    table.insert(lines, "FPS Statistics")
    table.insert(lines, "Current FPS: " .. tostring(currentFPS))
    table.insert(lines, "Minimum FPS: " .. tostring(getMinimumFPS()))
    table.insert(lines, "Maximum FPS: " .. tostring(getMaximumFPS()))
    table.insert(lines, "Average FPS: " .. tostring(getAverageFPS()))
    table.insert(lines, "Samples: " .. tostring(sampleCount))
    table.insert(lines, "")
    table.insert(lines, "Recorded Measurements")
    table.insert(lines, "Timestamp | FPS")
    table.insert(lines, "---------------------------")

    for _, entry in ipairs(performanceLog) do
        table.insert(
            lines,
            tostring(entry.time) .. " | " .. tostring(entry.fps)
        )
    end

    local output = table.concat(lines, "\n")

    files.save(
        "Sodium-Performance-Log.txt",
        output,
        "text/plain"
    )

    chat.print("[Sodium] Performance log exported as TXT.")
end

--------------------------------------------------
-- CLEAR PERFORMANCE LOG
--------------------------------------------------

local function clearPerformanceLog()
    performanceLog = {}

    chat.print("[Sodium] Performance log cleared.")
end

--------------------------------------------------
-- PERFORMANCE STATUS
--------------------------------------------------

local function showPerformanceStatus()
    chat.print("----- Sodium Performance -----")
    chat.print("Current FPS: " .. tostring(currentFPS))
    chat.print("Minimum FPS: " .. tostring(getMinimumFPS()))
    chat.print("Maximum FPS: " .. tostring(getMaximumFPS()))
    chat.print("Average FPS: " .. tostring(getAverageFPS()))
    chat.print("Samples: " .. tostring(sampleCount))
    chat.print("Log entries: " .. tostring(#performanceLog))
    chat.print("------------------------------")
end

--------------------------------------------------
-- GAME OPTION HELPERS
--------------------------------------------------

local function setGameOption(name, value)
    local success, result = pcall(function()
        game.setOption(name, value)
    end)

    return success and result ~= false
end

local function applyBasicOptimizations()
    setGameOption("viewBobbing", false)
    setGameOption("fovEffects", 0)
    setGameOption(
        "renderDistance",
        getSetting("renderDistance", 12)
    )
    setGameOption(
        "framerateLimit",
        getSetting("fpsLimit", 260)
    )
end

--------------------------------------------------
-- OPTIMIZATION PRESETS
--------------------------------------------------

local function applyPreset(name)
    local renderDistance = 12
    local fpsLimit = 260
    local bobbing = false
    local fovEffects = 0

    if name == "low" then
        renderDistance = 4
        fpsLimit = 60
        bobbing = false
        fovEffects = 0

    elseif name == "balanced" then
        renderDistance = 8
        fpsLimit = 120
        bobbing = false
        fovEffects = 0

    elseif name == "high" then
        renderDistance = 16
        fpsLimit = 260
        bobbing = true
        fovEffects = 1

    elseif name == "apply" then
        renderDistance = getSetting("renderDistance", 12)
        fpsLimit = getSetting("fpsLimit", 260)
        bobbing = not getSetting("disableBobbing", false)

        if getSetting("reduceFov", false) then
            fovEffects = 0
        else
            fovEffects = 1
        end

    else
        chat.print("[Sodium] Unknown optimization preset.")
        return
    end

    setGameOption("renderDistance", renderDistance)
    setGameOption("framerateLimit", fpsLimit)
    setGameOption("viewBobbing", bobbing)
    setGameOption("fovEffects", fovEffects)

    chat.print("[Sodium] Applied " .. name .. " optimization preset.")
    chat.print("[Sodium] Render distance: " .. renderDistance)
    chat.print("[Sodium] FPS limit: " .. fpsLimit)
end

--------------------------------------------------
-- RESET OPTIMIZATION OPTIONS
--------------------------------------------------

local function resetOptimizations()
    setGameOption("renderDistance", 12)
    setGameOption("framerateLimit", 260)
    setGameOption("viewBobbing", true)
    setGameOption("fovEffects", 1)

    chat.print("[Sodium] Optimization options reset.")
end

--------------------------------------------------
-- ADAPTIVE RENDER DISTANCE
--------------------------------------------------

local adaptiveRenderDistance = 12

local function updateAdaptiveRenderDistance()
    if not isEnabled() then
        return
    end

    if not getSetting("adaptiveRenderDistance", false) then
        return
    end

    if not game.inWorld() then
        return
    end

    local fps = currentFPS
    local newDistance = adaptiveRenderDistance

    if fps < 25 then
        newDistance = math.max(2, adaptiveRenderDistance - 2)
    elseif fps < 40 then
        newDistance = math.max(2, adaptiveRenderDistance - 1)
    elseif fps >= 90 then
        newDistance = math.min(32, adaptiveRenderDistance + 1)
    end

    if newDistance ~= adaptiveRenderDistance then
        adaptiveRenderDistance = newDistance
        setGameOption("renderDistance", adaptiveRenderDistance)
    end
end

--------------------------------------------------
-- AUTOMATIC OPTIMIZATION
--------------------------------------------------

local function updateAutomaticOptimization()
    if not autoOptimize then
        return
    end

    if currentFPS < 25 then
        setGameOption("renderDistance", 4)
    elseif currentFPS < 40 then
        setGameOption("renderDistance", 6)
    elseif currentFPS < 60 then
        setGameOption("renderDistance", 8)
    elseif currentFPS >= 100 then
        setGameOption("renderDistance", 12)
    end
end

--------------------------------------------------
-- FPS HUD
--------------------------------------------------

hud.add("sodium_fps", function(ctx)
    if not isEnabled() then
        return
    end

    if not game.inWorld() then
        return
    end

    local y = 4

    if getSetting("showBranding", true) then
        ctx:text(
            MOD_NAME,
            4,
            y,
            getSetting("hudColor", "#FFFFFF")
        )

        y = y + 12
    end

    if getSetting("fpsHud", true) then
        local fpsText = "FPS: " .. tostring(currentFPS)

        ctx:text(
            fpsText,
            4,
            y,
            getFPSColor(currentFPS)
        )
    end
end)

--------------------------------------------------
-- MAIN TICK EVENT
--------------------------------------------------

on("tick", function()
    if not isEnabled() then
        return
    end

    if not game.inWorld() then
        return
    end

    local now = os.clock()

    if now - lastSampleTime >= 1 then
        lastSampleTime = now
        recordFPS()

        if autoOptimize then
            updateAutomaticOptimization()
        end
    end

    if getSetting("adaptiveRenderDistance", false) then
        adaptiveTimer = adaptiveTimer + 1

        if adaptiveTimer >= 40 then
            adaptiveTimer = 0
            updateAdaptiveRenderDistance()
        end
    end
end)

--------------------------------------------------
-- /PERFORMANCE COMMAND
--------------------------------------------------

commands.register("performance", function(args)
    local action = args[1] or "status"

    if action == "log" then
        exportPerformanceLog()

    elseif action == "clear" then
        clearPerformanceLog()

    elseif action == "status" then
        showPerformanceStatus()

    elseif action == "auto" then
        local state = args[2]

        if state == "on" then
            autoOptimize = true
            chat.print("[Sodium] Automatic optimization enabled.")

        elseif state == "off" then
            autoOptimize = false
            chat.print("[Sodium] Automatic optimization disabled.")

        else
            chat.print("Usage: /performance auto on|off")
        end

    else
        chat.print("----- Sodium Performance -----")
        chat.print("/performance log")
        chat.print("/performance clear")
        chat.print("/performance status")
        chat.print("/performance auto on|off")
    end
end, "Sodium performance monitoring commands")

--------------------------------------------------
-- /REFRESH COMMAND
--------------------------------------------------

commands.register("refresh", function(args)
    local action = args[1]

    if action == "fps" then
        refreshFPS()
    else
        chat.print("Usage: /refresh fps")
    end
end, "Refresh Sodium measurements")

--------------------------------------------------
-- /OPTIMIZE COMMAND
--------------------------------------------------

commands.register("optimize", function(args)
    local action = args[1] or "status"

    if action == "apply" then
        applyPreset("apply")

    elseif action == "low" then
        applyPreset("low")

    elseif action == "balanced" then
        applyPreset("balanced")

    elseif action == "high" then
        applyPreset("high")

    elseif action == "reset" then
        resetOptimizations()

    elseif action == "status" then
        chat.print("----- Sodium Optimization -----")
        chat.print(
            "Render distance: " ..
            tostring(game.option("renderDistance"))
        )
        chat.print(
            "FPS limit: " ..
            tostring(game.option("framerateLimit"))
        )
        chat.print(
            "View bobbing: " ..
            tostring(game.option("viewBobbing"))
        )
        chat.print(
            "FOV effects: " ..
            tostring(game.option("fovEffects"))
        )
        chat.print("-------------------------------")

    else
        chat.print("----- Sodium Optimize -----")
        chat.print("/optimize apply")
        chat.print("/optimize low")
        chat.print("/optimize balanced")
        chat.print("/optimize high")
        chat.print("/optimize reset")
        chat.print("/optimize status")
    end
end, "Sodium optimization presets")

--------------------------------------------------
-- /SODIUM COMMAND
--------------------------------------------------

commands.register("sodium", function(args)
    local action = args[1] or "settings"

    if action == "on" then
        settings.set("enabled", true)
        chat.print("[Sodium] Enabled.")

    elseif action == "off" then
        settings.set("enabled", false)
        chat.print("[Sodium] Disabled.")

    elseif action == "settings" then
        settings.open()

    elseif action == "apply" then
        applyPreset("apply")

    elseif action == "version" then
        chat.print("Sodium " .. MOD_VERSION)

    else
        chat.print("----- Sodium -----")
        chat.print("/sodium on")
        chat.print("/sodium off")
        chat.print("/sodium settings")
        chat.print("/sodium apply")
        chat.print("/sodium version")
    end
end, "Sodium main commands")

--------------------------------------------------
-- SETTINGS CHANGE HANDLER
--------------------------------------------------

settings.onChange(function(key, value)
    if key == "enabled" then
        if value then
            chat.print("[Sodium] Enabled.")
        else
            chat.print("[Sodium] Disabled.")
        end
    end

    if key == "renderDistance" then
        adaptiveRenderDistance = value
    end
end)

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

adaptiveRenderDistance = getSetting("renderDistance", 12)
lastSampleTime = os.clock()

if game.inWorld() then
    currentFPS = game.fps()
end

mod.export = {
    name = MOD_NAME,
    version = MOD_VERSION,

    getFPS = function()
        return currentFPS
    end,

    getAverageFPS = function()
        return getAverageFPS()
    end,

    getMinimumFPS = function()
        return getMinimumFPS()
    end,

    getMaximumFPS = function()
        return getMaximumFPS()
    end,

    refreshFPS = function()
        refreshFPS()
    end
}

chat.print("[Sodium] v" .. MOD_VERSION .. " loaded.")
