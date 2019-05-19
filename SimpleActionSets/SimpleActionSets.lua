----------------------------------------------------------
----------------------------------------------------------
-- Simple Action Sets Beta 0.59				--
--							--
-- Allows all 120 action buttons to be saved to action	--
-- sets. Sets can then be swapped to on the fly.	--
--							--
-- Thanks to Cide, Ts, and Gello for some excellent	--
-- mods to "borrow" from.				--
----------------------------------------------------------
----------------------------------------------------------

SAS_POS = 270;
SAS_OFFSET = 0

SAS_POS_DEFAULT = 270;
SAS_OFFSET_DEFAULT = 0;

SAS_POS_TEMP = nil;
SAS_OFFSET_TEMP = nil;

SAS_NO_REMOVE = nil;

--SASDebug = nil;

local PlrName;
local PlrClass; -- not used yet

local inCombat;
local delayedSet;
local delayedSetPlayer;

-- Path name for all icons in the game
local IconPath = "Interface\\Icons\\";

-- Basic data broker support
local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("SimpleActionSets", {
	type = "launcher",
	label = "SimpleActionSets",
	icon = "Interface\\AddOns\\SimpleActionSets\\sas",
	OnClick = function(self,button)
		if button == "RightButton" then
			ToggleDropDownMenu(1, nil, SAS_SetsDropDown, self, 0, 0);
		else
		SASMain_Toggle()
		end
	end,
	OnTooltipShow = function(tt)
		tt:AddLine("Simple Action Sets")
		tt:AddDoubleLine("Current Set", SAS_GetCurrentSet(), 1,1,1, 0.75,0.75,0.75)
	end,
})

------------------------------
-- SAS Main Frame functions --
------------------------------

local SASMainTabs = {
	{280,"SASSets"},
	{185,"SASOptions"},
	{185,"SASHelp"},
	};

function SASMain_UpdateDisplay()
	SASSets:Hide()
	SASOptions:Hide();
	SASHelp:Hide();
	local tab = SASMain.selectedTab;
	local height = SASMainTabs[tab][1];
	SASActions:SetHeight(height);
	SASMainBottomDivider:SetPoint("TOPLEFT", SASMainTopDivider, "BOTTOMLEFT", 0, 10-height);
	getglobal(SASMainTabs[tab][2]):Show();
end

function SASMain_Toggle()
	if ( SASMain:IsVisible() ) then
		HideUIPanel(SASMain);
	else
		ShowUIPanel(SASMain);
	end
end


-----------------------------
-- Actions Frame functions --
-----------------------------
function SASActions_OnShow()
	SASActions_Load( SAS_GetCurrentSet() );
end

function SASActions_OnHide()
	SAS_Temp = nil;
end

function SASActions_Load( set, plr )
	SAS_Temp = {};

	if ( not plr ) then
		plr = PlrName;
	end

	if ( not set or set == SAS_TEXT_CURRENT ) then
		set = nil;
		SAS_Temp = SAS_IterateActions();
		SASDebug( "Loading current actions" );
		UIDropDownMenu_Initialize(SASActionSetsDropDown, SASActions_DropDown_Initialize);
		UIDropDownMenu_SetSelectedID( SASActionSetsDropDown, 0 );
		SASActionSetsDropDownButton:Disable();
		SASActionSetsDropDownText:SetText( "|c00999999"..SAS_TEXT_CURRENT );
		SASActionsDelete:Disable();
	elseif ( plr ~= PlrName ) then
		SAS_Temp = SAS_CopyTable(SAS_Saved[plr]["s"][set]);
		SASDebug( "Loading set "..set.." from "..plr );
		UIDropDownMenu_Initialize(SASActionSetsDropDown, SASActions_DropDown_Initialize);
		UIDropDownMenu_SetSelectedID( SASActionSetsDropDown, 0 );
		SASActionSetsDropDownText:SetText( "|c00999999"..SAS_TEXT_CURRENT );
		SASActionsDelete:Disable();
	else
		SAS_Temp = SAS_CopyTable(SAS_Saved[plr]["s"][set]);
		SASDebug( "Loading set "..set );
		UIDropDownMenu_Initialize(SASActionSetsDropDown, SASActions_DropDown_Initialize);
		UIDropDownMenu_SetSelectedName( SASActionSetsDropDown, set );
		SASActionsDelete:Enable();
	end

	for k, v in pairs(SAS_Saved[PlrName]["s"]) do
		SASActionSetsDropDownButton:Enable();
		break;
	end

	SASActions_Display();
	SASActionsSave:Disable();
	--SAS_CurrentSet = set;
	TitanPanelSAS_Update();
end

function SASActions_Bar_CheckAll( self )
	-- Check all bars enabled or disabled
	local check = self:GetChecked();
	for i = 0, 9 do
		getglobal( "SASActionBar"..i.."Enable"):SetChecked(check);
		--SASActions_Bar_Toggle( i, check );
		if ( SAS_Temp[i] ) then
			if ( check ) then
				SAS_Temp[i][0] = nil;
			else
				SAS_Temp[i][0] = 1;
			end
		end
	end
	SASActions_Display();
end

function SASActions_BarEnable_OnClick( bar, enable )
	-- Enable or disable a bar
	if ( SAS_Temp[bar] ) then
		if ( enable ) then
			SAS_Temp[bar][0] = nil;
		else
			SAS_Temp[bar][0] = 1;
		end
	end
	SASActions_UpdateBar( bar )
	SASActionsCheckAll:SetChecked(1);

	SASActions_SaveEnable();
end

function SASActionBarButton_OnClick( self, button )
	local bar = self:GetParent():GetID();
	local enable = SAS_BarEnabled(bar)
	local LocalSavedBar = SAS_CopyTable(SAS_Temp[bar]);
	local returnbar = SAS_DraggingBar;

	if ( button == "RightButton" ) then
		if ( LocalSavedBar ) then
			local set;
			for id = 1, 12 do
				if ( not LocalSavedBar[id] or type(LocalSavedBar[id]) == "number" ) then
					if ( not set ) then
						set = (LocalSavedBar[id] or -1) + 1;
					end
					if ( set == 2 ) then
						SAS_Temp[bar][id] = nil;
					else
						SAS_Temp[bar][id] = set;
					end
				end
			end
		end
		LocalSavedBar = nil;
	elseif ( SASFakeDragFrame.Bar and not IsShiftKeyDown() and not IsControlKeyDown() ) then
		SAS_Temp[bar] = SASFakeDrag_Drop(1);
		--SAS_Temp[bar]["enable"] = enable;
		if ( returnbar ) then
			SAS_DraggingBar = nil;
			--enable = SAS_Temp[returnbar]["enable"];
			SAS_Temp[returnbar] = SAS_CopyTable(LocalSavedBar);
			--SAS_Temp[returnbar]["enable"] = enable;
			SASActions_UpdateBar(returnbar);
		end
		LocalSavedBar = nil;
	elseif ( IsControlKeyDown() and not IsShiftKeyDown() ) then
		SAS_Temp[bar] = {};
		--SAS_Temp[bar]["enable"] = enable;
	end

	if ( SAS_BarHasActions(bar) and LocalSavedBar ) then
		SASFakeDrag_PickupBar(LocalSavedBar);
		if ( not IsShiftKeyDown() ) then
			SAS_DraggingBar = bar;
		end
	end
	SASActions_UpdateBar(bar);
	SASActions_SaveEnable();
end

function SASActionBarButton_OnReceiveDrag( self )
	SASActionBarButton_OnClick( self );
end

function SASActionBarButton_OnDragStart( self )
	local bar = self:GetParent():GetID();
	if ( SAS_BarHasActions(bar) ) then
		SASDebug("Picking up bar "..bar );
		SASFakeDrag_PickupBar( SAS_Temp[bar] );
		SAS_DraggingBar = bar;
		SASActions_UpdateBar(bar);
	else
		SASFakeDrag_PickupBar();
		SAS_DraggingBar = nil;
	end
end

function SASActionBarButton_OnEnter( self )
	self:SetScript("OnUpdate", SASActionBarButton_OnUpdate);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText( getglobal("SAS_TEXT_BARS_"..self:GetParent():GetID()) );
	GameTooltip:Show();
end

function SASActionBarButton_OnLeave( self )
	self:SetScript("OnUpdate", nil);

	for i=1, 12 do
		local button = getglobal( self:GetParent():GetName().."Action"..i ):GetName();
		getglobal( button.."Delete" ):Hide();
		getglobal( button.."Copy" ):Hide();
	end

	GameTooltip:Hide();
end

function SASActionBarButton_OnUpdate( self )
	if ( not SAS_Temp ) then return; end

	local BarFrame = self:GetParent();
	local barName = BarFrame:GetName();

	for i=1, 12 do
		local button = getglobal( barName.."Action"..i ):GetName();
		if ( IsControlKeyDown() and not IsShiftKeyDown() and getglobal( button.."Icon" ):IsVisible() ) then
			getglobal( button.."Delete" ):Show();
			getglobal( button.."Copy" ):Hide();
		elseif ( IsShiftKeyDown() and not IsControlKeyDown() and SAS_BarHasActions(BarFrame:GetID()) ) then
			getglobal( button.."Copy" ):Show();
			getglobal( button.."Delete" ):Hide();
		else
			getglobal( button.."Delete" ):Hide();
			getglobal( button.."Copy" ):Hide();
		end
	end
end

function SASActionBarButton_OnDragStop()
	SASFakeDrag_Drop();
end

function SASActions_DropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, SASActions_DropDown_Initialize);
	UIDropDownMenu_SetWidth(135,self);
	UIDropDownMenu_SetButtonWidth(24,self);
	UIDropDownMenu_JustifyText("LEFT",self);
	if ( SAS_GetCurrentSet() ) then
		UIDropDownMenu_SetSelectedName( self, SAS_GetCurrentSet());
	else
		UIDropDownMenu_SetText( "|c00999999"..SAS_TEXT_CURRENT, self );
	end
end

function SASActions_DropDown_Initialize(self)
	if ( not SAS_Saved or not SAS_Saved[PlrName] or not SAS_Saved[PlrName]["s"] ) then return; end
	local list = {};
	for k, v in pairs(SAS_Saved[PlrName].s) do
		tinsert(list, k);
	end
	table.sort(list);
	local info;
	for k, v in ipairs(list) do
		info = {};
		info.text = v;
		info.value = v;
		info.justifyH = "LEFT";
		info.func = SASActions_DropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function SASActions_DropDown_OnClick()
	UIDropDownMenu_SetSelectedID( SASActionSetsDropDown, this:GetID() );
	SASActions_Load(this:GetText());
end

function SASActions_Display()
	-- Update the display of all bars.
	if ( SAS_Temp ) then
		for i=0, 9 do
			SASActions_UpdateBar( i );
		end
	end
	SASActions_SaveEnable();
end

function SASActions_UpdateBar( bar )
	-- Update the display of a bar
	local BarFrame = getglobal( "SASActionBar"..bar );
	if ( SAS_Temp[bar] ) then
		getglobal( BarFrame:GetName().."Enable"):SetChecked(not SAS_Temp[bar][0]);
	end
	if ( bar ) then
		for i=1, 12 do
			SASActions_UpdateAction( self, bar, i );
		end
	end

	if ( SAS_DraggingBar == bar and SASFakeDragFrame:IsVisible() ) then
		BarFrame:SetAlpha(0.5);
	else
		BarFrame:SetAlpha(1.0);
	end
end

function SAS_BarEnabled( bar, set )
	if ( not set ) then set = SAS_Temp; end
	if ( set and set[bar] ) then
		return not set[bar][0];
	end
end

function SASActions_UpdateAction(self, bar, id)
	-- Update the display of an action.
	local button = getglobal( "SASActionBar"..bar.."Action"..id ):GetName();
	local icon = getglobal( button.."Icon" );
	local buttonName = getglobal( button.."Name" );
	local normalTexture = getglobal( button.."NormalTexture" );
	local border = getglobal( button.."Border" );
	local hotkey = getglobal( button.."HotKey" );
	local enable = SAS_BarEnabled(bar);

	if ( SAS_Saved[PlrName]["NoEmptyButtons"] and (not SAS_Temp[bar] or not SAS_Temp[bar][id]) ) then
		enable = nil;
	elseif ( not SAS_Saved[PlrName]["EmptyBars"] and not SAS_BarHasActions(bar) ) then
		enable = nil;
	end
	SetDesaturation( getglobal( "SASActionBar"..bar.."Action"..id.."Icon" ), not enable );
	border:Hide();
	normalTexture:SetVertexColor(1.0, 1.0, 1.0, 1.0);

	if ( enable ) then
		getglobal(button):SetAlpha(1.0);
		border:SetVertexColor(1.0, 0.5, 0.0, 0.2);
		border:Show();

	else
		getglobal(button):SetAlpha(0.5);
		border:SetVertexColor(0.5, 1.0, 1.0, 0.2);
		border:Show();
	end

	hotkey:SetTextColor(0.25,0.25,0.25);

	if ( not SAS_Temp ) then
		getglobal( button ):Disable();
	else
		getglobal( button ):Enable();

		icon:Hide()
		buttonName:Hide();
		icon:SetVertexColor(1.0, 1.0, 1.0);

		if ( SAS_Temp[bar] and SAS_Temp[bar][id] ) then
			if ( SAS_Temp[bar][id] == 0 ) then
				normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot");
				border:SetVertexColor(1.0, 0.5, 0.0, 1);
				border:Show();
				icon:SetTexture();
				icon:Show();
			elseif ( SAS_Temp[bar][id] == 1 ) then
				getglobal(button):SetAlpha(0.5);
				normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2");
				border:SetVertexColor(0.5, 1.0, 1.0, 1);
				border:Show();
				icon:SetTexture();
				icon:Show();
			else
				local name, texture, rank, link, macro = SAS_ParseActionInfo( SAS_Temp[bar][id] ); --SAS_Temp[bar][id][1], SAS_Temp[bar][id][2], SAS_Temp[bar][id][3], SAS_Temp[bar][id][4], SAS_Temp[bar][id][5];
				texture = SAS_FullPath(texture);
				icon:SetTexture( texture );
				icon:Show();
				normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2");
				hotkey:SetTextColor(0.6,0.6,0.6);

				if ( macro ) then
					buttonName:SetText( name );
					buttonName:Show();
					buttonName:SetTextColor(1.0, 1.0, 1.0);
					if ( not SAS_FindMacro( name, texture, macro ) ) then
						border:SetVertexColor(1.0, 0.0, 0.0, 0.35);
						buttonName:SetTextColor(0.4, 0.4, 0.4);
						border:Show();
						normalTexture:SetVertexColor(0.9, 0.0, 0.0, 1.0);
						icon:SetVertexColor(0.4, 0.4, 0.4);
					end
				elseif ( link ) then
					border:SetVertexColor(0, 1.0, 0, 0.35);
					border:Show();
					local itemLink;
					if ( link == "?" or link == "1" ) then
						itemLink = SAS_CheckItem( name, bar*12+id, SASActions_GetLoaded() );
					else
						itemLink = SAS_FindItem( link );
					end
					if ( not itemLink or itemLink == "?" ) then
						border:SetVertexColor(1.0, 0.0, 0.0, 0.35);
						normalTexture:SetVertexColor(0.9, 0.0, 0.0, 1.0);
						icon:SetVertexColor(0.4, 0.4, 0.4);
					elseif ( link == "?" ) then
						SAS_Temp[bar][id] = SAS_IncActionInfo( SAS_Temp[bar][id], itemLink, 4 );
					end
				elseif ( rank == "MOUNT" or rank == "CRITTER" ) then
					if ( not SAS_FindCompanion( name, rank ) ) then
						icon:SetVertexColor(0.4, 0.4, 0.4);
						border:SetVertexColor(1.0, 0.0, 0.0, 0.35);
					end
				else
					local spellNum, highest = SAS_FindSpell( name, rank );
					if ( not spellNum ) then
						if ( highest ) then
							border:SetVertexColor(0.0, 0.0, 1.0, 0.7);
						else
							icon:SetVertexColor(0.4, 0.4, 0.4);
							border:SetVertexColor(1.0, 0.0, 0.0, 0.35);
						end
						border:Show();
					elseif ( not rank ) then
						local checktexture = GetSpellTexture( spellNum, BOOKTYPE_SPELL );
						if ( texture ~= checktexture ) then
							icon:SetTexture( checktexture );
							local set = SASActions_GetLoaded();
							if ( set ) then
								SAS_Temp[bar][id] = SAS_IncActionInfo( SAS_Temp[bar][id], checktexture, 2 );
								SAS_Saved[PlrName]["s"][set][bar][id] = SAS_IncActionInfo( SAS_Saved[PlrName]["s"][set][bar][id], checktexture, 2 );
							end
						end
					end
				end
			end
		elseif ( SAS_Temp[bar] ) then
			if ( enable ) then
				normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot");
			else
				normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2");
			end
		end
	end
end

function SASActions_SaveNew( set )
	SASSaveMenuNameEB:SetText("");
	ShowUIPanel(SASSaveMenu);
	if ( set ) then
		SASSaveMenuNameEB:SetText( set );
		SASSaveMenu_Save( set );
	end
end

function SASActions_ClearTemp()
	-- Clear the temp set
	for i=0, 9 do
		SAS_Temp[i] = {};
	end
	SASActions_Display();
end

function SASActions_LoadCurrent()
	if ( SASActionsSave:GetButtonState() == "DISABLED" ) then
		SASActions_Load();
	else
		SAS_Warning("UNSAVED_LOAD", SASActions_Load);
	end
end

function SASActions_SwapSet()
	if ( SASActionsSave:GetButtonState() == "NORMAL" ) then
		SAS_Warning("SWAPPINGSAVE", SASActions_SwapSave, SASActions_GetLoaded());
	else
		SAS_Warning("SWAPPING", SAS_SwapSet, SASActions_GetLoaded());
	end
end

function SASActions_SwapSave( set )
	SAS_SaveSet( set );
	SAS_SwapSet( set );
end

function SASActions_Delete()
	SAS_Warning("DELETE", SAS_Delete, SASActions_GetLoaded());
end

function SASActions_Save()
	SAS_Warning("SAVE", SAS_SaveSet, SASActions_GetLoaded());
end

function SASActions_SaveEnable()
	local set = SASActions_GetLoaded();
	if ( set and SAS_CompareSet(SAS_Temp, SAS_Saved[PlrName]["s"][set], 2) ) then
		SASActionsSave:Enable();
	else
		SASActionsSave:Disable();
	end
end

function SASActions_Cancel(self)
	if ( SASActionsSave:GetButtonState() == "DISABLED" ) then
		HideUIPanel(self:GetParent());
	else
		SAS_Warning("UNSAVED_CANCEL", SASMain_Toggle);
	end
end

function SASActions_GetLoaded()
	local set = UIDropDownMenu_GetSelectedName( SASActionSetsDropDown );
	if ( set ~= SAS_TEXT_CURRENT ) then
		return set;
	end
end

function SASActionsSave_Enable()
	SASActionsSaveLeft:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	SASActionsSaveMiddle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	SASActionsSaveRight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	SASActionsSave:oldEnable();
	SASActionsSave:EnableMouse(1);
end

function SASActionsSave_Disable()
	SASActionsSaveLeft:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	SASActionsSaveMiddle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	SASActionsSaveRight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	SASActionsSave:oldDisable();
	SASActionsSave:EnableMouse();
end

function SASSets_Character_DropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, SASSets_Character_DropDown_Initialize);
	UIDropDownMenu_SetWidth(160,self);
	UIDropDownMenu_SetButtonWidth(24,self);
	UIDropDownMenu_JustifyText("LEFT",self);
	UIDropDownMenu_SetSelectedID(self, 1 );
end

function SASSets_Character_DropDown_Initialize()
	local info;
	local list = {};
	for k, v in pairs(SAS_Saved) do
		if ( k ~= "debug" and k ~= "BackUp" and k ~= PlrName and v.s ) then
			for j, z in pairs(v.s) do
				tinsert(list,k);
				break;
			end
		end
	end
	table.sort(list);
	if ( SAS_Saved["BackUp"] ) then
		tinsert(list,"BackUp");
	end
	for i=1, getn(list) do
		info = {};
		info.text = list[i];
		info.value = list[i];
		info.justifyH = "LEFT";
		info.func = SASSets_Character_DropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function SASSets_Character_DropDown_OnClick()
	UIDropDownMenu_SetSelectedName( SASSets_Character_DropDown, this:GetText() );
	UIDropDownMenu_Initialize( SASSets_CharacterSets_DropDown, SASSets_CharacterSets_DropDown_Initialize);
	UIDropDownMenu_SetSelectedID( SASSets_CharacterSets_DropDown, 1 );
end

function SASSets_CharacterSets_DropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, SASSets_CharacterSets_DropDown_Initialize);
	UIDropDownMenu_SetWidth(160,self);
	UIDropDownMenu_SetButtonWidth(24,self);
	UIDropDownMenu_JustifyText("LEFT",self);
	UIDropDownMenu_SetSelectedID( self, 1 );
end

function SASSets_CharacterSets_DropDown_Initialize()
	local info;
	local list = {};
	local char = SASSets_Character_DropDownText:GetText();
	if ( SAS_Saved[char] and SAS_Saved[char]["s"] ) then
		for k, v in pairs(SAS_Saved[char]["s"]) do
			tinsert(list,k);
		end
	end
	table.sort(list);
	for i=1, getn(list) do
		info = {};
		info.text = list[i];
		info.value = list[i];
		info.justifyH = "LEFT";
		info.func = SASSets_CharacterSets_DropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function SASSets_CharacterSets_DropDown_OnClick()
	UIDropDownMenu_SetSelectedID(SASSets_CharacterSets_DropDown, this:GetID() );
end

function SASActions_LoadOtherSet()
	local char = SASSets_Character_DropDownText:GetText();
	local set = SASSets_CharacterSets_DropDownText:GetText();
	SASActions_Load( set, char );
end

-------------------------------
-- SASActionButton functions --
-------------------------------
function SASActionButton_OnClick( self, button )
	-- Pick up action, and replace with held action (if there is one)
	local bar = self:GetParent():GetID();
	local id = self:GetID();
	--local i = id + bar * 12;
	local LocalSavedAction;
	if ( button == "RightButton" ) then
		if ( SASFakeDragFrame.Action ) then
			SASFakeDrag_Drop(1);
		elseif ( SAS_Temp[bar][id] == 0 ) then
			SAS_Temp[bar][id] = 1;
		elseif ( SAS_Temp[bar][id] == 1 ) then
			SAS_Temp[bar][id] = nil;
		elseif ( SAS_Temp[bar][id] ) then
			SAS_Temp[bar][id] = nil;
		else
			SAS_Temp[bar][id] = 0;
		end
		SASActions_UpdateAction( self, bar, id );
	elseif ( IsShiftKeyDown() and not IsControlKeyDown() and not SASFakeDragFrame.Action ) then
		LocalSavedAction = SAS_Temp[bar][id];
		ClearCursor();
	else
		if ( SAS_SavedPickup ) then
			-- Cursor has an item / action / macro that can be placed on the action bar
			SASDebug("SASActionButton_OnClick getting action "..SAS_ParseActionInfo(SAS_SavedPickup, 1).." from cursor");
			if ( SAS_ParseActionInfo(SAS_SavedPickup, 6) ) then
				-- Spell is passive, don't add to set
				UIErrorsFrame:AddMessage(ERR_PASSIVE_ABILITY, 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME);
			else
				if ( SAS_Temp[bar] and not SAS_Temp[bar][id] == SAS_SavedPickup ) then
					LocalSavedAction = SAS_Temp[bar][id];
				end
				SAS_Temp[bar][id] = SAS_SavedPickup;
				SASActions_UpdateAction( self, bar, id );

				if ( SAS_ReturnAction and not inCombat ) then
					PlaceAction( SAS_ReturnAction );
				elseif ( not inCombat ) then
					ClearCursor();
				end
			end
		elseif ( SASFakeDragFrame.Action ) then
			-- Cursor fake drag is holding an action
			SASDebug("SASActionButton_OnClick getting fake drag action "..SAS_ParseActionInfo(SASFakeDragFrame.Action, 1));
			if ( SAS_Temp[bar] and SAS_Temp[bar][id] ) then
				LocalSavedAction = SAS_Temp[bar][id];
			end
			SAS_Temp[bar][id] = SASFakeDrag_Drop(1)
			SASActions_UpdateAction( self, bar, id );
		elseif ( SAS_Temp[bar][id] ) then
			SASDebug("SASActionButton_OnClick putting action "..SAS_ParseActionInfo(SAS_Temp[bar][id], 1).." on fake drag");
			-- This slot already has an action, pick it up
			LocalSavedAction = SAS_Temp[bar][id];
			SAS_Temp[bar][id] = nil;
			SASActions_UpdateAction( self, bar, id );
			if ( IsControlKeyDown() and not IsShiftKeyDown() ) then
				LocalSavedAction = nil;
			end
			getglobal( self:GetName().."Delete" ):Hide();
			getglobal( self:GetName().."Copy" ):Hide();
		end
	end

	if ( LocalSavedAction ) then
		SASFakeDrag_PickupAction( LocalSavedAction );
	end
	SASActions_SaveEnable();
	SASActionButton_OnEnter(self);
end

function SASActionButton_OnMouseDown( self, button )
	if ( button == "RightButton" ) then
		local bar = self:GetParent():GetID();
		local id = self:GetID();
		if ( SAS_Temp[bar] and SAS_Temp[bar][id] and type(SAS_Temp[bar][id]) == "string" ) then
			self.mousedown = 1;
		end
	end
end

function SASActionButton_OnMouseUp(self)
	self.mousedown = nil;
end

function SASActionButton_OnDragStart(self)
	local bar = self:GetParent():GetID();
	local id = self:GetID();
	SASFakeDrag_PickupAction( SAS_Temp[bar][id] );
	if ( not IsShiftKeyDown() ) then
		SAS_Temp[bar][id] = nil;
		SASActions_UpdateAction( self, bar, id );
		SASActions_SaveEnable(self);
	end
end

function SASActionButton_OnDragStop(self)
	SASFakeDrag_Drop();
end

function SASActionButton_OnReceiveDrag(self)
	SASDebug("Drag Receive");
	SASActionButton_OnClick(self);
end

function SASActionButton_OnEnter(self)
	-- Make Tooltip to display for this button
	self:SetScript("OnUpdate", SASActionButton_OnUpdate); --this.hasfocus = 1;

	local bar = self:GetParent():GetID();
	local id = self:GetID();
	local enabled = getglobal( "SASActionBar"..bar.."Enable" ):GetChecked();

	if ( not enabled ) then
		SetDesaturation( getglobal(self:GetName().."Icon"), 0 );
		self:SetAlpha(1.0);
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot");
	end

	if ( getglobal( self:GetName().."Icon" ):IsVisible() and SAS_Temp ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		SAS_SetTooltip( self, bar, id );
	else
		GameTooltip:Hide();
	end
end

function SASActionButton_OnLeave(self)
	-- Hide the tooltip, reset desaturated on disabled bars
	local enabled = getglobal( "SASActionBar"..self:GetParent():GetID().."Enable" ):GetChecked();
	local bar = self:GetParent():GetID();
	local id = self:GetID();
	SASActions_UpdateAction( self, bar, id );
	self:SetScript("OnUpdate", nil); --this.hasfocus = nil;
	getglobal( self:GetName().."Delete" ):Hide();
	getglobal( self:GetName().."Copy" ):Hide();
	GameTooltip:Hide();
end

function SASActionButton_OnUpdate(self)
	if ( not getglobal( self:GetName().."Icon" ):IsVisible() or not SAS_Temp ) then return; end

	if ( self.mousedown or ( IsControlKeyDown() and not IsShiftKeyDown() ) ) then
		getglobal( self:GetName().."Delete" ):Show();
	else
		getglobal( self:GetName().."Delete" ):Hide();
	end
	if ( IsShiftKeyDown() and not IsControlKeyDown() ) then
		getglobal( self:GetName().."Copy" ):Show();
	else
		getglobal( self:GetName().."Copy" ):Hide();
	end
end


----------------------------
-- Options Menu Functions --
----------------------------
function SASOptions_OnShow()
	SASOptions_Update();
	SASOptionsMinimapShow:SetChecked( not SAS_Saved[PlrName]["HideMinimapButton"] );
	SASOptionsMinimapShowText:SetText( SAS_TEXT_OPTIONS_MINIMAP_SHOW );
	SASOptionsMinimapDrag:SetChecked( SAS_Saved[PlrName]["LockMinimapButton"] );
	SASOptionsMinimapDragText:SetText( SAS_TEXT_OPTIONS_MINIMAP_DRAG );
	SASOptionsMinimapPositionUndo:Disable();
	SASOptionsGeneralWarnings:SetChecked( not SAS_Saved[PlrName]["NoUIWarnings"] );
	SASOptionsGeneralWarningsText:SetText( SAS_TEXT_OPTIONS_GENERAL_WARNINGS );
	SASOptionsGeneralWarnings.tooltipText = SAS_TEXT_OPTIONS_GENERAL_WARNINGS_TOOLTIP;
	SASOptionsGeneralEmptyBars:SetChecked( not SAS_Saved[PlrName]["EmptyBars"] );
	SASOptionsGeneralEmptyBarsText:SetText( SAS_TEXT_OPTIONS_GENERAL_EMPTYBARS );
	SASOptionsGeneralEmptyBars.tooltipText = SAS_TEXT_OPTIONS_GENERAL_EMPTYBARS_TOOLTIP;
	SASOptionsGeneralEmptyButtons:SetChecked( SAS_Saved[PlrName]["NoEmptyButtons"] );
	SASOptionsGeneralEmptyButtonsText:SetText( SAS_TEXT_OPTIONS_GENERAL_EMPTYBUTTONS );
	SASOptionsGeneralEmptyButtons.tooltipText = SAS_TEXT_OPTIONS_GENERAL_EMPTYBUTTONS_TOOLTIP;
	--SASOptionsGeneralFakeItemTooltips:SetChecked( not SAS_Saved[PlrName]["HideFakeItemTooltips"] );
	--SASOptionsGeneralFakeItemTooltipsText:SetText( SAS_TEXT_OPTIONS_GENERAL_FAKEITEMTOOLTIPS );
	--SASOptionsGeneralFakeItemTooltips.tooltipText = SAS_TEXT_OPTIONS_GENERAL_FAKEITEMTOOLTIPS_TOOLTIP;
	SASOptionsGeneralAutoRestore:SetChecked( not SAS_Saved[PlrName]["AutoRestore"] );
	SASOptionsGeneralAutoRestoreText:SetText( SAS_TEXT_OPTIONS_GENERAL_AUTORESTORE );
	SASOptionsGeneralAutoRestore.tooltipText = SAS_TEXT_OPTIONS_GENERAL_AUTORESTORE_TOOLTIP;
	SASOptionsGeneralAutoRestoreWarning:SetChecked( not SAS_Saved[PlrName]["NoAutoRestoreWarnings"] );
	SASOptionsGeneralAutoRestoreWarningText:SetText( SAS_TEXT_OPTIONS_GENERAL_AUTORESTOREWARN );
	SASOptionsGeneralAutoRestoreWarning.tooltipText = SAS_TEXT_OPTIONS_GENERAL_AUTORESTOREWARN_TOOLTIP;
	SAS_POS_TEMP = SAS_POS;
	SAS_OFFSET_TEMP = SAS_OFFSET;
end

function SASOptions_General_Warnings(self)
	SAS_Saved[PlrName]["NoUIWarnings"] = not self:GetChecked();
end

function SASOptions_General_EmptyBars(self)
	SAS_Saved[PlrName]["EmptyBars"] = not self:GetChecked();
	SASActions_Display();
end

function SASOptions_General_EmptyButtons(self)
	SAS_Saved[PlrName]["NoEmptyButtons"] = self:GetChecked();
	SASActions_Display();
end

--[[
function SASOptions_General_FakeItemTooltips(self)
	SAS_Saved[PlrName]["HideFakeItemTooltips"] = not self:GetChecked();
end
]]

function SASOptions_General_AutoRestore(self)
	SAS_Saved[PlrName]["AutoRestore"] = not self:GetChecked();
end

function SASOptions_General_AutoRestoreWarnings(self)
	SAS_Saved[PlrName]["NoAutoRestoreWarnings"] = not self:GetChecked();
end

function SASOptions_Minimap_Show(self)
	SAS_Saved[PlrName]["HideMinimapButton"] = not self:GetChecked();
	if ( self:GetChecked() ) then
		SASMinimapFrame:Show();
	else
		SASMinimapFrame:Hide();
	end
end

function SASOptions_Minimap_Drag(self)
	SAS_Saved[PlrName]["LockMinimapButton"] = self:GetChecked();
end

function SASOptions_Minimap_Defaults()
	SAS_POS = SAS_POS_DEFAULT;
	SAS_OFFSET = SAS_POS_DEFAULT;
	SASMinimap_PosUpdate();
end

function SASOptions_Minimap_Undo()
	SAS_POS = SAS_POS_TEMP;
	SAS_OFFSET = SAS_OFFSET_TEMP;
	SASMinimap_PosUpdate();
	SASOptions_Update();
end

function SASOptions_Update()
	if ( SAS_POS < 0 ) then SAS_POS = SAS_POS + 360; end
	SASButtonPos:SetValue(SAS_POS);
	SASButtonOffset:SetValue(SAS_OFFSET);
end


--------------------------------------
-- Warning and Save Frame Functions --
--------------------------------------
function SAS_Warning( type, func, value, force )
	if ( SAS_Saved[PlrName]["NoUIWarnings"] and ( not force or SAS_Saved[PlrName]["NoAutoRestoreWarnings"] ) ) then
		func(value);
	else
		if ( value ) then
			SASWarningFrameText:SetText( string.gsub(getglobal("SAS_TEXT_WARNING_"..type), "%%s", value) );
		else
			SASWarningFrameText:SetText( getglobal("SAS_TEXT_WARNING_"..type ) );
		end
		SASWarningFrame.func = func;
		SASWarningFrame.value = value
		ShowUIPanel(SASWarningFrame);
	end
end

function SASWarning_Okay(self)
	SASWarningFrame.func(SASWarningFrame.value)
	SASWarningFrame.func = nil;
	SASWarningFrame.value = nil;
	HideUIPanel(self:GetParent());
end

function SASSaveMenu_Save( set )
	SASSaveMenuHelp.warned = nil
	SASSaveMenuHelp:Hide();
	SAS_SaveSet( set );
	HideUIPanel( SASSaveMenu );
end


---------------------------------
-- Minimap Button functions --
---------------------------------
function SASMinimap_OnLoad(self)
	-- Load and initialize Simple Action Sets
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	self:RegisterForDrag("LeftButton", "RightButton");

	tinsert(UISpecialFrames,"SASMain");

	SlashCmdList["SAS"] = SAS_Console;
	SLASH_SAS1 = "/sas";
end

function SASMinimap_OnEvent(self)
	if( event == "PLAYER_ENTERING_WORLD" ) then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD");
		self:RegisterEvent("ACTIONBAR_SHOWGRID");
		self:RegisterEvent("ACTIONBAR_HIDEGRID");
		self:RegisterEvent("UNIT_INVENTORY_CHANGED");
		self:RegisterEvent("BAG_UPDATE");
		self:RegisterEvent("PLAYER_LOGOUT");
		self:RegisterEvent("PLAYER_REGEN_DISABLED");
		self:RegisterEvent("PLAYER_REGEN_ENABLED");

		SASMinimap_PosUpdate();

		PlrName = UnitName("player").." - "..GetCVar("realmName");

		SASFrame.PlrName = PlrName;

		PlrClass, PlrClass = UnitClass("player");

		if ( not SAS_Saved ) then
			SAS_Saved = {};
		end
		if ( not SAS_Saved[PlrName] ) then
			SAS_Saved[PlrName] = {};
			SAS_Saved[PlrName]["s"] = {};
		end

		if ( SAS_Saved[PlrName]["sets"] ) then
			SAS_UpgradeSets();
		end

		if ( SAS_Saved[PlrName]["HideMinimapButton"] ) then
			SASMinimapFrame:Hide();
		end
		
		local currentset = SAS_GetCurrentSet();
		local liveactions = SAS_IterateActions();

		if ( SAS_Saved[PlrName]["AutoRestore"] and SAS_Saved["BackUp"] and SAS_Saved["BackUp"]["s"][PlrName] ) then
			if ( SAS_CompareSet( liveactions, SAS_Saved["BackUp"]["s"][PlrName] ) ) then
				SAS_Warning( "CHANGEDSINCELAST", SAS_RestoreBackUp, nil, 1 );
				return;
			end
		end
		if ( currentset ) then
			if ( SAS_CompareSet( liveactions, SAS_Saved[PlrName]["s"][currentset] ) ) then
				SASDebug( currentset.." does not appear to be loaded." );
				SAS_SetCurrentSet();
			else
				SASDebug( currentset.." appears to be loaded, keeping as current set." );
			end
		end
	elseif( event == "ACTIONBAR_SHOWGRID" ) then
		if ( not SAS_SwappingSet ) then
			SAS_SavedPickup = SAS_BuildCursorAction();
			--SASDebug("Valid Item on Cursor");
		end
	elseif( event == "ACTIONBAR_HIDEGRID" ) then
		if ( not SAS_SwappingSet ) then
			SAS_SavedPickup = nil;
			SAS_ReturnAction = nil;
			--SASDebug("No Valid Item on Cursor");
		end
	elseif ( event == "UNIT_INVENTORY_CHANGED" or event == "BAG_UPDATE" ) then
		if ( arg1 == "player" or tonumber(arg1) ) then
			SAS_FindMissingItems();
			SASActions_Display();
		end
	elseif ( event == "PLAYER_LOGOUT" ) then
		if ( not SAS_Saved["BackUp"] ) then
			SAS_Saved["BackUp"] = {};
			SAS_Saved["BackUp"]["s"] = {};
		end
		SAS_Saved["BackUp"]["s"][PlrName] = SAS_IterateActions();
	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		inCombat = 1;
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		inCombat = nil;
		if ( delayedSet ) then
			SAS_DoSwap(delayedSet, delayedSetName, delayedSetPlayer);
			delayedSet = nil;
			delayedSetName = nil;
			delayedSetPlayer = nil;
		end
	end
end

function SASMinimap_OnClick( self, button )
	-- Open up the main menu
	SAS_SetsDropDown:Hide();
	if ( button == "LeftButton" ) then
		if ( self:GetScript("OnUpdate") ) then
			SASMinimap_DragStop()
		else
			SASMain_Toggle();
		end
	else
		if ( self:GetScript("OnUpdate")) then
			SASMinimap_DragStop();
			SAS_POS = SAS_POS_TEMP;
			SASMinimap_PosUpdate();
		else
			SAS_SetsDropDown.point = "TOPRIGHT";
			SAS_SetsDropDown.relativePoint = "BOTTOMLEFT";
			ToggleDropDownMenu(1, nil, SAS_SetsDropDown, "SASMinimapButton", 0, 0);
		end
	end
end

-- Dragging functions for the minimap button position
function SASMinimap_DragStart( self )
	if ( not SAS_Saved[PlrName]["LockMinimapButton"] ) then
		SAS_POS_TEMP = SAS_POS;
		self:SetScript("OnUpdate", SASMinimap_DragUpdate); --SASMinimapFrame.BeingDragged = true;
	end
end
function SASMinimap_DragStop( self )
	SASMinimapButton:UnlockHighlight()
	self:SetScript("OnUpdate", nil); --SASMinimapFrame.BeingDragged = nil;
end
function SASMinimap_DragUpdate()
	-- Thanks to Gello for making this a ton shorter
	SASMinimapButton:LockHighlight();
	local curX, curY = GetCursorPosition();
	local mapX, mapY = Minimap:GetCenter();
	SAS_POS = math.deg(math.atan2( curY - mapY * Minimap:GetEffectiveScale(), mapX * Minimap:GetEffectiveScale() - curX ));
	SASMinimap_PosUpdate();
end

function SASMinimap_OnEnter( self )
	if ( SAS_SetsDropDown:IsVisible() ) then return; end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	GameTooltip:AddLine("Simple Action Sets");
	if ( SAS_Saved[PlrName]["LockMinimapButton"] ) then
		GameTooltip:AddLine(" Minimap button is locked", 0.6, 0.6, 0.6);
	elseif ( SASMinimapFrame.BeingDragged ) then
		GameTooltip:AddLine(" Right click SAS button to reset", 0.7, 0.7, 0.7);
	else
		GameTooltip:AddLine(" Drag to reposition minimap button", 0.7, 0.7, 0.7);
	end
	GameTooltip:Show();
end

function SASMinimap_PosUpdate()
	SASMinimapFrame:SetPoint("TOPLEFT","Minimap","TOPLEFT",53-((80+SAS_OFFSET)*cos(SAS_POS or 0)),((80+SAS_OFFSET)*sin(SAS_POS or 0))-55);
	SASOptions_Update();
end

function SASMinimap_SetsDropDown_Initialize()
	-- Setup the minimap dropdown menu
	local info = {};
	local hasSets;

	info.text = SAS_TEXT_DROPDOWN_TITLE;
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	UIDropDownMenu_AddButton(info);

	SAS_SetsDropDown_Initialize();
end

function SAS_GetSetList()
	local list = {};
	if ( SAS_Saved and PlrName and SAS_Saved[PlrName] and SAS_Saved[PlrName]["s"] ) then
		for k, v in pairs(SAS_Saved[PlrName]["s"]) do
			tinsert(list,k);
		end
		table.sort(list);
	end

	if ( #list > 0 ) then
		return list;
	end
end

function SAS_SetsDropDown_Initialize()

	local info = {};
	info.text = SAS_TEXT_DROPDOWN_OPEN;
	info.notCheckable = 1;
	info.func = SASMinimap_SetsDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = SAS_TEXT_DROPDOWN_SAVENEW;
	info.notCheckable = 1;
	info.func = SASMinimap_SetsDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = SAS_TEXT_DROPDOWN_SAVECURRENT;
	info.notCheckable = 1;
	if ( not SAS_GetCurrentSet() ) then
		info.disabled = 1;
	end
	info.func = SASMinimap_SetsDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = SAS_TEXT_DROPDOWN_SETS;
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	UIDropDownMenu_AddButton(info);

	local list = SAS_GetSetList();
	if ( list ) then
		for k, v in ipairs(list) do
			info = { };
			info.text = v;
			info.isTitle = nil;
			if ( SAS_GetCurrentSet() == v ) then
				info.checked = 1;
			end
			info.func = SASMinimap_SetsDropDown_OnClick;
			UIDropDownMenu_AddButton(info);
		end
	else
		info = { };
		info.text = SAS_TEXT_DROPDOWN_NONE;
		info.disabled = 1;
		UIDropDownMenu_AddButton(info);
	end
end

function SASMinimap_SetsDropDown_OnClick()
	-- minimap dropdown menu handler
	local id = this:GetID();
	if ( id == 2 ) then
		ShowUIPanel(SASMain);
	elseif ( id == 3 ) then
		SASActions_SaveNew();
	elseif ( id == 4 ) then
		SAS_Warning("SAVE", SAS_SaveSet, SAS_GetCurrentSet());
	elseif ( id > 5 ) then
		SASDebug( this:GetText() );
		SAS_SwapSet( this:GetText() );
	end
end

function SASMinimap_SetsDropDown_OnLoad( self )
	UIDropDownMenu_Initialize(self, SASMinimap_SetsDropDown_Initialize, "MENU");
end


-------------------------
-- Fake Drag functions --
-------------------------
function SASFakeDrag_Drop(clear)
	-- Pick up sas item
	SASFakeDragFrame:Hide();
	local focus = GetMouseFocus();
	local action = SASFakeDragFrame.Action;
	local bar = SASFakeDragFrame.Bar;
	if ( focus and not (focus.IsSASAction or focus.IsSASBar) or clear ) then
		if ( SASFakeDragFrame.Action ) then
			PlaySoundFile("Sound\\Interface\\uSpellIconDrop.wav");
			SASDebug("Dumping FakeDrag Action "..action);
		elseif ( SASFakeDragFrame.Bar ) then
			PlaySoundFile("Sound\\Interface\\uSpellIconDrop.wav");
			SASDebug("Dumping FakeDrag Bar");
		else
			--SASDebug("Dumping FakeDrag Action, no action");
		end
		SASFakeDragFrame.Action = nil;
		SASFakeDragFrame.Bar = nil;
		SASFakeDragFrame:SetScript("OnUpdate", nil);
		if ( SAS_DraggingBar ) then
			if ( SASActions:IsVisible() ) then
				SASActions_UpdateBar(SAS_DraggingBar);
			else
				SAS_DraggingBar = nil;
			end
		end
	end
	return action or bar;
end

function SASFakeDrag_PickupAction(action)
	SASFakeDragFrame.Action = action;
	SASFakeDragFrame.Bar = nil;
	if ( action ) then
		local name, texture = SAS_ParseActionInfo( action );
		for i=1, 12 do
			getglobal( "SASFakeDragFrameIcon"..i ):SetTexture();
		end
		SASDebug("FakeDrag Pickup Action "..name);
		SASFakeDragFrame:Show();
		SASFakeDragFrameIcon:SetTexture( SAS_FullPath(texture) );
		SASFakeDragFrameIcon:SetAlpha( 0.5 );
		PlaySoundFile("Sound\\Interface\\uSpellIconPickup.wav");
		SASFakeDragFrame:SetScript("OnUpdate", SASFakeDrag_OnUpdate);
	else
		SASFakeDragFrame:Hide();
		SASFakeDragFrame:SetScript("OnUpdate", nil);
	end
end

function SASFakeDrag_PickupBar(bar)
	SASFakeDragFrame.Bar = SAS_CopyTable(bar);
	SASFakeDragFrame.Action = nil;
	if ( bar ) then
		SASFakeDragFrameIcon:SetTexture();
		for i=1, 12 do
			local icon = getglobal( "SASFakeDragFrameIcon"..i );
			if ( bar[i] ) then
				local texture = SAS_ParseActionInfo( bar[i], 2 );
				icon:SetTexture( SAS_FullPath(texture) );
				icon:SetTexCoord( 0, 1, 0, 1 );
			else
				icon:SetTexture("Interface\\Buttons\\UI-Quickslot");
				icon:SetTexCoord( 0.1875, 0.8125, 0.1875, 0.8125 );
			end
			icon:SetAlpha( 0.5 );
			SASFakeDragFrame:Show();
			SASFakeDragFrame:SetScript("OnUpdate", SASFakeDrag_OnUpdate);
		end
		PlaySoundFile("Sound\\Interface\\uSpellIconPickup.wav");
	else
		SASFakeDragFrame:Hide();
		SASFakeDragFrame:SetScript("OnUpdate", nil);
	end
end

function SASFakeDrag_OnUpdate(self)
	-- Update the position of the FakeDrag frame to under the cursor
	if ( (self.Action or self.Bar) and self:IsVisible() ) then
		if ( SASActions:IsVisible() ) then
			local curX, curY = GetCursorPosition();
			local scale = UIParent:GetScale();
			self:SetPoint("CENTER", "UIParent", "BOTTOMLEFT", curX/scale, curY/scale );
		else
			SASFakeDrag_Drop(1);
			self:SetScript("OnUpdate", nil);
		end
	else
		self:SetScript("OnUpdate", nil);
	end
end


-------------------------
-- Titan Panel Support --
-------------------------
function TitanPanelSASButton_OnLoad(self)
	self.registry = {
		id = SAS_TITAN_ID,
		menuText = "Simple Action Sets",
		buttonTextFunction = "TitanPanelSASButton_GetButtonText",
		tooltipTitle = SAS_TITLE,
		tooltipTextFunction = "TitanPanelSASButton_GetTooltipText",
		icon = "Interface\\AddOns\\SimpleActionSets\\sas",
		iconWidth = 16,
		savedVariables = {
			ShowLabelText = 1,  -- Default to 1
			ShowIcon = 1;
			ShowColoredText = 1,
		}
	};
end

function TitanPanelSASButton_GetButtonText(id)
	-- If id not nil, return corresponding plugin button
	-- Otherwise return this button and derive the real id
	local button, id = TitanUtils_GetButton(id, true);

	if ( SAS_GetCurrentSet() ) then
		if ( TitanGetVar(SAS_TITAN_ID, "ShowColoredText") ) then
			return SAS_TITAN_LABEL, TitanUtils_GetGreenText( SAS_GetCurrentSet() );
		else
			return SAS_TITAN_LABEL, TitanUtils_GetHighlightText( SAS_GetCurrentSet() );
		end
	else
		return SAS_TITAN_LABEL, TitanUtils_GetHighlightText( SAS_TITAN_NA );
	end
end

function TitanPanelSASButton_GetTooltipText()
	return TitanUtils_GetGreenText(SAS_TITAN_HINT);
end

function TitanPanelSAS_OnClick(button)
	if ( button == "LeftButton" ) then
		SASMain_Toggle();
	end
end

function TitanPanelRightClickMenu_PrepareSASMenu()
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[SAS_TITAN_ID].menuText);

	SAS_SetsDropDown_Initialize();

	TitanPanelRightClickMenu_AddSpacer();
	TitanPanelRightClickMenu_AddToggleIcon(SAS_TITAN_ID);
	TitanPanelRightClickMenu_AddToggleLabelText(SAS_TITAN_ID);
	TitanPanelRightClickMenu_AddToggleColoredText(SAS_TITAN_ID);

	TitanPanelRightClickMenu_AddSpacer();
	TitanPanelRightClickMenu_AddCommand(TITAN_PANEL_MENU_HIDE, SAS_TITAN_ID, TITAN_PANEL_MENU_FUNC_HIDE);
end

function TitanPanelSAS_Update()
	if ( TitanPanelSASButton and TitanPanelButton_UpdateButton ) then
		TitanPanelButton_UpdateButton(SAS_TITAN_ID);
	end
end


------------------------
-- Reusable functions --
------------------------

function SASPrint(msg)
	-- Basic print function
	if ( not msg ) then
		msg = "|wnil";
	end
	msg = string.gsub( msg, "%|w", "|cffff0000" );
	msg = string.gsub( msg, "%|i", "|cffe6e6fA" );
	DEFAULT_CHAT_FRAME:AddMessage( "<|cff40E0D0SAS|r> "..msg, 0.012, 0.658, 0.62 );
	--local cols = "|cff03A98E";
end

function SASDebug(msg)
	-- Print when debug is turned on
	if ( SAS_Saved["debug"] ) then SASPrint("<|wDEBUG|r> "..msg); end
end

function SASTooltipAddLine(msg)
	-- Adds a colored line to the tooltip
	GameTooltip:AddLine( msg, 0.012, 0.658, 0.62, 1, 1 );
	GameTooltip:Show();
end

function SAS_BuildActionInfo2(...) -- name, texture, rank, link, macro, ?
	local name, texture, rank, link, macro = ...;
	if ( not name ) then
		return;
	end
	if ( texture ) then texture = tPath(texture); end
	if ( rank ) then rank = tRank(rank); end
	if ( link ) then link = tLink(link); end
	return name.."�"..(texture or "").."�"..(rank or "").."�"..(link or "").."�"..(macro or "");
end

function SAS_BuildActionInfo(...) -- name, texture, rank, link, macro, ?
	local temp, string, i = "";
	for i=1, select("#",...) do
		local val = select(i,...);
		if ( val ) then
			string = (string or "")..temp..(val or "").."�";
			temp = "";
		else
			temp = temp .. "�";
		end
	end
	return string;
end

function SAS_IncActionInfo( action, val, part )
	if ( not val ) then return;
	elseif ( not part ) then part = 1; end
	local a = {SAS_ParseActionInfo(action)};
	a[part] = val;

	return SAS_BuildActionInfo( a[1], a[2], a[3], a[4], a[5], a[6] );
end

function SAS_ParseActionInfo( action, ... )
	if not action then return; end
	if type(action)~="string" then return action; end
	local a = {strsplit("�",action)};
	for k, v in pairs(a) do if v == "" then a[k] = nil; end end
	if ( select("#",...) > 0 ) then
		local b = {};
		for i=1, select("#",...) do
			tinsert( b, a[select(i,...)] );
		end
		return unpack(b);
	else
		if a[3] ~= "MOUNT" and a[3] ~= "CRITTER" then
			a[3] = tonumber(a[3])
		end
		return a[1], a[2], a[3], a[4], tonumber(a[5]), a[6]; --name, texture, rank, link, macro, ?;
	end
end

function SAS_ItemLink( item )
	-- Return an item's link
	local itemLink = SAS_FindItem( item );
	if ( itemLink ) then
		return SAS_FindLink( itemLink );
	end
end
function SAS_FindLink( item )
	-- Find an item's link number from it's item link
	return string.match( item, "item:(%d+):" );
end

function SAS_ItemName( item )
	-- Return an item's name
	local itemName = SAS_FindItem( item );
	if ( itemName ) then
		return SAS_FindName( itemName );
	end
end
function SAS_FindName( item )
	-- Find an item's name from it's item link
	if ( item ) then
		for name in string.gmatch( item, "%[(.+)%]") do
			return name;
		end
	end
end

function SAS_FindItem( item )
	-- Iterate over items the player has and return it's link and location --
	if ( not item ) then return; end

	item = tostring(item);

	-- Iterate over bags
	for i=0, 4 do
		local bagSlots = GetContainerNumSlots(i);
		if ( bagSlots ) then
			for j=1, bagSlots do
				--SASDebug("Doing GetContainerItemLink() on "..i.." "..j);
				local itemLink = GetContainerItemLink(i,j);
				if ( itemLink ) then
					if ( item == SAS_FindLink( itemLink ) or item == SAS_FindName( itemLink ) ) then
						return itemLink, i, j;
					end
				end
			end
		end
	end

	-- Iterate over paper doll
	for i=0, 23 do
		--SASDebug("Doing GetInventoryItemLink() on "..i);
		local itemLink = GetInventoryItemLink("player",i);
		if ( itemLink ) then
			if ( itemLink ) then
				if ( item == SAS_FindLink( itemLink ) or item == SAS_FindName( itemLink ) ) then
					return itemLink, nil, nil, i;
				end
			end
		end
	end
end

function SAS_FindSpell( spell, rank )
	if ( not spell ) then return; end
	-- Iterate over spells the player has and return location
	local i, name, texture, highest = 1;
	local spellName, spellRank = GetSpellName( i, BOOKTYPE_SPELL );
	while spellName do
		if ( spellName == spell ) then
			highest = i;
			if ( rank ) then
				if ( tRank(spellRank) == tonumber(rank) ) then
					return i;
				end
			else
				return i;
			end
		end
		i = i+1;
		spellName, spellRank = GetSpellName( i, BOOKTYPE_SPELL );
	end
	return nil, highest;
end

-- saved as globals in the macro blizz addon
-- MAX_ACCOUNT_MACROS = 36;
-- MAX_CHARACTER_MACROS = 18;

function SAS_FindMacro( name, texture, macro )
	-- Check saved macro id
	local macroName, macroTexture, bestguess;
	if ( macro ) then
		macroName, macroTexture = GetMacroInfo(macro);
		if ( macroName == name ) then
			if ( texture and macroTexture == texture ) then
				return macro;
			end
			bestguess = macro;
		end
	end

	-- If no direct match, iterate over macros and return matching index
	local numAccountMacros, numCharacterMacros = GetNumMacros();
	numCharacterMacros = numCharacterMacros + 36;
	for i=1, 36+18 do
		if ( i > numAccountMacros and i < 37 ) then
			-- no more global macros, skip to local
			i = 37;
		end
		if ( i > numCharacterMacros ) then
			-- no more macros
			break;
		end
		macroName, macroTexture = GetMacroInfo(i)
		if ( macroName and macroName == name ) then
			if ( texture and macroTexture == texture ) then
				return i;
			end
			bestguess = i;
		end
	end

	return bestguess;
end

function SAS_FindCompanion( name, companionType )
	local i, companionId, companionName, spellId;
	for i=1, GetNumCompanions(companionType) do
		companionId, companionName, spellId = GetCompanionInfo(companionType, i);
		if name == companionName then
			return companionId, spellId;
		end
	end
end

function SAS_GetActionInfo( id )
	local actionType, typeId, subType = GetActionInfo(id);
	if ( actionType == "spell" and typeId > 0 ) then
		local name, rank = GetSpellName(typeId,subType);
		return name, tPath(GetSpellTexture(typeId,subType)), tRank(rank);
	elseif ( actionType == "item" ) then
		local texture = tPath(GetActionTexture(id));
		return (GetItemInfo(typeId)), texture, nil, typeId;
	elseif ( actionType == "macro" ) then
		local name, texture = GetMacroInfo(typeId);
		if ( not texture ) then
			texture = tPath(GetActionTexture(id));
		else
			texture = tPath(texture);
		end
		return name, texture, nil, nil, typeId;
	elseif ( actionType == "companion" ) then
		local npcid, name, spellid, texture = GetCompanionInfo( subType, typeId );
		return name, tPath(texture), subType; -- treat companions as spells for now
	end
end

function SAS_IterateActions()
	-- Iterate over all current actions
	local actionlist = {};
	for i=0, 9 do
		actionlist[i] = {};
		for j=1, 12 do
			actionlist[i][j] = SAS_BuildActionInfo( SAS_GetActionInfo( j+(i*12) ) ); --action[1], action[2], action[3], action[4], action[5] );
		end
	end

	return actionlist;
end

function SAS_SetTooltip( self, bar, id )
	-- Sets the Tooltip for the found action
	if ( not bar or not id ) then return; end

	if ( SAS_Temp[bar][id] ) then
		if ( SAS_Temp[bar][id] == 0 ) then
			GameTooltip:SetText( SAS_TEXT_TOOLTIP_FORCECLEAR, 1, 1, 1 );
			SASTooltipAddLine( SAS_TEXT_TOOLTIP_FORCECLEAR_TIP );
			GameTooltip:Show();
		elseif ( SAS_Temp[bar][id] == 1 ) then
			GameTooltip:SetText( SAS_TEXT_TOOLTIP_FORCENOAPPLY, 1, 1, 1 );
			SASTooltipAddLine( SAS_TEXT_TOOLTIP_FORCENOAPPLY_TIP );
			GameTooltip:Show();
		else
			local name, texture, rank, link, macro = SAS_ParseActionInfo( SAS_Temp[bar][id] );
			texture = SAS_FullPath(texture);
			local TooltipReturn;
			-- is a macro
			if ( macro ) then
				TooltipReturn = GameTooltip:SetText( name, 1, 1, 1 );
				local macroName,macroTexture,macroText = GetMacroInfo( SAS_FindMacro(name, texture, macro) );
				if ( macroText ) then
					GameTooltip:AddLine( macroText, 0.75, 0.75, 0.75, 1, 1 );
					GameTooltip:Show();
				else
					SASTooltipAddLine( SAS_TEXT_TOOLTIP_NOMACRO );
				end
			-- is an item
			elseif ( link ) then
				local itemLink;
				SASDebug("SAS_SetTooltip - link = "..link);
				if ( link == "?" or link == "1" ) then
					itemLink = SAS_FindItem( name );
					if ( itemLink ) then
						link = SAS_FindLink(itemLink);
					else
						link = nil;
					end
				else
					itemLink = SAS_FindItem( link );
				end
				if ( link and select(2,GetItemInfo(link)) ) then
					TooltipReturn = GameTooltip:SetHyperlink(select(2,GetItemInfo(link)));
					if ( not itemLink ) then
						SASTooltipAddLine( SAS_TEXT_TOOLTIP_NOTHAVE );
					end
				else
					TooltipReturn = GameTooltip:SetText( name, 1, 1, 1 );
					SASTooltipAddLine( SAS_TEXT_TOOLTIP_NOTVALID );
				end
			-- is a companion
			elseif ( rank == "MOUNT" or rank == "CRITTER" ) then
				local companionid, spellid = SAS_FindCompanion( name, rank );
				if ( companionid ) then
					TooltipReturn = GameTooltip:SetHyperlink("spell:"..spellid);
				else
					GameTooltip:SetText( name, 1, 1, 1 );
					SASTooltipAddLine( SAS_TEXT_TOOLTIP_NOCOMPANION );
				end
			-- is a spell
			else
				local spellNum, highest = SAS_FindSpell( name, rank );
				if ( spellNum ) then
					TooltipReturn = GameTooltip:SetSpell( spellNum, BOOKTYPE_SPELL );
					if ( rank ) then
						local spellName, spellRank = GetSpellName( spellNum, BOOKTYPE_SPELL );
						GameTooltipTextRight1:SetText( spellRank );
						GameTooltipTextRight1:SetTextColor( 0.5, 0.5, 0.5 );
						GameTooltipTextRight1:Show();
						GameTooltip:Show();
					end
				elseif ( highest ) then
					local spellName, spellRank = GetSpellName( highest, BOOKTYPE_SPELL );
					local string = string.gsub( SAS_TEXT_TOOLTIP_NOSPELLRANK, "%%r", rank );
					TooltipReturn = GameTooltip:SetSpell( highest, BOOKTYPE_SPELL );
					if ( spellRank ) then
						GameTooltipTextRight1:SetText( spellRank );
						GameTooltipTextRight1:SetTextColor( 0.5, 0.5, 0.5 );
						GameTooltipTextRight1:Show();
						GameTooltip:Show();
					end
					SASTooltipAddLine( string );
				else
					TooltipReturn = GameTooltip:SetText( name, 1, 1, 1 );
					if ( rank ) then
						GameTooltipTextRight1:SetText( RANK.." "..rank );
						GameTooltipTextRight1:SetTextColor( 0.5, 0.5, 0.5 );
						GameTooltipTextRight1:Show();
						GameTooltip:Show();
					end
					SASTooltipAddLine( SAS_TEXT_TOOLTIP_NOSPELL );
				end
			end
		end
		if ( TooltipReturn ) then
			self.updateTooltip = TOOLTIP_UPDATE_TIME;
		else
			self.updateTooltip = nil;
		end
	end
end

function SAS_BarHasActions(bar, set)
	if ( not set ) then
		set = SAS_Temp;
	end
	if ( bar and set[bar] ) then
		for i=1, 12 do
			if ( set[bar][i] ) then
				return 1;
			end
		end
	end
end

function SAS_ClearSlot(id)
	-- Clear an action slot
	if ( HasAction(id) and not SAS_Saved[PlrName]["NoEmptyButtons"] ) then
		PickupAction(id);
		ClearCursor();
	end
end

function SAS_MissingItem( id, itemInfo )
	-- Add to list of items to place on the bar when available.
	if ( id and itemInfo ) then
		if ( not SAS_Saved[PlrName]["MissingItems"] ) then
			SAS_Saved[PlrName]["MissingItems"] = {};
		end
		local missing = SAS_Saved[PlrName]["MissingItems"]
		if ( not missing[id] or SAS_ParseActionInfo(missing[id], 3) ~= itemInfo[3] ) then
			SAS_Saved[PlrName]["MissingItems"][id] = SAS_BuildActionInfo(itemInfo[1], itemInfo[2], nil, itemInfo[3], nil, nil, itemInfo[4]);
			if ( HasAction( id ) ) then
				PickupAction( id );
				ClearCursor();
			end
			SASDebug( itemInfo[1] );
		end
	end
end

function SAS_ForceUpdate( id )
	if ( id and not HasAction( id ) ) then
		SASDebug( "force update on "..id );
		i = 1;
		--if ( not SAS_original_HasAction( id ) ) then
			local passive = IsPassiveSpell( i, BOOKTYPE_SPELL );
			while passive do
				i = i + 1;
				passive = IsPassiveSpell( i, BOOKTYPE_SPELL );
			end
			PickupSpell( i, BOOKTYPE_SPELL );
			PickupAction( id );
		--end
		PickupAction( id );
		ClearCursor();
	end
end

function SAS_FindMissingItems()
	-- Readd missing items to action bar
	if ( not SAS_Saved[PlrName]["MissingItems"] ) then return; end
	for id, itemInfo in pairs(SAS_Saved[PlrName]["MissingItems"]) do
		SAS_PlaceItem( id, SAS_ParseActionInfo( itemInfo, 4, 1, 6 ) );
	end
end

function SAS_GetMissingItemInfo( id )
	if ( id ) then
		if ( SAS_Saved and PlrName ) then
			if ( SAS_Saved[PlrName]["MissingItems"] and SAS_Saved[PlrName]["MissingItems"][id] ) then
				return SAS_Saved[PlrName]["MissingItems"][id];
			end
		end
	end
end

function SAS_CheckItemDBs( name )
	-- check if there are any item db mods, get item link from that
	if ( ItemLinks ) then
		if ( ItemLinks[name] and ItemLinks[name]["i"] ) then
			SASDebug( "found "..name.." in LootLink db" );
			return tLink(ItemLinks[name]["i"]);
		end
	elseif ( IMDB ) then
		local realm = GetCVar("realmName");
		if ( IMDB[realm] and IMDB[realm][name] ) then
			for itemLink in string.gmatch( IMDB[realm][name], "item(%d:%d:%d:%d)" ) do
				SASDebug( "found "..name.." in ItemSync db" );
				return tLink(itemLink);
			end
		elseif ( IMDB[name] ) then
			for itemLink in string.gmatch( IMDB[name], "item(%d:%d:%d:%d)" ) do
				SASDebug( "found "..name.." in ItemSync db" );
				return tLink(itemLink);
			end
		end
	end

	SASDebug( "could not find "..name.." in either item dbs." );

	return "?";
end

function SAS_PlaceItem( id, link, name, set )
	-- Place an item, update set link id if found
	local itemLink, bag, slot, inv;
	if ( link == "?" or link == "1" ) then
		itemLink, bag, slot, inv = SAS_CheckItem( name, id, set );
	else
		itemLink, bag, slot, inv = SAS_FindItem( link );
	end
	if ( bag ) then
		PickupContainerItem( bag, slot );
		PlaceAction(id);
		return 1;
	elseif ( inv ) then
		PickupInventoryItem( inv );
		PlaceAction(id);
		return 1;
	end
end

function SAS_CheckItem( name, id, set )
	if ( name ) then
		itemLink, bag, slot, inv = SAS_FindItem( name );
		itemLink = SAS_FindLink(itemLink)
		if ( not itemLink ) then
			itemLink = SAS_CheckItemDBs( name );
		end
		if ( itemLink and itemLink ~= "?" and itemLink ~= "1" ) then
			local slot = math.mod( id, 12 );
			local bar = (id-slot) / 12;
			if ( SAS_Saved[PlrName]["s"][set] ) then
				local action = SAS_Saved[PlrName]["s"][set][bar][slot];
				local iname, ilink = SAS_ParseActionInfo(action, 1, 4);
				if ( iname ) then
					if ( iname == name and ilink and ilink == "?" ) then
						SASDebug( "Updating item in action #"..id.." in set "..set.." with itemLink." );
						SAS_Saved[PlrName]["s"][set][bar][slot] = SAS_IncActionInfo(action, itemLink, 4);
					else
						SASDebug( "|wAttempted to update itemLink in action #"..id.." but names are wrong?" );
					end
				end
			end
		end
	end
	return itemLink, bag, slot, inv;
end

function SAS_SwapSet( set, player )
	if ( not player ) then
		SASDebug( "SAS_SwapSet - No player name specified, using "..PlrName );
		player = PlrName;
	end

	local actions;
	if ( set ) then
		SASDebug(" SAS_SwapSet - about to do copy table on SAS_Saved["..player.."][sets]["..set.."]" );
		actions = SAS_CopyTable( SAS_Saved[player]["s"][set] );
	elseif ( SASMain:IsVisible() ) then
		SASDebug(" SAS_SwapSet - about to do copy table on SAS_Temp" );
		actions = SAS_CopyTable( SAS_Temp );
	else
		return;
	end

	if ( not actions ) then
		SASDebug("|wNo actions to change to.");
		return;
	end

	if ( not inCombat ) then
		SAS_DoSwap(actions, set, player);
	else
		SASDebug("In combat, copying set delayed set");
		if ( not delayedSet ) then
			delayedSet = {};
			delayedSetPlayer = player;
			delayedSetName = set;
		end
		for i = 0, 9 do
			local bar;
			if ( SAS_BarEnabled(i,actions) and not ( not SAS_BarHasActions(i, actions) and not SAS_Saved[PlrName]["EmptyBars"] ) ) then
				bar = {};
				for j = 1, 12 do
					if ( actions[i][j] ) then
						bar[j] = actions[i][j];
					elseif ( not SAS_Saved[PlrName]["NoEmptyButtons"] ) then
						bar[j] = nil;
					end
				end
			end
			if ( bar ) then
				delayedSet[i] = bar;
			end
		end
	end
end

function SAS_DoSwap(actions, set, player)
	-- Swaps a saved set to the player's real action bars.
	SAS_SwappingSet = true;
	if ( not player or player == PlrName ) then
		SAS_SetCurrentSet( set );
	end
	ClearCursor();
	for i = 0, 9 do
		if ( SAS_BarEnabled(i,actions) and not ( not SAS_BarHasActions(i, actions) and not SAS_Saved[PlrName]["EmptyBars"] ) ) then
			SASDebug("Bar "..(i+1).." is enabled");
			for j = 1, 12 do
				local id = j + i*12;
				local msg = "Action "..id;
				if ( actions[i][j]  ) then
					if ( actions[i][j] == 0 ) then
						msg = msg.." forced cleared.";
						SAS_ClearSlot(id);
					elseif ( actions[i][j] == 1 ) then
						msg = msg.." forced no change.";
					else
						local ename, etexture, erank, elink, emacro = SAS_GetActionInfo(id);
						local name, texture, rank, link, macro = SAS_ParseActionInfo( actions[i][j] ); --actions[i][j][1], actions[i][j][2], actions[i][j][3], actions[i][j][4], actions[i][j][5];
						if ( (name == ename and (( rank == erank ) or ( macro and emacro ) or ( link and elink ))) ) then
							msg = msg.." is the same as the one trying to be swapped.";
						else
							if ( macro ) then
								msg = msg.." is a macro.";
								local macroID = SAS_FindMacro( name, texture, macro )
								if ( macroID ) then
									PickupMacro( macroID );
									PlaceAction(id);
								else
									msg = msg.." |wCouldn't find macro."
									SAS_ClearSlot(id);
								end
							elseif ( link ) then
								msg = msg.." is an item.";
								if ( not SAS_PlaceItem( id, link, name, set ) ) then
									msg = msg.." |wCouldn't find item."
									SAS_MissingItem( id, {name, texture, link, set} );
								end
							elseif ( rank == "MOUNT" or rank == "CRITTER" ) then
								msg = msg.." is a companion.";
								local companionId = SAS_FindCompanion( name, rank );
								if ( companionId ) then
									PickupCompanion( rank, companionId );
									PlaceAction(id);
								else
									msg = msg.." |wCouldn't find companion."
									SAS_ClearSlot(id);
								end
							elseif ( name ) then
								msg = msg.." is a spell.";
								local spellNum, highest = SAS_FindSpell( name, rank );
								if ( spellNum ) then
									PickupSpell( spellNum, BOOKTYPE_SPELL );
									PlaceAction(id);
								elseif ( highest ) then
									local spellName, spellRank = GetSpellName( highest, BOOKTYPE_SPELL );
									if ( rank ~= spellRank ) then
										msg = msg.." Can't find rank, using highest found instead.";
										PickupSpell( highest, BOOKTYPE_SPELL );
										PlaceAction(id);
									else
										msg = msg.." Action is highest rank found, won't swap.";
									end
								else
									msg = msg.." |wCoulnd't find spell."
									SAS_ClearSlot(id);
								end
							else
								msg = msg.." is has no name, link, macro?";
							end
						end

						ClearCursor();
					end
				elseif ( not SAS_Saved[PlrName]["NoEmptyButtons"] ) then
					msg = msg.." is empty.";
					SAS_ClearSlot(id);
				end
				SASDebug(msg);
			end
		elseif ( not SAS_BarEnabled(i,actions) ) then
			SASDebug("Bar "..(i+1).." not enabled, skipping");
		else
			SASDebug("Bar "..(i+1).." has no actions, skipping");
		end
	end
	ClearCursor();

	SAS_SwappingSet = nil;
end

function SAS_CopyTable(copyTable)
	-- properly copies a table instead of referencing the same table, thanks Sallust.
	if ( not copyTable ) then return; end
	local returnTable = {};
	for k, v in pairs(copyTable) do
		if type(v) == "table" then
			returnTable[k] = SAS_CopyTable(v);
		else
			returnTable[k] = v;
		end
	end
	return returnTable;
end

function SAS_SetExists( set )
	-- Check to see if the set already exists
	if SAS_Saved[PlrName]["s"][set] then
		return true;
	end
end

function SAS_SaveSet(set)
	-- Save a set
	if ( not set ) then
		if ( SAS_GetCurrentSet() ) then
			set = SAS_GetCurrentSet();
		else
			return;
		end
	else
		SAS_SetCurrentSet(set);
	end
	local actions;
	if ( SASMain:IsVisible() and SAS_Temp ) then
		actions = SAS_CopyTable(SAS_Temp);
	else
		actions = SAS_IterateActions();
	end
	SASPrint(SAS_TEXT_SAVING..set);
	SAS_Saved[PlrName]["s"][set] = SAS_CopyTable(actions);
	SASActions_Load( set );
end

function SAS_Delete(set)
	-- Delete a set
	SASDebug(SAS_TEXT_DELETING..set);
	SAS_Saved[PlrName]["s"][set] = nil;
	if ( SAS_GetCurrentSet() == set ) then
		SAS_SetCurrentSet();
	end
	SASActions_Load();
end

function SAS_SetCurrentSet( set )
	SASDebug("Changing current set to " .. (set or "nil"));
	SAS_Saved[PlrName]["CurrentSet"] = set;
	if ( SASFu ) then
		SASFu:UpdateText();
	end
	TitanPanelSAS_Update();
end

function SAS_GetCurrentSet()
	if ( SAS_Saved and PlrName ) then
		return SAS_Saved[PlrName]["CurrentSet"];
	end
end

function SASBackUp()
	SAS_BackUp = SAS_IterateActions();
end

function SAS_RestoreBackUp()
	SAS_SwapSet( PlrName, "BackUp" );
end

function SAS_Console( msg )
	if ( strlower(string.sub( msg, 1, 4 )) == "swap" ) then
		local set = string.sub( msg, 6 );
		if ( set and SAS_SetExists( set ) ) then
			SAS_SwapSet( set );
		else
			SASPrint( string.gsub(SAS_TEXT_CONSOLE_NOVALID, "%%s", set) );
		end
	elseif ( strlower(string.sub( msg, 1, 4 )) == "save" ) then
		local set = string.sub( msg, 6 );
		if ( set ) then
			if ( SAS_SetExists( set ) ) then
			else
				SAS_SaveSet( set );
			end
		end
	elseif ( strlower(string.sub( msg, 1, 5 )) == "debug" ) then
		SAS_Saved["debug"] = not SAS_Saved["debug"];
	elseif ( strlower(string.sub( msg, 1, 4 )) == "show" or msg == "" ) then
		SASMain_Toggle();
	else
		SASPrint( SAS_TEXT_CONSOLE_HELP );
	end
end
function tPath( texture )
	-- truncate icon's file path
	if ( texture ) then
		return string.gsub( texture, IconPath, "" );
	end
end

function SAS_FullPath( texture )
	-- add icon's file path back in
	if ( texture ) then return IconPath..texture; end
end

function tRank( rank )
	-- truncate ranks to just numerical data
	if ( rank ) then
		for i in string.gmatch( rank, "%d+" ) do return tonumber(i); end
	end
end

function tLink( itemLink )
	-- truncate item links to item ids
	if ( not itemLink ) then return; end
	for num in string.gmatch( itemLink, "m:(%d+)" ) do return num; end
	return itemLink;
end

function SAS_TableNil(a)
	if a then
		for k, v in pairs(a) do
			return a;
		end
	end
end

local function actionComp( a, b )
	if a and b then
		local A = { SAS_ParseActionInfo( a ) };
		local B = { SAS_ParseActionInfo( b ) };
		for k, v in pairs(A) do
			if ( k ~= 4 and (not B[k] or v ~= B[k]) ) then
				SASDebug( k.." "..v.." does not == "..B[k] );
				return 1;
			end
		end
	else
		if ( a ) then
			SASDebug( "no b" );
		elseif ( b ) then
			SASDebug( "no a" );
		else
			SASDebug( "no a or b" );
		end
		return 1;
	end
end

function SAS_CompareSet( set1, set2, strict )
	-- Compare two sets to see if they're similar
	if ( not set1 or not set2 ) then
		if ( not set1 ) then
			SASDebug( "no set1" );
		elseif ( not set2 ) then
			SASDebug( "no set2" );
		else
			SASDebug( "no set1 or set2" );
		end
		return 1;
	end

	for i=0, 9 do
		if ( set1[i] ) then
			if ( strict == 2 ) then
				if ( set1[i][0] ~= set2[i][0] ) then
					return 1;
				end
			end
			for j=1, 12 do
				if ( set1[i][j] ) then
					if ( actionComp( set1[i][j], set2[i][j] ) ) then
						SASDebug( "returning at "..i.." "..j );
						return 1;
					end
				elseif ( strict and set2[i][j] ) then
					SASDebug( "strict returning at "..i.." "..j.." no set1 but set2" );
					return 1;
				end
			end
		elseif ( strict and set2[i] ) then
			SASDebug( "strict returning at "..i.." no set1 but set2" );
			return 1;
		end
	end
end

function SAS_UpgradeSets()
	-- Move action set data from 0.373 and prior versions to 0.4+
	for p, v in pairs(SAS_Saved) do
		if ( v["sets"] ) then
			SASPrint( "Doing upgrade on "..p.."'s sets" );
			v["s"] = {};
			for s, k in pairs(v["sets"]) do
				v["s"][s] = {};
				for i=0, 9 do
					v["s"][s][i] = {};
					if ( not k[i]["enable"] ) then
						v["s"][s][i] = {[0] = 1};
					end
					for j=1, 12 do
						local a = SAS_TableNil(SAS_CopyTable(k[i][j]));
						if ( a ) then
							v["s"][s][i][j] = SAS_BuildActionInfo(a[1],a[5],a[2],a[4],a[3]);
						end
					end
				end
			end
			v["sets"] = nil; -- delete old set data!!
		end
	end
end

function SAS_SetReturnSlot(slot,blah)
	SASDebug(slot.." "..blah);
	SAS_ReturnAction = slot;
	if ( SAS_GetMissingItemInfo( slot ) ) then
		SAS_Saved[PlrName]["MissingItems"][slot] = nil;
	end
end
hooksecurefunc("PickupAction", function(slot) SAS_SetReturnSlot(slot,1) end);
hooksecurefunc("PlaceAction", function(slot) SAS_SetReturnSlot(slot,2) end);
hooksecurefunc("UseAction", function(slot) SAS_SetReturnSlot(slot,3) end);

-- Unused code

--[[ unneeded delay code - save for later
function SAS_MissingItem( id, itemInfo )
	-- Add to list of items to place on the bar when available.
	if ( id ) then
		if ( not SAS_Saved[PlrName]["MissingItems"] ) then
			SAS_Saved[PlrName]["MissingItems"] = {};
		end
		SAS_Saved[PlrName]["MissingItems"][id] = itemInfo;
		SAS_ForceUpdate( id );
	end
end]]

--[[function SAS_ForceUpdate( id )
	-- Force an update event for an action
	tinsert( SAS_ForceUpdateList, id );
	SASFrame:SetScript( "OnUpdate", SAS_Delayed_OnUpdate );
end

function SAS_Delayed_OnUpdate()
	local id = SAS_ForceUpdateList[1];
	if ( id and not SAS_original_HasAction( id ) ) then
		local itemInfo = SAS_GetMissingItemInfo( id );
		i = 1;
		local passive = IsSpellPassive( i, BOOKTYPE_SPELL );
		while passive do
			i = i + 1;
			passive = IsSpellPassive( i, BOOKTYPE_SPELL );
		end
		PickupSpell( i, BOOKTYPE_SPELL );
		SAS_original_PickupAction( id );
		SAS_Saved[PlrName]["MissingItems"][id] = itemInfo;
		SAS_original_PickupAction( id );
		ClearCursor();
		tremove( SAS_ForceUpdateList, 1 );
	else
		SASFrame:SetScript( "OnUpdate", nil );
	end
end]]

--[[ attempt to unquely identify macros
function SAS_CreateUniqueMacros()
	local function iterateMacros()
		local all, numglobal, numlocal = {}, GetNumMacros();
		numlocal = numlocal + 18;
		for i=1, 36 do
			if ( i > numglobal and i < 19 ) then
				-- no more global macros, skip to local
				i = 19;
			end
			if ( i > numlocal ) then
				-- no more macros
				return;
			end
			local name = GetMacroInfo(i);
			if ( name ) then
				if ( all[name] ) then
					all[name] = all[name] + 1;
					EditMacro(i, name.."�");
					return iterateMacros();
				else
					all[name] = 0;
				end
			end
		end
	end
	iterateMacros();
end

function SAS_StripUniqueMacros()
	for i=1, 36 do
		local name = GetMacroInfo(i);
		if ( name ) then
			EditMacro(i, SAS_StripUniqueMacroName(name));
		end
	end
end

function SAS_StripUniqueMacroName(name)
	return string.gsub(name, "(.-)�+", "%1");
end]]
