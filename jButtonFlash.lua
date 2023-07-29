-- locals and speed
local AddonName, Addon = ...

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local IsAddOnLoaded = IsAddOnLoaded
local GetActionButtonForID = GetActionButtonForID
local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS

local TEXTURE_OFFSET = 3

local BARTENDER4_TOKEN = "Bartender4"
local BARTENDER4_NUM_MAX_BUTTONS = 180

local DOMINOS_TOKEN = "Dominos"
local DOMINOS_NUM_MAX_BUTTONS = 14 * NUM_ACTIONBAR_BUTTONS
local DOMINOS_PUSHED_STATE = "PUSHED"

-- main
function Addon:Load()
    self.frame = CreateFrame("Frame", nil)

    -- set OnEvent handler
    self.frame:SetScript("OnEvent", function(_, ...)
        self:OnEvent(...)
    end)

    self.frame:RegisterEvent("PLAYER_LOGIN")
end

-- frame events
function Addon:OnEvent(event, ...)
    local action = self[event]

    if (action) then
        action(self, ...)
    end
end

function Addon:PLAYER_LOGIN()
    self:SetupButtonFlash()
    self:HookActionEvents()

    local bt4 = IsAddOnLoaded(BARTENDER4_TOKEN)
    if (bt4) then
        self:HookBartender4Buttons()
    end

    local dominos = IsAddOnLoaded(DOMINOS_TOKEN)
    if (dominos) then
        self:HookDominosButtons()
    end

    self.frame:UnregisterEvent("PLAYER_LOGIN")
end

function Addon:SetupButtonFlash()
    local frame = CreateFrame("Frame", nil)
    frame:SetFrameStrata("TOOLTIP")

    local texture = frame:CreateTexture()
    texture:SetTexture([[Interface\Cooldown\star4]])
    texture:SetAlpha(0)
    texture:SetAllPoints(frame)
    texture:SetBlendMode("ADD")
    texture:SetDrawLayer("OVERLAY", 7)

    local animation = texture:CreateAnimationGroup()

    local alpha = animation:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0)
    alpha:SetOrder(1)

    local scale1 = animation:CreateAnimation("Scale")
    scale1:SetScale(1.5, 1.5)
    scale1:SetDuration(0)
    scale1:SetOrder(1)

    local scale2 = animation:CreateAnimation("Scale")
    scale2:SetScale(0, 0)
    scale2:SetDuration(.3)
    scale2:SetOrder(2)

    local rotation = animation:CreateAnimation("Rotation")
    rotation:SetDegrees(90)
    rotation:SetDuration(.3)
    rotation:SetOrder(2)

    self.overlay = frame
    self.animation = animation
end

-- hooks
-- regular action buttons
do
    local function Button_ActionButtonDown(id)
        Addon:ActionButtonDown(id)
    end

    local function Button_MultiActionButtonDown(bar, id)
        Addon:MultiActionButtonDown(bar, id)
    end

    function Addon:HookActionEvents()
        hooksecurefunc("ActionButtonDown", Button_ActionButtonDown)
        hooksecurefunc("MultiActionButtonDown", Button_MultiActionButtonDown)
    end
end

-- bartender4 support
do
    local function Button_OnClick(button, _, down)
        if (down) then
            Addon:AnimateButton(button)
        end
    end

    function Addon:HookBartender4Buttons()
        for i = 1, BARTENDER4_NUM_MAX_BUTTONS do
            local button = _G["BT4Button" .. i]

            if (button) then
                button:HookScript("OnClick", Button_OnClick)
            end
        end
    end
end

-- dominos support
do
    local function Button_OnClick(button, _, down)
        if (down) then
            Addon:AnimateButton(button)
        end
    end

    local function Button_SetButtonStateBase(button, state)
        if (DOMINOS_PUSHED_STATE == state) then
            Addon:AnimateButton(button)
        end
    end

    function Addon:HookDominosButtons()
        for i = 1, DOMINOS_NUM_MAX_BUTTONS do
            local button = _G["DominosActionButton" .. i]

            if (button) then
                -- dominos proxy action buttons
                -- mirror the pushed state of the target button
                hooksecurefunc(button, "SetButtonStateBase", Button_SetButtonStateBase)

                -- button mouse clicks
                button:HookScript("OnClick", Button_OnClick)
            end
        end
    end
end

function Addon:ActionButtonDown(id)
    local button = GetActionButtonForID(id)
    if (button) then
        self:AnimateButton(button)
    end
end

function Addon:MultiActionButtonDown(bar, id)
    local button = _G[bar .. "Button" .. id]
    if (button) then
        self:AnimateButton(button)
    end
end

function Addon:AnimateButton(button)
    if (not button:IsVisible()) then
        return
    end

    self.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -TEXTURE_OFFSET, TEXTURE_OFFSET)
    self.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", TEXTURE_OFFSET, -TEXTURE_OFFSET)

    self.animation:Stop()
    self.animation:Play()
end

-- begin
Addon:Load()
