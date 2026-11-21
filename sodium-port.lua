
-- name: Sodium
-- id: sodium
-- version: 0.3.3
-- author: UserArham
-- description: FPS monitoring and performance optimization for Eaglercraft.

--------------------------------------------------
-- SODIUM v0.3.3
--------------------------------------------------

local MOD_NAME = "Sodium"
local MOD_VERSION = "0.3.3"

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

settings.toggle("enabled", {
    label = "Enable Sodium",
    default = true
})

settings.toggle("fpsHud", {
    label = "Show FPS HUD",
    default = true
})

settings.toggle("fpsBar", {
    label = "Show FPS bar",
    default = true
})

settings.toggle("showBranding", {
    label = "Show Sodium branding",
    default = true
})

settings.toggle("expandedHud", {
    label = "Expanded performance HUD",
    default = true
})

settings.toggle("adaptiveRenderDistance", {
    label = "Adaptive render distance",
    default = false
})

settings.toggle("reduceFov", {
    label = "Reduce FOV effects",
    default = false
})

settings.toggle("disableBobbing", {
    label = "Disable view bobbing",
    default = false
})

settings.slider("renderDistance", {
    label = "Target render distance",
    min = 2,
    max = 32,
    step = 1,
    default = 12
})

settings.slider("fpsLimit", {
    label = "FPS limit",
    min = 10,
    max = 260,
    step = 10,
    default = 260
})

settings.color("hudColor", {
    label = "Branding color",
    default = "#FFFFFF"
})

--------------------------------------------------
-- SETTINGS HELPERS
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
-- FPS DATA
--------------------------------------------------

local currentFPS = 0
local displayedFPS = 0

local minimumFPS = nil
local maximumFPS = 0
local totalFPS = 0
local sampleCount = 0

local performanceLog = {}
local MAX_LOG_ENTRIES = 600

local lastSampleTime = os.clock()
local adaptiveTimer = 0

local autoOptimize = false
local adaptiveDistance = 12

local fpsHistory = {}
local MAX_HISTORY = 48

--------------------------------------------------
-- FPS COLORS
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

local function getFPSStatus(fps)
    if fps >= 66 then
        return "SMOOTH"
    elseif fps >= 50 then
        return "GOOD"
    elseif fps >= 25 then
        return "MODERATE"
    elseif fps >= 18 then
        return "LOW"
    else
        return "VERY LOW"
    end
end

--------------------------------------------------
-- FPS STATISTICS
--------------------------------------------------

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
-- PERFORMANCE HISTORY
--------------------------------------------------

local function addHistory(fps)
    table.insert(fpsHistory, fps)

    if #fpsHistory > MAX_HISTORY then
        table.remove(fpsHistory, 1)
    end
end

--------------------------------------------------
-- PERFORMANCE SAMPLING
--------------------------------------------------

local function recordFPS()
    if not game.inWorld() then
        return
    end

    local fps = math.max(0, math.floor(currentFPS))

    minimumFPS = math.min(minimumFPS or fps, fps)
    maximumFPS = math.max(maximumFPS, fps)

    totalFPS = totalFPS + fps
    sampleCount = sampleCount + 1

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")

    table.insert(performanceLog, {
        time = timestamp,
        fps = fps
    })

    if #performanceLog > MAX_LOG_ENTRIES then
        table.remove(performanceLog, 1)
    end

    addHistory(fps)
end

--------------------------------------------------
-- REFRESH FPS
--------------------------------------------------

local function refreshFPS()
    currentFPS = game.inWorld() and game.fps() or 0
    displayedFPS = currentFPS

    minimumFPS = nil
    maximumFPS = 0
    totalFPS = 0
    sampleCount = 0

    performanceLog = {}
    fpsHistory = {}

    lastSampleTime = os.clock()

    if game.inWorld() then
        local fps = math.max(0, math.floor(currentFPS))

        minimumFPS = fps
        maximumFPS = fps
        totalFPS = fps
        sampleCount = 1

        table.insert(performanceLog, {
            time = os.date("%Y-%m-%d %H:%M:%S"),
            fps = fps
        })

        addHistory(fps)
    end

    chat.print("[Sodium] FPS measurements refreshed.")
end

--------------------------------------------------
-- PERFORMANCE TXT EXPORT
--------------------------------------------------

local function exportPerformanceLog()
    local lines = {}

    table.insert(lines, "================================")
    table.insert(lines, "         SODIUM LOG")
    table.insert(lines, "================================")
    table.insert(lines, "Version: " .. MOD_VERSION)
    table.insert(lines, "Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "")
    table.insert(lines, "PERFORMANCE STATISTICS")
    table.insert(lines, "Current FPS: " .. currentFPS)
    table.insert(lines, "Minimum FPS: " .. getMinimumFPS())
    table.insert(lines, "Average FPS: " .. getAverageFPS())
    table.insert(lines, "Maximum FPS: " .. getMaximumFPS())
    table.insert(lines, "Samples: " .. sampleCount)
    table.insert(lines, "")
    table.insert(lines, "FPS HISTORY")
    table.insert(lines, "--------------------------------")

    for _, entry in ipairs(performanceLog) do
        table.insert(
            lines,
            entry.time .. " | " .. entry.fps .. " FPS"
        )
    end

    table.insert(lines, "--------------------------------")
    table.insert(lines, "End of Sodium performance log.")

    files.save(
        "Sodium-Performance-Log.txt",
        table.concat(lines, "\n"),
        "text/plain"
    )

    chat.print("[Sodium] TXT performance log downloaded.")
end

--------------------------------------------------
-- CLEAR LOG
--------------------------------------------------

local function clearPerformanceLog()
    performanceLog = {}
    fpsHistory = {}

    chat.print("[Sodium] Performance log cleared.")
end

--------------------------------------------------
-- PERFORMANCE STATUS
--------------------------------------------------

local function showPerformanceStatus()
    chat.print("----- Sodium Performance -----")
    chat.print("Current FPS: " .. currentFPS)
    chat.print("Minimum FPS: " .. getMinimumFPS())
    chat.print("Average FPS: " .. getAverageFPS())
    chat.print("Maximum FPS: " .. getMaximumFPS())
    chat.print("Samples: " .. sampleCount)
    chat.print("Log entries: " .. #performanceLog)
    chat.print("------------------------------")
end

--------------------------------------------------
-- GAME OPTION HELPER
--------------------------------------------------

local function setGameOption(name, value)
    local ok, err = pcall(function()
        game.setOption(name, value)
    end)

    return ok
end

--------------------------------------------------
-- OPTIMIZATION PRESETS
--------------------------------------------------

local function applyPreset(name)
    local distance
    local limit
    local bobbing
    local fovEffects

    if name == "low" then
        distance = 4
        limit = 60
        bobbing = false
        fovEffects = 0

    elseif name == "balanced" then
        distance = 8
        limit = 120
        bobbing = false
        fovEffects = 0

    elseif name == "high" then
        distance = 16
        limit = 260
        bobbing = true
        fovEffects = 1

    elseif name == "apply" then
        distance = getSetting("renderDistance", 12)
        limit = getSetting("fpsLimit", 260)
        bobbing = not getSetting("disableBobbing", false)

        fovEffects = getSetting("reduceFov", false) and 0 or 1

    else
        chat.print("[Sodium] Unknown preset.")
        return
    end

    setGameOption("renderDistance", distance)
    setGameOption("framerateLimit", limit)
    setGameOption("viewBobbing", bobbing)
    setGameOption("fovEffects", fovEffects)

    adaptiveDistance = distance

    chat.print("[Sodium] " .. name .. " preset applied.")
    chat.print("[Sodium] Render distance: " .. distance)
    chat.print("[Sodium] FPS limit: " .. limit)
end

--------------------------------------------------
-- RESET OPTIMIZATIONS
--------------------------------------------------

local function resetOptimizations()
    setGameOption("renderDistance", 12)
    setGameOption("framerateLimit", 260)
    setGameOption("viewBobbing", true)
    setGameOption("fovEffects", 1)

    adaptiveDistance = 12

    chat.print("[Sodium] Options reset.")
end

--------------------------------------------------
-- ADAPTIVE RENDER DISTANCE
--------------------------------------------------

local function updateAdaptiveRenderDistance()
    if not getSetting("adaptiveRenderDistance", false) then
        return
    end

    if not game.inWorld() then
        return
    end

    local newDistance = adaptiveDistance

    if currentFPS < 25 then
        newDistance = math.max(2, adaptiveDistance - 2)
    elseif currentFPS < 40 then
        newDistance = math.max(2, adaptiveDistance - 1)
    elseif currentFPS >= 90 then
        newDistance = math.min(32, adaptiveDistance + 1)
    end

    if newDistance ~= adaptiveDistance then
        adaptiveDistance = newDistance
        setGameOption("renderDistance", newDistance)
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
-- FPS BAR CONFIGURATION
--------------------------------------------------

local fpsBar = {
    x = 8,
    y = 8,
    width = 184,
    height = 72,
    maxFPS = 260,
    enabled = true,
    compact = false
}

--------------------------------------------------
-- DRAW FPS BAR BACKGROUND
--------------------------------------------------

local function drawPanel(ctx, x, y, w, h)
    -- Outer shadow
    ctx:rect(
        x + 2,
        y + 3,
        w,
        h,
        "#70000000"
    )

    -- Main panel
    ctx:gradient(
        x,
        y,
        x + w,
        y + h,
        "#F0192435",
        "#E90B1220"
    )

    -- Border
    ctx:outline(
        x,
        y,
        w,
        h,
        "#526783"
    )

    -- Top highlight
    ctx:rect(
        x + 1,
        y + 1,
        w - 2,
        1,
        "#806FA6D8"
    )
end

--------------------------------------------------
-- DRAW FPS BAR
--------------------------------------------------

local function drawFPSBar(ctx, x, y, width, height)
    local fps = math.max(0, currentFPS)
    local color = getFPSColor(fps)

    local ratio = math.min(
        1,
        math.max(0, displayedFPS / fpsBar.maxFPS)
    )

    local fillWidth = math.floor(width * ratio)

    -- Bar shadow
    ctx:rect(
        x,
        y + 1,
        width,
        height,
        "#AA000000"
    )

    -- Dark track
    ctx:gradient(
        x,
        y,
        x + width,
        y + height,
        "#FF111827",
        "#FF263449"
    )

    -- Colored glow layers
    if fillWidth > 0 then
        ctx:rect(
            x,
            y - 2,
            fillWidth,
            height + 4,
            "#263399FF"
        )

        -- Main colored fill
        ctx:gradient(
            x,
            y,
            x + fillWidth,
            y + height,
            color,
            color
        )

        -- Bright upper highlight
        ctx:rect(
            x,
            y,
            fillWidth,
            2,
            "#70FFFFFF"
        )
    end

    -- Scale marks
    for i = 1, 4 do
        local markX = x + (width * i / 5)

        ctx:rect(
            markX,
            y + 1,
            1,
            height - 2,
            "#60405060"
        )
    end

    -- Border
    ctx:outline(
        x,
        y,
        width,
        height,
        "#FF64748B"
    )
end

--------------------------------------------------
-- DRAW FPS HISTORY GRAPH
--------------------------------------------------

local function drawHistoryGraph(ctx, x, y, width, height)
    ctx:rect(
        x,
        y,
        width,
        height,
        "#70101827"
    )

    ctx:outline(
        x,
        y,
        width,
        height,
        "#40516A"
    )

    if #fpsHistory < 2 then
        ctx:text(
            "Collecting FPS history...",
            x + 5,
            y + 5,
            "#94A3B8"
        )
        return
    end

    local previousX = nil
    local previousY = nil

    for i, fps in ipairs(fpsHistory) do
        local graphX =
            x + ((i - 1) / math.max(1, MAX_HISTORY - 1)) * width

        local normalized =
            math.min(1, math.max(0, fps / fpsBar.maxFPS))

        local graphY =
            y + height - (normalized * (height - 4)) - 2

        if previousX then
            ctx:line(
                previousX,
                previousY,
                graphX,
                graphY,
                getFPSColor(fps),
                2
            )
        end

        previousX = graphX
        previousY = graphY
    end
end

--------------------------------------------------
-- DRAW STATISTIC CARD
--------------------------------------------------

local function drawStat(ctx, label, value, x, y, color)
    ctx:text(
        label,
        x,
        y,
        "#91A3BA"
    )

    ctx:text(
        tostring(value),
        x,
        y + 11,
        color
    )
end

--------------------------------------------------
-- MAIN FPS HUD
--------------------------------------------------

hud.add("sodium_main_hud", function(ctx)
    if not isEnabled() then
        return
    end

    if not game.inWorld() then
        return
    end

    if not getSetting("fpsHud", true)
        and not getSetting("showBranding", true)
        and not getSetting("fpsBar", true) then
        return
    end

    local x = fpsBar.x
    local y = fpsBar.y
    local width = fpsBar.width

    local fps = currentFPS
    local color = getFPSColor(fps)

    --------------------------------------------------
    -- COMPACT MODE
    --------------------------------------------------

    if fpsBar.compact
        or not getSetting("expandedHud", true) then

        drawPanel(ctx, x, y, width, 34)

        if getSetting("showBranding", true) then
            ctx:text(
                "SODIUM",
                x + 8,
                y + 6,
                getSetting("hudColor", "#FFFFFF")
            )
        end

        if getSetting("fpsHud", true) then
            ctx:text(
                tostring(fps) .. " FPS",
                x + 83,
                y + 6,
                color
            )
        end

        if getSetting("fpsBar", true) then
            drawFPSBar(
                ctx,
                x + 8,
                y + 23,
                width - 16,
                5
            )
        end

        return
    end

    --------------------------------------------------
    -- EXPANDED MODE
    --------------------------------------------------

    local panelHeight = 112

    drawPanel(
        ctx,
        x,
        y,
        width,
        panelHeight
    )

    --------------------------------------------------
    -- HEADER
    --------------------------------------------------

    if getSetting("showBranding", true) then
        ctx:text(
            "SODIUM",
            x + 9,
            y + 7,
            getSetting("hudColor", "#FFFFFF")
        )

        ctx:text(
            "PERFORMANCE",
            x + 66,
            y + 7,
            "#8EA4C1"
        )
    end

    ctx:circle(
        x + width - 12,
        y + 11,
        3,
        "#55DD55"
    )

    --------------------------------------------------
    -- MAIN FPS NUMBER
    --------------------------------------------------

    if getSetting("fpsHud", true) then
        ctx:text(
            tostring(fps),
            x + 9,
            y + 23,
            color
        )

        ctx:text(
            "FPS",
            x + 49,
            y + 29,
            "#B7C7D9"
        )

        ctx:text(
            getFPSStatus(fps),
            x + width - 64,
            y + 29,
            color
        )
    end

    --------------------------------------------------
    -- FPS BAR
    --------------------------------------------------

    if getSetting("fpsBar", true) then
        drawFPSBar(
            ctx,
            x + 9,
            y + 44,
            width - 18,
            9
        )
    end

    --------------------------------------------------
    -- STATISTICS
    --------------------------------------------------

    drawStat(
        ctx,
        "MIN",
        getMinimumFPS(),
        x + 10,
        y + 61,
        "#FF8800"
    )

    drawStat(
        ctx,
        "AVG",
        getAverageFPS(),
        x + 69,
        y + 61,
        "#55DD55"
    )

    drawStat(
        ctx,
        "MAX",
        getMaximumFPS(),
        x + 130,
        y + 61,
        "#3399FF"
    )

    --------------------------------------------------
    -- HISTORY GRAPH
    --------------------------------------------------

    drawHistoryGraph(
        ctx,
        x + 9,
        y + 86,
        width - 18,
        17
    )
end)

--------------------------------------------------
-- FRAME EVENT
--------------------------------------------------

on("frame", function(dt)
    if not isEnabled() or not game.inWorld() then
        return
    end

    local measured = game.fps()

    if type(measured) == "number" then
        currentFPS = math.max(0, math.floor(measured))
    end

    local delta = math.max(0, math.min(dt or 0.05, 0.25))
    local smoothing = math.min(1, delta * 10)

    displayedFPS =
        displayedFPS +
        (currentFPS - displayedFPS) * smoothing
end)

--------------------------------------------------
-- TICK EVENT
--------------------------------------------------

on("tick", function()
    if not isEnabled() or not game.inWorld() then
        return
    end

    local now = os.clock()

    if now - lastSampleTime >= 1 then
        lastSampleTime = now

        recordFPS()
        updateAutomaticOptimization()
    end

    adaptiveTimer = adaptiveTimer + 1

    if adaptiveTimer >= 40 then
        adaptiveTimer = 0
        updateAdaptiveRenderDistance()
    end
end)

--------------------------------------------------
-- /PERFORMANCE
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
        if args[2] == "on" then
            autoOptimize = true
            chat.print("[Sodium] Automatic optimization enabled.")

        elseif args[2] == "off" then
            autoOptimize = false
            chat.print("[Sodium] Automatic optimization disabled.")

        else
            chat.print("Usage: /performance auto on|off")
        end

    else
        chat.print("/performance log")
        chat.print("/performance clear")
        chat.print("/performance status")
        chat.print("/performance auto on|off")
    end
end, "Sodium performance commands")

--------------------------------------------------
-- /REFRESH
--------------------------------------------------

commands.register("refresh", function(args)
    if args[1] == "fps" then
        refreshFPS()
    else
        chat.print("Usage: /refresh fps")
    end
end, "Refresh FPS measurements")

--------------------------------------------------
-- /OPTIMIZE
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
        chat.print("----- Sodium Options -----")
        chat.print("Render distance: " ..
            tostring(game.option("renderDistance")))
        chat.print("FPS limit: " ..
            tostring(game.option("framerateLimit")))
        chat.print("View bobbing: " ..
            tostring(game.option("viewBobbing")))
        chat.print("--------------------------")

    else
        chat.print("/optimize apply")
        chat.print("/optimize low")
        chat.print("/optimize balanced")
        chat.print("/optimize high")
        chat.print("/optimize reset")
        chat.print("/optimize status")
    end
end, "Sodium optimization presets")

--------------------------------------------------
-- /FPSBAR
--------------------------------------------------

commands.register("fpsbar", function(args)
    local action = args[1] or "status"

    if action == "on" then
        settings.set("fpsBar", true)
        chat.print("[Sodium] FPS bar enabled.")

    elseif action == "off" then
        settings.set("fpsBar", false)
        chat.print("[Sodium] FPS bar disabled.")

    elseif action == "compact" then
        fpsBar.compact = true
        chat.print("[Sodium] Compact HUD enabled.")

    elseif action == "expanded" then
        fpsBar.compact = false
        chat.print("[Sodium] Expanded HUD enabled.")

    elseif action == "reset" then
        fpsBar.x = 8
        fpsBar.y = 8
        fpsBar.width = 184
        fpsBar.height = 72
        fpsBar.maxFPS = 260
        fpsBar.compact = false

        chat.print("[Sodium] FPS bar layout reset.")

    elseif action == "status" then
        chat.print("FPS bar: " ..
            tostring(getSetting("fpsBar", true)))
        chat.print("Compact mode: " ..
            tostring(fpsBar.compact))
        chat.print("Maximum scale: " .. fpsBar.maxFPS)

    else
        chat.print("/fpsbar on")
        chat.print("/fpsbar off")
        chat.print("/fpsbar compact")
        chat.print("/fpsbar expanded")
        chat.print("/fpsbar reset")
        chat.print("/fpsbar status")
    end
end, "Sodium FPS HUD controls")

--------------------------------------------------
-- /SODIUM
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
        chat.print("/sodium on")
        chat.print("/sodium off")
        chat.print("/sodium settings")
        chat.print("/sodium apply")
        chat.print("/sodium version")
    end
end, "Sodium main commands")

--------------------------------------------------
-- SETTINGS CHANGES
--------------------------------------------------

settings.onChange(function(key, value)
    if key == "enabled" then
        chat.print(
            value and "[Sodium] Enabled." or "[Sodium] Disabled."
        )
    end

    if key == "renderDistance" then
        adaptiveDistance = value
    end
end)

--------------------------------------------------
-- MOD EXPORT
--------------------------------------------------

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

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

adaptiveDistance = getSetting("renderDistance", 12)

if game.inWorld() then
    currentFPS = game.fps()
    displayedFPS = currentFPS
end

lastSampleTime = os.clock()

chat.print("[Sodium] v" .. MOD_VERSION .. " loaded.")
chat.print("[Sodium] Enhanced FPS HUD initialized.")
