--[[local tempActions = {};

function SAS_BuildTempActionList()
	for i=1, 120 do
		tempActions[i] = SAS_BuildActionInfo(SAS_GetActionInfo(i));
	end
end--]]

---------------------------------------------
-- Hook functions to track picked up items --
---------------------------------------------

-- All hooks replaced with new function, yay for GetCursorInfo()!
function SAS_BuildCursorAction()
	SASFakeDrag_Drop(1);
	local curtype, detail, subdetail = GetCursorInfo()
	if ( not curtype ) then
		return;
	elseif ( curtype == "item" ) then
		local name,_,_,_,_,_,_,_,_,texture = GetItemInfo(detail);
		if ( name ) then
			return SAS_BuildActionInfo( name, tPath(texture), nil, detail );
		end
	elseif ( curtype == "spell" and detail > 0 ) then
		local texture = GetSpellTexture( detail, subdetail );
		if ( texture ) then
			local name, rank = GetSpellName( detail, subdetail );
			local passive = IsPassiveSpell( detail, subdetail );
			return SAS_BuildActionInfo( name, tPath(texture), tRank(rank), nil, nil, passive );
		end
	elseif ( curtype == "companion" ) then
		local _,name,_,texture = GetCompanionInfo(subdetail, detail);
		if name then
			return SAS_BuildActionInfo( name, tPath(texture), subdetail );
		end
	elseif ( curtype == "macro" ) then
		local name, texture = GetMacroInfo(detail);
		if ( name ) then
			return SAS_BuildActionInfo( name, tPath(texture), nil, nil, detail );
		end
	end
end

--[[function SAS_PickupAction(...)
	local slot, _, _, _, noExtra = ...;
	local PlrName = SASFrame.PlrName;
	local itemInfo = SAS_GetMissingItemInfo( slot );
	if ( not SAS_SwappingSet ) then
		SAS_SavedPickup = tempActions[slot];
		tempActions[slot] = SAS_BuildActionInfo(SAS_GetActionInfo(slot));
		if ( SAS_SavedPickup ) then
			SASDebug("Picked up action "..(SAS_SavedPickup or "?").." from slot "..slot );
			SAS_ReturnAction = slot;
			SASFakeDrag_Drop(1);
		end
	end
	if ( not noExtra and itemInfo and HasAction(slot) ) then
		SASDebug( "Removing missing item from action "..slot..". Attempted to pick up." );
		SAS_Saved[PlrName]["MissingItems"][slot] = nil;
		SAS_ForceUpdate( slot );
	end
end--]]

--[[
function SAS_PlaceAction(slot)
	if ( not SAS_SwappingSet ) then
		SAS_ReturnAction = nil;
		SASDebug("Place action "..slot);
		SAS_SavedPickup = tempActions[slot];
		tempActions[slot] = SAS_BuildActionInfo(SAS_GetActionInfo(slot));
		if ( SAS_SavedPickup ) then
			SASDebug("Placed action "..(SAS_SavedPickup or "?").." from slot "..slot );
			SASFakeDrag_Drop(1);
		end
	end
end
hooksecurefunc("PlaceAction", SAS_PlaceAction);

function SAS_UseAction(slot, check, onSelf)
	if ( not SAS_SwappingSet ) then
		SAS_ReturnAction = nil;
		SAS_SavedPickup = tempActions[slot];
		tempActions[slot] = SAS_BuildActionInfo(SAS_GetActionInfo(slot));
		if ( SAS_SavedPickup ) then
			SASFakeDrag_Drop(1);
			SASDebug("Use action "..(SAS_SavedPickup or "?").." from slot "..slot );
		end
	end
end
hooksecurefunc("UseAction", SAS_UseAction);

function SAS_PickupContainerItem( bag, slot )
	if ( not SAS_SwappingSet ) then
		SAS_ReturnAction = nil;
		local itemLink = GetContainerItemLink( bag, slot );
		if ( itemLink ) then
			local name = SAS_FindName(itemLink);
			local link = SAS_FindLink(itemLink);
			local texture = GetContainerItemInfo( bag, slot );
			SAS_SavedPickup = SAS_BuildActionInfo( name, tPath(texture), nil, link );
			SASFakeDrag_Drop(1);
			SASDebug("Pick up container item "..name.." from "..bag..", "..slot );
		end
	end
end
hooksecurefunc("PickupContainerItem", SAS_PickupContainerItem);

function SAS_PickupInventoryItem(index)
	if ( not SAS_SwappingSet ) then
		SAS_ReturnAction = nil;
		local itemLink = GetInventoryItemLink( "player", index );
		if ( itemLink ) then
			local name = SAS_FindName(itemLink);
			local link = SAS_FindLink(itemLink);
			local texture = GetInventoryItemTexture( "player", index );
			SAS_SavedPickup = SAS_BuildActionInfo( name, tPath(texture), nil, link );
			SASFakeDrag_Drop(1);
			SASDebug("Pick up inventory item "..name.." from "..index );
		end
	end
end
hooksecurefunc("PickupInventoryItem", SAS_PickupInventoryItem);

function SAS_PickupMacro(index)
	if ( not SAS_SwappingSet ) then
		SAS_ReturnAction = nil;
		local name, texture = GetMacroInfo(index);
		local macro = GetMacroIndexByName(name);
		if ( name ) then
			SAS_SavedPickup = SAS_BuildActionInfo( name, tPath(texture), nil, nil, macro );
			SASFakeDrag_Drop(1);
			SASDebug("Pick up macro "..name.." from "..index );
		end
	end
end
hooksecurefunc("PickupMacro", SAS_PickupMacro);

function SAS_PickupSpell(id, bookType)
	if ( not SAS_SwappingSet ) then
		SAS_ReturnAction = nil;
		local name, rank = GetSpellName( id, bookType );
		local texture = GetSpellTexture( id, bookType );
		if ( name ) then
			SASFakeDrag_Drop(1);
			SASDebug("Pick up spell "..name.." from "..id);
			local passive = IsPassiveSpell( id, bookType );
			if ( passive ) then
				SASDebug("Spell is passive? Why can we pick this up?");
			end
			SAS_SavedPickup = SAS_BuildActionInfo( name, tPath(texture), tRank(rank), nil, nil, passive );
		end
	end
end
hooksecurefunc("PickupSpell", SAS_PickupSpell);--]]


--------------------------------------------
-- Hook functions to drop fake drag frame --
--------------------------------------------

local function forceFakeDrop()
	SASFakeDrag_Drop(1);
end
hooksecurefunc("CameraOrSelectOrMoveStart", forceFakeDrop);
hooksecurefunc("TurnOrActionStart", forceFakeDrop);

-------------------------------------------
-- Hook functions to show missing items --
-------------------------------------------
--[[
SAS_original_GetActionTexture = GetActionTexture;
function SAS_GetActionTexture( id )
	local PlrName = SASFrame.PlrName;
	local texture = SAS_original_GetActionTexture( id );
	local itemInfo = SAS_GetMissingItemInfo( id );
	if ( itemInfo ) then
		if ( texture ) then
			SASDebug( "Removing missing item from action "..id..". Real action exists." );
			SAS_Saved[PlrName]["MissingItems"][id] = nil;
			SAS_ForceUpdate( id );
		else
			return SAS_FullPath(SAS_ParseActionInfo(itemInfo, 2));
		end
	end
	return texture;
end
GetActionTexture = SAS_GetActionTexture;

SAS_original_IsConsumableAction = IsConsumableAction;
function SAS_IsConsumableAction( id )
	if ( SAS_GetMissingItemInfo( id ) ) then
		return 1;
	end
	return SAS_original_IsConsumableAction( id );
end
IsConsumableAction = SAS_IsConsumableAction;

SAS_original_HasAction = HasAction;
function SAS_HasAction( ... )
	local slot, _, _, _, noExtra = ...;
	if ( not noExtra and SAS_GetMissingItemInfo( slot ) ) then
		return 1;
	end
	return SAS_original_HasAction( slot );
end
HasAction = SAS_HasAction;

function SAS_SetAction( this, id )
	local PlrName = SASFrame.PlrName;
	local itemInfo = SAS_GetMissingItemInfo( id );
	if ( itemInfo ) then
		local name, link = SAS_ParseActionInfo( itemInfo, 1, 4);
		if ( link and GetItemInfo("item:"..link) ) then
			TooltipReturn = GameTooltip:SetHyperlink("item:"..link);
		else
			TooltipReturn = GameTooltip:SetText( name, 1, 1, 1 );
			SASTooltipAddLine( SAS_TEXT_TOOLTIP_NOTVALID );
		end
		if ( not SAS_Saved[PlrName]["HideFakeItemTooltips"] ) then
			SASTooltipAddLine( SAS_TEXT_TOOLTIP_GENERATEDACTION );
			if ( IsShiftKeyDown() or SAS_IsValidAction ) then
				SASTooltipAddLine( SAS_TEXT_TOOLTIP_FAKEACTIONWARN );
			end
		end
		GameTooltip:Show();
	end
end
hooksecurefunc(GameTooltip, "SetAction", SAS_SetAction);

--]]