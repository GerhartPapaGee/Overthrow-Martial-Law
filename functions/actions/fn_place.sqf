if !(captive player) exitWith {"You cannot place objects while wanted" call OT_fnc_notifyMinor};

private _typecls = _this;

([_typecls] call {
	params ["_typecls"];
	private _ft = server getVariable ["OT_fastTravelType",1];
	if(!OT_adminMode && _ft > 1 && _typecls == "Camp") exitWith {hint "Fast Travel is disabled";};
	if(_typecls == "Camp") exitWith {
		[
			[0,3.5,1.1],
			[OT_item_Tent],
			40,
			"Creates a fast travel destination for all friendlies. Only one allowed per player, will remove any existing camps."
		]
	};
	if(_typecls == "Base") exitWith {
		[
			[0,6,4],
			[OT_flag_IND],
			5000,
			"Creates a fast travel destination for all friendlies and enables build mode for basic military structures"
		]
	};
	if(_typecls == "Ammobox") exitWith {
		[
			nil,
			[OT_item_Storage],
			60,
			"Another empty ammobox to fill with items you have acquired through.. various means."
		]
	};
	if(_typecls == "Whiteboard") exitWith {
		[
			nil,
			[OT_item_Map],
			20,
			"Plan out your next assault in the middle of the jungle."
		]
	};
	{
		if((_x select 0) == _typecls) exitWith {
			private _classes = [];
			{
				_class = _x select 0;
				_classes append [_class];
			}foreach (_x select 1);

			if(isNil "modeValue") then {
				modeValue = 0;
			};
			private _cls = _classes select modeValue;
			private _cost = ((_x select 1) select modeValue) select 1;
			private _description = ((_x select 1) select modeValue) select 2;

			[
				_x select 2,
				_classes,
				_cost,
				_description
			]
		};
	}foreach(OT_Placeables);
}) params [
	["_attachAt", [0,2,1]],
	["_modeValues", []],
	["_cost", 0],
	["_description", ""]
];
attachAt = _attachAt;
modeValues = _modeValues;
modeType = _typecls;
modeCost = _cost;
modeDescription = _description;
modeFinished = false;
modeCancelled = false;
modeSurface = false;

if !([getpos player,_typecls] call OT_fnc_canPlace) exitWith {
	if(_typecls == "Camp") exitWith {
		"Camps cannot be near another building" call OT_fnc_notifyMinor;
	};
	if(_typecls == "Base") exitWith {
		"Bases cannot be too close to a town, NATO installation or existing base" call OT_fnc_notifyMinor;
	};
	"You must be near a base or owned structure" call OT_fnc_notifyMinor
};

modeTarget = objNULL;
modeRedo = false;
if(isNil "modeValue") then {
	modeValue = 0;
};
if(isNil "modeRotation") then {
	modeRotation = 180;
};

if(modeCost > 0) then {
	[format [
		"<t size='1.1' color='#eeeeee'>%1</t><br/><t size='0.8' color='#bbbbbb'>$%2</t><br/><t size='0.4' color='#bbbbbb'>%3</t><br/><br/><t size='0.5' color='#bbbbbb'>Q,E = Rotate<br/>Space = Change Type<br/>Enter = Done<br/>Shift = Rotate faster/Place multiple<br/>Esc = Cancel</t>",
		_typecls,
		[modeCost, 1, 0, true] call CBA_fnc_formatNumber,
		_description
	], [safeZoneX + (0.8 * safeZoneW), (0.2 * safeZoneW)], 0.5, 10, 0, 0, 2] call OT_fnc_dynamicText;

	_keyhandler = {
		params ["_ctrl", "_key", "_shift", "_ctrlKey", "_alt"];

		private _dir = modeRotation;
		if(_key isEqualTo 19) exitWith {
			//R
			false
		};
		private _amt = 1;
		if (_shift) then { _amt = 5; };
		if (_key isEqualTo 16) exitWith {
			//Q
			private _newdir = _dir - _amt;
			if(_newdir < 0) then {_newdir = _newdir + 360};
			modeTarget setDir (_newdir);
			modeRotation = _newDir;
			if (modeSurface) then {
				modeTarget setVectorUp surfaceNormal position modeTarget;
			} else {
				modeTarget setVectorUp [0,0,1];
			};
			true
		};
		if (_key isEqualTo 18) exitWith {
			//E
			private _newdir = _dir + _amt;
			if(_newdir > 359) then {_newdir = _newdir - 360};
			modeTarget setDir (_newdir);
			modeRotation = _newDir;
			if (modeSurface) then {
				modeTarget setVectorUp surfaceNormal position modeTarget;
			} else {
				modeTarget setVectorUp [0,0,1];
			};
			true
		};
		if (_key isEqualTo 33) exitWith {
			//F
			modeSurface = !modeSurface;
			if (modeSurface) then {
				modeTarget setVectorUp surfaceNormal position modeTarget;
			} else {
				modeTarget setVectorUp [0,0,1];
			};
			true
		};
		if(_key isEqualTo 57) exitWith {
			//Space
			detach modeTarget;
			deleteVehicle modeTarget;
			modeValue = modeValue + 1;
			if(modeValue > ((count modeValues)-1)) then {modeValue = 0};

			private _cls = modeValues select modeValue;

			modeTarget = createVehicle [_cls, [0,0,0], [], 0, "CAN_COLLIDE"];
			modeTarget enableDynamicSimulation true;
			if(_cls == "B_Boat_Transport_01_F") then {
				_dir = _dir + 90;
			};

			clearWeaponCargoGlobal modeTarget;
			clearMagazineCargoGlobal modeTarget;
			clearBackpackCargoGlobal modeTarget;
			clearItemCargoGlobal modeTarget;
			{
				if((_x select 0) == modeType) exitWith {
					private _classes = _x select 1;
					modeCost = _classes select modeValue select 1;
					modeDescription = _classes select modeValue select 2;
				};
			}foreach(OT_Placeables);

			[format [
				"<t size='1.1' color='#eeeeee'>%1</t><br/><t size='0.8' color='#bbbbbb'>$%2</t><br/><t size='0.4' color='#bbbbbb'>%3</t><br/><br/><t size='0.5' color='#bbbbbb'>Q,E = Rotate (Shift for larger rotate)<br/><t size='0.5' color='#bbbbbb'>F = Toggle Surface Mode<br/>Space = Change Type<br/>Enter = Done<br/>Shift = Rotate faster/Place multiple<br/>Esc = Cancel</t>",
				modeType,
				[modeCost, 1, 0, true] call CBA_fnc_formatNumber,
				modeDescription
			], [safeZoneX + (0.8 * safeZoneW), (0.2 * safeZoneW)], 0.5, 10, 0, 0, 2] call OT_fnc_dynamicText;

			modeTarget attachTo [player,attachAt];
			modeTarget setDir _dir;
			if (modeSurface) then {
				modeTarget setVectorUp surfaceNormal position modeTarget;
			} else {
				modeTarget setVectorUp [0,0,1];
			};
		true
		};
		if(_key isEqualTo 28) exitWith {
			//Enter
			//Price check (on aisle 3)
			private _money = player getVariable "money";
			if(modeCost > _money) exitWith {
				format["You cannot afford that, you need $%1",modeCost] call OT_fnc_notifyMinor;
				modeCancelled = true;
				true
			};
			modeFinished = true;
			if(_shift) then {
				modeRedo = true;
			};
			true
		};
		if(_key isEqualTo 1) exitWith {
			//ESC
			modeCancelled = true;
			true
		};
		false
	};

	private _cls = modeValues select modeValue;
	private _handlerId = (findDisplay 46) displayAddEventHandler ["KeyDown",_keyhandler];
	modeTarget = createVehicle [_cls, [0,0,0], [], 0, "CAN_COLLIDE"];

	clearWeaponCargoGlobal modeTarget;
	clearMagazineCargoGlobal modeTarget;
	clearBackpackCargoGlobal modeTarget;
	clearItemCargoGlobal modeTarget;

	modeTarget attachTo [player,attachAt];
	modeTarget setDir modeRotation;
	if(_cls == "B_Boat_Transport_01_F") then {
		private _p = getDir modeTarget;
		private _v = getDir player;
		private _c = 360;

		private _dir = _c-((_c-_p)-(_c-_v));
		if(_dir >= 360) then {_dir = _dir - 360};

		modeTarget setDir _dir + 90;
	};

	waitUntil {
		sleep 0.5;
		modeFinished
		|| modeCancelled
		|| (count attachedObjects player == 0)
		|| (vehicle player != player)
		|| (!alive player)
		|| (!isPlayer player)
	};

	(findDisplay 46) displayRemoveEventHandler ["KeyDown",_handlerId];

	{detach _x} forEach attachedObjects player;

	if(
		modeCancelled
		|| (vehicle player != player)
		|| (!alive player)
		|| (!isPlayer player)
	) then {
		detach modeTarget;
		deleteVehicle modeTarget;
	}else{
		if ([getpos player,_typecls] call OT_fnc_canPlace) then {
			private _proceed = true;
			if(_typecls isEqualTo "Base") then {
				if(({side _x isEqualTo west || side _x isEqualTo east} count ((getpos modeTarget) nearEntities 200)) > 0) exitWith {
					"You cannot build a FOB so close to enemies." call OT_fnc_notifyMinor;
					detach modeTarget;
					deleteVehicle modeTarget;
					_proceed = false;
				};
				createDialog "OT_dialog_name";
				ctrlSetText [1400,"Base"];
			};
			if!(_proceed) exitWith {};
			[-modeCost] call OT_fnc_money;
			modeTarget setPosATL [getPosATL modeTarget select 0,getPosATL modeTarget select 1,getPosATL player select 2];
			[modeTarget,getPlayerUID player] call OT_fnc_setOwner;
			modeTarget remoteExec["OT_fnc_initObjectLocal",0,modeTarget];
			if(_typecls == "Base" || _typecls == "Camp") then {
				// @todo remove this when done
				createVehicle ["Land_ClutterCutter_large_F", (getpos modeTarget), [], 0, "CAN_COLLIDE"];
			};

			if(_typecls == "Camp") then {
				private _mrkid = format["%1-camp",getplayeruid player];
				createMarker [_mrkid,getpos modeTarget];
				_mrkid setMarkerPos (getpos modeTarget);
				private _camp = player getVariable["camp",[]];
				if(count _camp > 0) then {
					{
						private _t = typeof _x;
						if(((_x call OT_fnc_getOwner) == getplayeruid player) && !(modeTarget == _x)) then {
							{
								deleteVehicle _x;
							}foreach(_x nearObjects ["Land_ClutterCutter_large_F", 5]);
							deleteVehicle _x;
						};
					}foreach(allMissionObjects OT_item_Tent);
				};
				player setVariable ["camp",getpos modeTarget,true];
				_mrkid setMarkerShape "ICON";
				_mrkid setMarkerType "ot_Camp";
				_mrkid setMarkerColor "ColorWhite";
				_mrkid setMarkerAlpha 1;
				_mrkid setMarkerText format ["Camp %1",name player];
				_builder = name player;
				{
					_desc = (getpos modeTarget) call BIS_fnc_locationDescription;
					[_x,format["New Camp %1",_desc],format["%1 placed a camp %2",_builder,_desc]] call BIS_fnc_createLogRecord;
				}foreach([] call CBA_fnc_players);
			};
		}else{
			detach modeTarget;
			deleteVehicle modeTarget;
			_typecls call {
				if(_this == "Camp") exitWith {"Camps cannot be near a structure you already own" call OT_fnc_notifyMinor;};
				if(_this == "Base") exitWith {"Bases cannot be near a town, NATO installation or existing base" call OT_fnc_notifyMinor;};
				"You must be near a base or owned building" call OT_fnc_notifyMinor;
			};
		};
	};
}else{
	if(_typecls != "Camp" && _typecls != "Base") then {
		"To place this item you must be near a base or a building that you own" call OT_fnc_notifyMinor;
	}else{
		"You cannot place a camp/base near a building you own. Bases must also be built away from towns." call OT_fnc_notifyMinor;
	};
};

//Cleanup public vars
modeTarget = nil;
modeCancelled = nil;
modeFinished = nil;
if(modeRedo) then {
	_typecls spawn OT_fnc_place;
}else{
	modeValue = nil;
}
