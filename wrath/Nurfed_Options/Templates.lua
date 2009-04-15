local saveopt, onshow
local L = Nurfed:GetTranslations()

------------------------------------------
-- Option Menu Templates
-- Slider value text
local slidertext = function(self)
	local value = math.round(self:GetValue(), self.deci)
	_G[self:GetName().."value"]:SetText(value)
end
-- drop down menu
do	-- keep local dropmenu local...rofl?
	local dropmenu = CreateFrame("Frame")
	dropmenu.displayMode = "MENU"
	function Nurfed_DropMenu(self, tbl)
		local info = {}
		local btn = self
		local func
		
		if self.alt then
			func = function(self) btn:SetText(self.value) btn.alt(btn) end
		elseif self:GetParent():GetObjectType() == "EditBox" then
			func = function(self)
				local parent = btn:GetParent()
				parent:SetText(self.value)
				if parent:GetScript("OnEnterPressed") then
					parent:GetScript("OnEnterPressed")(parent)
				end
			end
		else
			func = function(self) 
				local valtext = _G[btn:GetName().."valtext"]
				if valtext then
					valtext:SetText(self.value or "")
				else
					btn:SetText(self.value) 
				end
				if btn.opt and btn.ofunc then
					btn.ofunc(btn.opt, self.value)
				else
					saveopt(btn) 
				end
			end
		end
		dropmenu.initialize = function()
			for _, v in ipairs(tbl) do
				info.text = v
				info.value = v
				info.func = func
				info.isTitle = nil
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info)
			end
		end
		ToggleDropDownMenu(1, nil, dropmenu, "cursor")
	end
	
	function Nurfed_GenerateMenu(menu, template, rows)
		local row, parent
		parent = _G["Nurfed"..menu.."Panel"]
		for i = 1, rows do
			row = Nurfed:create("Nurfed"..menu.."RowPanel"..i, template, parent)
			if row:GetObjectType() == "Button" then
				row:RegisterForClicks("AnyUp")
			end
			
			if i == 1 then
				row:SetPoint("TOPLEFT", "Nurfed"..menu.."Panelscroll", "TOPLEFT", 0, -3)
			else
				row:SetPoint("TOPLEFT", "Nurfed"..menu.."RowPanel"..(i - 1), "BOTTOMLEFT", 0, 0)
			end
		end
	end
end
-- Scroll menu
function Nurfed_Options_sliderOnValueChanged(self)
	local value = math.round(self:GetValue(), self.deci)
	local text = getglobal(self:GetName().."value")
	text:SetText(value)
end

function Nurfed_Options_ScrollMenu(self, val)
	if self then
		FauxScrollFrame_Update(self, self.pages, 1, 100)
		local page = FauxScrollFrame_GetOffset(self) + 1
		local children = { self:GetParent():GetChildren() }
		for _, child in ipairs(children) do
			if (not string.find(child:GetName(), "scroll", 1, true)) then
				if child.page == page then
					child:Show()
				else
					child:Hide()
				end
			end
		end
	end
end

function Nurfed_Options_ScrollMouseWheel(self, val)
    ScrollFrameTemplate_OnMouseWheel(self, val)
    Nurfed_Options_ScrollMenu(self, val)
end
-- color swatches
function Nurfed_Options_swatchSetColor(frame)
	local option = frame.option
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()
	local swatch = _G[frame:GetName().."bg"]
	swatch:SetVertexColor(r, g, b)
	frame.r = r
	frame.g = g
	frame.b = b
	NURFED_SAVED[frame.option] = { r, g, b, a }
	if frame.func then
		frame.func()
	end
end

function Nurfed_Options_swatchCancelColor(frame, prev)
	local option = frame.option
	local r = prev.r
	local g = prev.g
	local b = prev.b
	local a = prev.a
	local swatch = _G[frame:GetName().."bg"]
	swatch:SetVertexColor(r, g, b)
	frame.r = r
	frame.g = g
	frame.b = b
	NURFED_SAVED[frame.option] = { r, g, b, a }
	if frame.func then
		frame.func()
	end
end

function Nurfed_Options_swatchOpenColorPicker(self)
	CloseMenus()
	ColorPickerFrame.func = self.swatchFunc
	ColorPickerFrame.hasOpacity = self.hasOpacity
	ColorPickerFrame.opacityFunc = self.opacityFunc
	ColorPickerFrame.opacity = self.opacity
	ColorPickerFrame:SetColorRGB(self.r, self.g, self.b)
	ColorPickerFrame.previousValues = {r = self.r, g = self.g, b = self.b, a = self.opacity}
	ColorPickerFrame.cancelFunc = self.cancelFunc
	ColorPickerFrame:Show()
end

onshow = function(self)
	local text = _G[self:GetName().."Text"]
	local value = _G[self:GetName().."value"]
	local objtype = self:GetObjectType()
	if not text then
		text = _G[self:GetParent():GetName().."Text"]
		assert(text, "NO TEXT FRAME FOR:"..self:GetName())
	end
	text:SetText(self.text)
	if self.color then
		text:SetTextColor(unpack(self.color))
	end

	local point = select(3, self:GetPoint())
	if point and point:find("RIGHT") and objtype ~= "EditBox" then
		if value then
			value:ClearAllPoints()
			value:SetPoint("RIGHT", self, "LEFT", -3, 0)
		else
			text:ClearAllPoints()
			text:SetPoint("RIGHT", self, "LEFT", -1, 1)
			if text:GetText() ~= "" then
				self:SetHitRectInsets(-text:GetWidth(), 0, 0, 0)
			end
		end
	end
	if point and point:find("LEFT") and objtype ~= "EditBox" then
		if not value then
			if text:GetText() ~= "" then
				self:SetHitRectInsets(0, -text:GetWidth(), 0, 0)
			end
		end
	end
	if self.nohitrect then
		self:SetHitRectInsets(0, 0, 0, 0)
	end
	-- anchoring the value editbox of a slider in the template apparently does not
	-- move it...at all.  It is still getting anchored to the left/right
	-- even when the anchor to pos is not set to RIGHT at all
	-- look into further, until then hack it this way
	if value and value:GetObjectType() == "EditBox" and objtype == "Slider" then
		value:ClearAllPoints()
		value:SetPoint("TOP", self, "BOTTOM", 0, 0)
	end
	if self.fontobject then
		text:SetFontObject(self.fontobject)
	end
	if self.textpos then
		text:ClearAllPoints()
		local p1, p2, p3, p4, p5 = unpack(self.textpos)
		if type(p2) == "string" then	
			p2 = p2:gsub("$parent", self:GetName())
		end
		text:SetPoint(p1, p2, p3, p4, p5)
	end
	local opt
	if self.option then
		opt = Nurfed:getopt(self.option)
	elseif self.default then
		opt = self.default
	elseif self.opt and self.getopt then
		opt = self.getopt(self.opt, true)
	end

	if objtype == "CheckButton" and opt then
		self:SetChecked(opt)
	elseif objtype == "Slider" then
		local low = _G[self:GetName().."Low"]
		local high = _G[self:GetName().."High"]
		self:SetMinMaxValues(self.min, self.max)
		self:SetValueStep(self.step)
		if opt then
			self:SetValue(opt)
		end

		value.option = self.option
		value.val = self.val
		value.func = self.func
		if self.orientation then
			self:SetOrientation(self.orientation)
		end
	elseif objtype == "EditBox" then
		if type(opt) == "table" then
			local text = ""
			for name in pairs(opt) do
				text = text..name.."\r"
			end
			self:SetText(text)
		else
			self:SetText(opt or self.default or "")
		end
	elseif objtype == "Button" then
		local swatch = _G[self:GetName().."bg"]
		if swatch then
			local frame = self
			swatch:SetVertexColor(opt[1], opt[2], opt[3])
			self.r = opt[1]
			self.g = opt[2]
			self.b = opt[3]
			self.swatchFunc = function() Nurfed_Options_swatchSetColor(frame) end
			self.cancelFunc = function(x) Nurfed_Options_swatchCancelColor(frame, x) end
			if self.opacity then
				self.hasOpacity = frame.opacity
				self.opacityFunc = function() Nurfed_Options_swatchSetColor(frame) end
				self.opacity = opt[4]
			end
		else
			local valtext = _G[self:GetName().."valtext"]
			if valtext then
				valtext:SetText(opt or "")
			else
				self:SetText(opt or "")
			end
		end
	end
	self:SetScript("OnShow", nil)
end

saveopt = function(self)
	local value, objtype
	objtype = self:GetObjectType()

	if objtype == "CheckButton" then
		value = self:GetChecked() or false
		if value then
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	elseif objtype == "Slider" then
		value = self:GetValue()
	elseif objtype == "EditBox" then
		if not self.focus then return end
		value = self:GetText()
		if value == L["Default"] or value == L["default"] then
			value = nil
		end
		
	elseif objtype == "Button" then
		local valtext = _G[self:GetName().."valtext"]
		if valtext then
			value = valtext:GetText()
		else
			value = self:GetText()
		end
	end

	if self.option then
		local opt = self.option
		if type(NURFED_DEFAULT[opt]) == "boolean" then
			value = value == 1 and true or false
		end
		if type(value) == "nil" or value == NURFED_DEFAULT[opt] then
			NURFED_SAVED[opt] = nil
		else
			NURFED_SAVED[opt] = value
		end
	end
	if self.nrfevent then
		Nurfed:sendevent(self.nrfevent)
	end
	if self.func then
		self.func(value)
	end
	if self.ofunc and self.opt then
		self.ofunc(self.opt, value)
	end
	if self.funcself then
		self.funcself(self)
	end
end

local templates = {
	nrf_check = {
		type = "CheckButton",
		uitemp = "OptionsCheckButtonTemplate",
		OnShow = onshow,
		OnClick = saveopt,
		OnEnter = function(self)
			if self.hint then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
				GameTooltip:ClearLines()
				GameTooltip:AddLine(L["Hint:"], nil, nil, nil, true)
				GameTooltip:AddLine(self.hint, nil, nil, nil, true)
				GameTooltip:Show()
			end
		end,
		OnLeave = function() GameTooltip:Hide() end,
	},
	nrf_button = {
		type = "Button",
		size = { 60, 18 },
		Backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 10,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		},
		BackdropColor = { 0, 0, 0, 0.75 },
		Font = { "Fonts\\ARIALN.TTF", 12, "OUTLINE" },
		TextColor = { 1, 1, 1 },
		HighlightTextColor = { 0, 0.75, 1 },
		DisabledTextColor = { 1, 0, 0 },
		PushedTextOffset = { 1, -1 },
		children = {
			valtext = {
				type = "FontString",
				layer = "ARTWORK",
				Anchor = { "CENTER", "$parent", "CENTER", 0, 0 },
				FontObject = "GameFontNormalSmall",
				JustifyH = "LEFT",
			},
		},
		OnShow = function(self)
			local valtext = _G[self:GetName().."valtext"]
			local text = self.opt or self.text or self.Text
			if not text then text = self:GetText() end
			text = text or ""
			valtext:SetText(text)
			self:SetWidth(valtext:GetStringWidth()+12)
			self:SetScript("OnShow", nil)
		end,
		OnEnter = function(self)
			if self.hint then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
				GameTooltip:ClearLines()
				GameTooltip:AddLine(L["Hint:"], nil, nil, nil, true)
				GameTooltip:AddLine(self.hint, nil, nil, nil, true)
				GameTooltip:Show()
			end
		end,
		OnLeave = function() GameTooltip:Hide() end,
	},
	nrf_slider = {
		type = "Slider",
		uitemp = "OptionsSliderTemplate",
		children = {
			value = {
				template = "nrf_editbox",
				FontObject = "GameFontNormalSmall",
				size = { 45, 18 },
				Anchor = { "TOP", "$parent", "BOTTOM", 0, 0 },
				Backdrop = {
					bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					tile = true,
					tileSize = 16,
					insets = { left = 3, right = 3, top = 3, bottom = 3 },
				},
				BackdropColor = { 0, 0, 0.2, 0.75 },
				OnTextChanged = function(self)
					if self.focus then
						local parent = self:GetParent()
						local value = tonumber(self:GetText())
						local min, max = parent:GetMinMaxValues()
						if not value or value < min then return end
						if value > max then value = max end
						value = math.round(value, parent.deci)
						parent:SetValue(value)
						saveopt(parent)
					end
				end,
				OnEnterPressed = function(self)
					local p = self:GetParent()
					local v = tonumber(self:GetText())
					local min, max = p:GetMinMaxValues()
					if v > max then v = max
					elseif v < min then v = min
					end
					v = math.round(v, p.deci)
					p:SetValue(v)
					saveopt(p)
					self:ClearFocus()
				end,
				OnEditFocusGained = function(self) self:HighlightText() self.focus = true end,
				OnEditFocusLost = function(self) self:HighlightText(0, 0) self.focus = nil end,
			},
		},
		OnShow = function(self) 
			self:SetFrameLevel(30)
			self:EnableMouseWheel(true)
			if self.numText then
				_G[self:GetName().."High"]:SetText(self.max)
				_G[self:GetName().."Low"]:SetText(self.min)
			end
			onshow(self) 
		end,
		OnMouseUp = function(self) 
			local editbox = _G[self:GetName().."value"]
			editbox:SetCursorPosition(0)
			editbox:ClearFocus()
			saveopt(self) 
		end,
		OnValueChanged = function(self) 
			local value = math.round(self:GetValue(), self.deci)
			_G[self:GetName().."value"]:SetText(value) 
		end,
		OnMouseWheel = function(self, change)
			local value = self:GetValue()
			local newValue
			if IsShiftKeyDown() then
				newValue = self.step
			else
				if self.bigStep then
					newValue = self.bigStep
				else
					newValue = self.step
				end
			end
			if change > 0  then
				value = value + newValue
			else
				value = value - newValue
			end
			self:SetValue(value)
			saveopt(self)
		end,
		OnEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
			GameTooltip:ClearLines()
			GameTooltip:AddLine(L["Hint:"], nil, nil, nil, true)
			GameTooltip:AddLine(self.hint or L["Hold SHIFT when you scroll for smaller ranges."], nil, nil, nil, true)
			GameTooltip:Show()
		end,
		OnLeave = function() GameTooltip:Hide() end,
	},
	nrf_editbox = {
		type = "EditBox",
		AutoFocus = false,
		size = { 155, 20 },
		Backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 10,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		},
		BackdropColor = { 0, 0, 0.2, 0.75 },
		FontObject = "GameFontNormal",
		TextInsets = { 3, 3, 3, 3 },
		children = {
			Text = {
				type = "FontString",
				layer = "ARTWORK",
				Anchor = { "BOTTOMLEFT", "$parent", "TOPLEFT", 3, 0 },
				FontObject = "GameFontHighlight",
				JustifyH = "LEFT",
			},
		},
		OnShow = onshow,
		OnEscapePressed = function(self) self:ClearFocus() end,
		OnEnterPressed = function(self) if self.option and self.saveopt then saveopt(self) end self:ClearFocus(); end,
		OnEditFocusGained = function(self) self:HighlightText() self.focus = true end,
		OnEditFocusLost = function(self) self:HighlightText(0, 0) self.focus = nil end,
		OnEnter = function(self)
			if self.hint then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
				GameTooltip:ClearLines()
				GameTooltip:AddLine(L["Hint:"], nil, nil, nil, true)
				GameTooltip:AddLine(self.hint, nil, nil, nil, true)
				GameTooltip:Show()
			end
		end,
		OnLeave = function() GameTooltip:Hide() end,

		--OnTextChanged = function(self) end,
	},
	nrf_options = {
		type = "Frame",
		size = { 411, 271 },
		Anchor = { "TOPRIGHT", "$parentSubText", "BOTTOMRIGHT", 1, 0 },
		Backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		},
		BackdropColor = { 0, 0, 0, 0.95 },
		Alpha = 0,
		--Hide = true,
		children = {},
	},
	nrf_actionstates = {
		type = "Button",
		size = { 175, 14 },
		children = {
			delete = {
				type = "Button",
				layer = "ARTWORK",
				size = { 14, 14 },
				Anchor = { "LEFT", "$parent", "LEFT", 0, 0 },
				NormalTexture = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
				PushedTexture = "Interface\\Buttons\\UI-GroupLoot-Pass-Down",
				HighlightTexture = "Interface\\Buttons\\UI-GroupLoot-Pass-Highlight",
				OnClick = function(self) Nurfed_DeleteState(self) end,
				OnEnter = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(DELETE, 1, 0, 0)
					GameTooltip:Show()
				end,
				OnLeave = function() GameTooltip:Hide() end,
			},
			name = {
				type = "FontString",
				layer = "ARTWORK",
				size = { 102, 14 },
				Anchor = { "LEFT", "$parentdelete", "RIGHT", 5, 0 },
				FontObject = "GameFontNormalSmall",
				JustifyH = "LEFT",
				TextColor = { 1, 1, 1 },
			},
			value = {
				type = "FontString",
				layer = "ARTWORK",
				size = { 50, 14 },
				Anchor = { "LEFT", "$parentname", "RIGHT", 5, 0 },
				FontObject = "GameFontNormalSmall",
				JustifyH = "RIGHT",
				TextColor = { 1, 1, 1 },
			},
			HighlightTexture = {
				type = "Texture",
				layer = "BACKGROUND",
				Texture = "Interface\\QuestFrame\\UI-QuestTitleHighlight",
				BlendMode = "ADD",
				Anchor = "all",
			},
		},
	},
	nrf_actionbars_row = {
		type = "Button",
		size = { 150, 14 },
		children = {
			expand = {
				type = "Button",
				layer = "ARTWORK",
				size = { 14, 14 },
				Anchor = { "LEFT", "$parent", "LEFT", 5, 0 },
				NormalTexture = "Interface\\Buttons\\UI-PlusButton-Up",
				PushedTexture = "Interface\\Buttons\\UI-PlusButton-Down",
				HighlightTexture = "Interface\\Buttons\\UI-PlusButton-Hilight",
				OnClick = function(...) Nurfed_ExpandBar(...) end,
			},
			name = {
				type = "FontString",
				layer = "ARTWORK",
				size = { 105, 14 },
				Anchor = { "BOTTOMLEFT", "$parentexpand", "BOTTOMRIGHT", 5, 0 },
				FontObject = "GameFontNormal",
				JustifyH = "LEFT",
				TextColor = { 1, 1, 1 },
			},
			states = {
				template = "nrf_check",
				size = { 16, 16 },
				Anchor = { "LEFT", "$parentname", "RIGHT", 5, 0 },
				OnEnter = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(L["Show States"], 1, 1, 0)
					GameTooltip:Show()
				end,
				OnLeave = function() GameTooltip:Hide() end,
				OnClick = function(...) Nurfed_ToggleStates(...) end,
			},
			delete = {
				type = "Button",
				layer = "ARTWORK",
				size = { 14, 14 },
				Anchor = { "LEFT", "$parentstates", "RIGHT", 5, 0 },
				NormalTexture = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
				PushedTexture = "Interface\\Buttons\\UI-GroupLoot-Pass-Down",
				HighlightTexture = "Interface\\Buttons\\UI-GroupLoot-Pass-Highlight",
				OnClick = function() Nurfed_DeleteBar() end,
				OnEnter = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(DELETE, 1, 0, 0)
					GameTooltip:Show()
				end,
				OnLeave = function() GameTooltip:Hide() end,
			},
			HighlightTexture = {
				type = "Texture",
				layer = "BACKGROUND",
				Texture = "Interface\\QuestFrame\\UI-QuestTitleHighlight",
				BlendMode = "ADD",
				Anchor = "all",
			},
		},
		OnClick = function(self, val) Nurfed_ActionBar_OnClick(val) end,
		Hide = true,
	},
	nrf_color = {
		type = "Button",
		size = { 18, 18 },
		children = {
			bg = {
				type = "Texture",
				Texture = "Interface\\ChatFrame\\ChatFrameColorSwatch",
				layer = "BACKGROUND",
				Anchor = "all",
				VertexColor = { 1, 1, 1 },
			},
			Text = {
				type = "FontString",
				layer = "ARTWORK",
				Anchor = { "LEFT", "$parent", "RIGHT", 1, 0 },
				FontObject = "GameFontNormalSmall",
				JustifyH = "LEFT",
			},
		},
		OnShow = onshow,
		OnClick = function(self) Nurfed_Options_swatchOpenColorPicker(self) end,
	},
	nrf_scroll = {
		type = "ScrollFrame",
		Anchor = { "LEFT", 0, 0 },
		size = { 385, 271 },
		uitemp = "FauxScrollFrameTemplate",
		OnVerticalScroll = function(self, val) FauxScrollFrame_OnVerticalScroll(self, val, 100, Nurfed_Options_ScrollMenu) end,
		OnShow = function(self) 
			Nurfed_Options_ScrollMenu(self)
		end,
		OnMouseWheel = function(...) Nurfed_Options_ScrollMouseWheel(...) end,
	},
	nrf_multiedit = {
		type = "ScrollFrame",
		uitemp = "UIPanelScrollFrameTemplate",
		children = {
			Text = {
				type = "FontString",
				layer = "ARTWORK",
				Anchor = { "BOTTOMLEFT", "$parent", "TOPLEFT", 3, 0 },
				FontObject = "GameFontNormalSmall",
				JustifyH = "LEFT",
			},
			edit = {
				type = "EditBox",
				AutoFocus = false,
				MultiLine = true,
				FontObject = "GameFontNormalSmall",
				TextColor = { 1, 1, 1 },
				TextInsets = { 3, 3, 3, 3 },
				Anchor = { "TOPRIGHT", "$parent", "TOPRIGHT", 0, 0 },
				OnShow = function(self)
					local parent = self:GetParent()
					self.option = parent.option
					self.func = parent.func
					if parent.ltrs then
						self:SetMaxLetters(parent.ltrs)
					end
					self:ClearAllPoints();
					self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 4)
					self:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -4)
					onshow(self)
					parent:GetScript("OnLoad")(parent)
				end,
				OnEscapePressed = function(self) self:ClearFocus() end,
				OnEditFocusGained = function(self) self.focus = true end,
				OnEditFocusLost = function(self) saveopt(self) self.focus = nil end,
				OnTabPressed = function(self) self:Insert("   ") end,
				OnEnterPressed = function(self) self:GetScript("OnTextChanged")() end,
				OnTextChanged = function(self)
					local scrollBar = _G[self:GetParent():GetName().."ScrollBar"]
					self:GetParent():UpdateScrollChildRect()
					local min, max = scrollBar:GetMinMaxValues()
					if max > 0 then
						if self.max ~= max then
							self.max = max
							scrollBar:SetValue(max)
						end
					else
						scrollBar:SetValue(min)
						self:SetPoint("BOTTOM")
					end
				end,
			},
			bg = {
				type = "Frame",
				--size = { 1, 1 },
				Anchor = { "TOPLEFT", "$parent", "TOPLEFT", 0, 0 },
				Backdrop = {
					bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile = true,
					tileSize = 16,
					edgeSize = 8,
					insets = { left = 2, right = 2, top = 2, bottom = 2 },
				},
				BackdropColor = { 0, 0, 0, 0.95 },
				OnShow = function(self)
					local parent = self:GetParent()
					self:SetWidth(parent:GetWidth()+5)
					self:SetHeight(parent:GetHeight())
					self:SetFrameLevel(1)
				end,
			},	
		},
		OnLoad = function(self)
			local child = _G[self:GetName().."edit"]
			local text = _G[self:GetName().."Text"]
			child:SetWidth(self:GetWidth())
			text:SetText(self.text or "")
			self:SetScrollChild(child)
		end,
	},
	nrf_optbutton = {
		template = "nrf_button",
		children = {
			Text = {
				type = "FontString",
				layer = "ARTWORK",
				Anchor = { "RIGHT", "$parent", "LEFT", -3, 0 },
				FontObject = "GameFontNormalSmall",
				JustifyH = "LEFT",
			},
		},
		OnShow = onshow,
	},
}

for k, v in pairs(templates) do
  Nurfed:createtemp(k, v)
end
NurfedTemplatesOnShow = onshow
Nurfed:setversion("Nurfed-Options", "$Date$", "$Rev$")