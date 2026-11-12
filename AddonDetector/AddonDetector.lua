local ADDON_NAME = ... or "AddonDetector"

-- Default SavedVariables
AddonDetectorDB = AddonDetectorDB or {
    minimapPos = 225,
}

local isChecking = false
local UPDATE_INTERVAL = 0.10
local elapsedAccumulator = 0
local foundSet = {}
local foundList = {}

--------------------------------------------------------------------------------
-- Main Detector Panel
--------------------------------------------------------------------------------
local DetectorFrame = CreateFrame("Frame", "AddonDetectorFrame", UIParent)
DetectorFrame:SetSize(260, 95)
DetectorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
DetectorFrame:SetFrameStrata("TOOLTIP")
DetectorFrame:SetToplevel(true)
DetectorFrame:SetMovable(true)
DetectorFrame:EnableMouse(true)
DetectorFrame:SetClampedToScreen(true)
DetectorFrame:RegisterForDrag("LeftButton")
DetectorFrame:SetScript("OnDragStart", DetectorFrame.StartMoving)
DetectorFrame:SetScript("OnDragStop", DetectorFrame.StopMovingOrSizing)
DetectorFrame:Hide()

DetectorFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
DetectorFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.92)
DetectorFrame:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)

-- Header Title
local TitleText = DetectorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TitleText:SetPoint("TOPLEFT", DetectorFrame, "TOPLEFT", 10, -8)
TitleText:SetText("|cffd98c46AddonDetector|r")

-- Close Button
local CloseButton = CreateFrame("Button", nil, DetectorFrame, "UIPanelCloseButton")
CloseButton:SetSize(22, 22)
CloseButton:SetPoint("TOPRIGHT", DetectorFrame, "TOPRIGHT", -2, -2)

-- Check & Stop Buttons
local CheckButton = CreateFrame("Button", "AddonDetectorCheckButton", DetectorFrame, "UIPanelButtonTemplate")
CheckButton:SetSize(115, 22)
CheckButton:SetPoint("TOPLEFT", DetectorFrame, "TOPLEFT", 10, -26)
CheckButton:SetText("Check")

local StopButton = CreateFrame("Button", "AddonDetectorStopButton", DetectorFrame, "UIPanelButtonTemplate")
StopButton:SetSize(115, 22)
StopButton:SetPoint("TOPRIGHT", DetectorFrame, "TOPRIGHT", -10, -26)
StopButton:SetText("Stop")
StopButton:Disable()

-- Divider Line
local Divider = DetectorFrame:CreateTexture(nil, "ARTWORK")
Divider:SetHeight(1)
Divider:SetPoint("TOPLEFT", DetectorFrame, "TOPLEFT", 8, -54)
Divider:SetPoint("TOPRIGHT", DetectorFrame, "TOPRIGHT", -8, -54)
Divider:SetTexture(1, 1, 1, 0.15)

-- Output Text inside the box
local ResultText = DetectorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ResultText:SetPoint("TOPLEFT", DetectorFrame, "TOPLEFT", 10, -62)
ResultText:SetWidth(240)
ResultText:SetJustifyH("LEFT")
ResultText:SetJustifyV("TOP")
ResultText:SetText("|cff888888Stopped. Press Check to scan.|r")

--------------------------------------------------------------------------------
-- WeakAuras Read-Only Aura Name Resolver
--------------------------------------------------------------------------------
local function GetWeakAuraRegionType(auraId, frame)
    if type(frame) == "table" and type(frame.regionType) == "string" then
        return frame.regionType
    end
    if type(_G.WeakAuras) == "table" and type(_G.WeakAuras.regions) == "table" then
        local rData = _G.WeakAuras.regions[auraId]
        if type(rData) == "table" and type(rData.regionType) == "string" then
            return rData.regionType
        end
    end
    if type(_G.WeakAurasSaved) == "table" and type(_G.WeakAurasSaved.displays) == "table" then
        local dData = _G.WeakAurasSaved.displays[auraId]
        if type(dData) == "table" and type(dData.regionType) == "string" then
            return dData.regionType
        end
    end
    return nil
end

local function InspectWeakAuraFrame(curr)
    if type(curr) ~= "table" then
        return nil, nil
    end

    -- 1. Check direct .id property on WeakAuras region frames
    if type(curr.id) == "string" and curr.id ~= "" then
        local isSec, taint = issecurevariable(curr, "id")
        if not isSec and (taint == "WeakAuras" or taint == "WeakAurasOptions") then
            return curr.id, GetWeakAuraRegionType(curr.id, curr)
        elseif _G.WeakAurasFrame and curr:GetParent() == _G.WeakAurasFrame then
            return curr.id, GetWeakAuraRegionType(curr.id, curr)
        end
    end

    -- 2. Check .data.id (used by WeakAuras mover/option frames)
    if type(curr.data) == "table" and type(curr.data.id) == "string" and curr.data.id ~= "" then
        local isSec, taint = issecurevariable(curr, "data")
        if not isSec and (taint == "WeakAuras" or taint == "WeakAurasOptions") then
            return curr.data.id, curr.data.regionType or GetWeakAuraRegionType(curr.data.id, curr)
        end
    end

    -- 3. Fallback lookup in WeakAuras.regions and WeakAuras.clones tables
    local WA = _G.WeakAuras
    if type(WA) == "table" then
        if type(WA.regions) == "table" then
            for id, regionData in pairs(WA.regions) do
                if type(regionData) == "table" and regionData.region == curr then
                    return tostring(id), regionData.regionType or GetWeakAuraRegionType(id, curr)
                end
            end
        end
        if type(WA.clones) == "table" then
            for id, clones in pairs(WA.clones) do
                if type(clones) == "table" then
                    for _, cloneFrame in pairs(clones) do
                        if cloneFrame == curr then
                            return tostring(id), GetWeakAuraRegionType(id, curr)
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

--------------------------------------------------------------------------------
-- General Addon Detection Logic (Read-Only)
--------------------------------------------------------------------------------
local function GetSingleFrameOwner(frame)
    -- 1. Check global variable taint if the frame is named
    local name = frame:GetName()
    if name and type(name) == "string" and _G[name] ~= nil then
        local isSecure, taint = issecurevariable(name)
        if not isSecure and taint and taint ~= "" then
            return taint
        elseif isSecure then
            return "BLIZZARD"
        end
    end

    -- 2. Check string keys on the frame table itself (catches unnamed Lua frames)
    if type(frame) == "table" then
        for k in pairs(frame) do
            if type(k) == "string" then
                local isSecure, taint = issecurevariable(frame, k)
                if not isSecure and taint and taint ~= "" then
                    return taint
                end
            end
        end
    end

    -- 3. Check named regions (textures/fontstrings) belonging to the frame
    if frame.GetNumRegions then
        local numRegions = frame:GetNumRegions()
        if numRegions and numRegions > 0 and numRegions <= 25 then
            local regions = { frame:GetRegions() }
            for i = 1, #regions do
                local rName = regions[i] and regions[i]:GetName()
                if rName and type(rName) == "string" and _G[rName] ~= nil then
                    local isSecure, taint = issecurevariable(rName)
                    if not isSecure and taint and taint ~= "" then
                        return taint
                    end
                end
            end
        end
    end

    return nil
end

local function ResolveFrameAddon(frame)
    local curr = frame
    local depth = 0
    local fallbackOwner = nil
    local waRoot = _G["WeakAurasFrame"]

    if curr == waRoot then
        return nil
    end

    while curr and curr ~= UIParent and curr ~= WorldFrame and depth < 15 do
        if curr == DetectorFrame or curr == _G["AddonDetectorMinimapButton"] then
            return nil
        end

        -- If we hit the master WeakAurasFrame container without finding an aura, ignore it
        if waRoot and curr == waRoot then
            return nil
        end

        -- Check if this frame is a specific WeakAuras aura region
        local auraId, regionType = InspectWeakAuraFrame(curr)
        if auraId then
            -- Ignore invisible group/dynamicgroup bounding boxes so empty space isn't flagged
            if regionType == "group" or regionType == "dynamicgroup" then
                return nil
            end
            return "WeakAuras: |cffffd100" .. auraId .. "|r"
        end

        local owner = GetSingleFrameOwner(curr)
        if owner == "BLIZZARD" then
            return fallbackOwner
        elseif owner == ADDON_NAME then
            return nil
        elseif owner == "WeakAuras" or owner == "WeakAurasOptions" then
            -- Remember WeakAuras ownership, but keep climbing to find the parent region's aura ID
            fallbackOwner = owner
        elseif owner and not fallbackOwner then
            return owner
        end

        curr = curr:GetParent()
        depth = depth + 1
    end

    return fallbackOwner
end

local function IsFullscreenAnchor(frame, uiWidth, uiHeight)
    local w, h = frame:GetWidth(), frame:GetHeight()
    if not w or not h or w <= 1 or h <= 1 then
        return true
    end
    if w >= (uiWidth * 0.95) and h >= (uiHeight * 0.95) then
        if not frame:IsMouseEnabled() then
            return true
        end
    end
    return false
end

local function OnUpdateScanner(self, elapsed)
    if not isChecking then
        return
    end

    elapsedAccumulator = elapsedAccumulator + elapsed
    if elapsedAccumulator < UPDATE_INTERVAL then
        return
    end
    elapsedAccumulator = 0

    wipe(foundSet)
    wipe(foundList)

    local uiWidth, uiHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local frame = EnumerateFrames()

    while frame do
        if frame ~= self
            and frame ~= UIParent
            and frame ~= WorldFrame
            and frame:IsVisible()
            and frame:GetEffectiveAlpha() > 0
            and frame:GetLeft() ~= nil
            and not IsFullscreenAnchor(frame, uiWidth, uiHeight)
            and frame:IsMouseOver()
        then
            local addonLabel = ResolveFrameAddon(frame)
            if addonLabel and not foundSet[addonLabel] then
                foundSet[addonLabel] = true
                foundList[#foundList + 1] = addonLabel
            end
        end
        frame = EnumerateFrames(frame)
    end

    if #foundList > 0 then
        table.sort(foundList)
        ResultText:SetText(table.concat(foundList, "\n"))
    else
        ResultText:SetText("|cff888888None|r")
    end

    local textHeight = ResultText:GetStringHeight() or 14
    self:SetHeight(math.max(95, textHeight + 74))
end

--------------------------------------------------------------------------------
-- Start / Stop Controls
--------------------------------------------------------------------------------
local function StartChecking()
    isChecking = true
    elapsedAccumulator = UPDATE_INTERVAL
    CheckButton:Disable()
    StopButton:Enable()
    DetectorFrame:SetScript("OnUpdate", OnUpdateScanner)
end

local function StopChecking()
    isChecking = false
    CheckButton:Enable()
    StopButton:Disable()
    DetectorFrame:SetScript("OnUpdate", nil)
    ResultText:SetText("|cff888888Stopped. Press Check to scan.|r")
    DetectorFrame:SetHeight(95)
end

CheckButton:SetScript("OnClick", StartChecking)
StopButton:SetScript("OnClick", StopChecking)

DetectorFrame:SetScript("OnHide", function()
    if isChecking then
        StopChecking()
    end
end)

--------------------------------------------------------------------------------
-- Minimap Button (Draggable & Saved)
--------------------------------------------------------------------------------
local MinimapButton = CreateFrame("Button", "AddonDetectorMinimapButton", Minimap)
MinimapButton:SetSize(31, 31)
MinimapButton:SetFrameStrata("MEDIUM")
MinimapButton:SetFrameLevel(8)
MinimapButton:RegisterForClicks("LeftButtonUp")
MinimapButton:RegisterForDrag("LeftButton")
MinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local Icon = MinimapButton:CreateTexture(nil, "BACKGROUND")
Icon:SetSize(20, 20)
Icon:SetPoint("CENTER", 0, 0)
Icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")

local Border = MinimapButton:CreateTexture(nil, "OVERLAY")
Border:SetSize(53, 53)
Border:SetPoint("TOPLEFT", 0, 0)
Border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdateMinimapPosition()
    local angle = AddonDetectorDB and AddonDetectorDB.minimapPos or 225
    local rads = math.rad(angle)
    local x = math.cos(rads) * 80
    local y = math.sin(rads) * 80
    MinimapButton:ClearAllPoints()
    MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

MinimapButton:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
        AddonDetectorDB.minimapPos = angle
        UpdateMinimapPosition()
    end)
end)

MinimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
end)

MinimapButton:SetScript("OnClick", function()
    if DetectorFrame:IsShown() then
        DetectorFrame:Hide()
    else
        DetectorFrame:Show()
    end
end)

MinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("AddonDetector", 0.85, 0.55, 0.27)
    GameTooltip:AddLine("Left-Click: Toggle Window", 1, 1, 1)
    GameTooltip:AddLine("Left-Drag: Move Minimap Button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

MinimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Load saved minimap position on login
local Loader = CreateFrame("Frame")
Loader:RegisterEvent("ADDON_LOADED")
Loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        AddonDetectorDB = AddonDetectorDB or {}
        if type(AddonDetectorDB.minimapPos) ~= "number" then
            AddonDetectorDB.minimapPos = 225
        end
        UpdateMinimapPosition()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------
SLASH_ADDONDETECTOR1 = "/addondetector"
SLASH_ADDONDETECTOR2 = "/ad"
SlashCmdList["ADDONDETECTOR"] = function()
    if DetectorFrame:IsShown() then
        DetectorFrame:Hide()
    else
        DetectorFrame:Show()
    end
end
