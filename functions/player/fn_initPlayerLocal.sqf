if (!hasInterface) exitWith {};

if !(isClass (configFile >> "CfgPatches" >> "OT_Overthrow_Main")) exitWith {
	[
        format ["<t size='1' color='#000000'>Overthrow addon not detected, you must add @Overthrow to your -mod commandline</t>",_this],
        0,
        0.2,
        30,
        0,
        0,
        2
    ] spawn BIS_fnc_dynamicText;
};

//waitUntil {!isNull player && {player isEqualTo player} && {!isNull server}};
waitUntil {time > 1 && {server isEqualType bigboss} && {count (allvariables server) > 0}}; // per MaxP

ace_interaction_EnableTeamManagement = true; //Enable\Disable group switching
ace_interaction_disableNegativeRating = true; //Disable ACE negative ratings

enableSaving [false,false];
enableEnvironment [false,true];

if(isServer) then {
	missionNameSpace setVariable ["OT_HOST", player, true];
};

if(isNil {server getVariable "generals"}) then {
	server setVariable ["generals",[getplayeruid player]]
};

OT_centerPos = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");

if(isMultiplayer && (!isServer)) then {
	// this is all done on server too, no need to execute them again
	call OT_fnc_initBaseVar;
	call compile preprocessFileLineNumbers "initVar.sqf";
	call OT_fnc_initVar;
	[] spawn OT_fnc_jobSystem;
	addMissionEventHandler ["EntityKilled",OT_fnc_deathHandler];
	//ACE3 events
	["ace_cargoLoaded",OT_fnc_cargoLoadedHandler] call CBA_fnc_addEventHandler;
	["ace_common_setFuel",OT_fnc_refuelHandler] call CBA_fnc_addEventHandler;
	["ace_explosives_place",OT_fnc_explosivesPlacedHandler] call CBA_fnc_addEventHandler;
	["ace_repair_setWheelHitPointDamage",OT_fnc_WheelRemovedHandler] call CBA_fnc_addEventHandler;
	//Overthrow events
	["OT_QRFstart", OT_fnc_QRFStartHandler] call CBA_fnc_addEventHandler;
	["OT_QRFend", OT_fnc_QRFEndHandler] call CBA_fnc_addEventHandler;
	OT_QRFstart = spawner getVariable ["QRFstart",nil];//If theres already a QRF going
}else{
	OT_varInitDone = true;
};

private _highCommandModule = (createGroup sideLogic) createUnit ["HighCommand",[0,0,0],[],0,"NONE"];
_highCommandModule synchronizeObjectsAdd [player];
missionNameSpace setVariable [format["%1_hc_module",getPlayerUID player],_highCommandModule,true];

private _start = OT_startCameraPos;
private _introcam = "camera" camCreate _start;
_introcam camSetTarget OT_startCameraTarget;
_introcam cameraEffect ["internal", "BACK"];
_introcam camSetFocus [15, 1];
_introcam camsetfov 1.1;
_introcam camCommit 0;
waitUntil {camCommitted _introcam};
showCinemaBorder false;

if(!isMultiplayer) exitWith {
	[
		"<t size='1' color='#000000'>Overthrow currently does not work very well in Single Player mode. Please host a LAN game for solo play. See the wiki at http://armaoverthrow.com/</t>",
		0,
		0.2,
		30,
		0,
		0,
		2
	] call OT_fnc_dynamicText;
};

if((isServer || count ([] call CBA_fnc_players) == 1) && (server getVariable ["StartupType",""] isEqualTo "")) then {
    waitUntil {!(isnull (findDisplay 46)) && OT_varInitDone};

	if (isServer || count ([] call CBA_fnc_players) == 1) then {
		sleep 1;
		if ((["ot_start_autoload", 0] call BIS_fnc_getParamValue) == 1) then {
			server setVariable ["OT_difficulty",["ot_start_difficulty", 1] call BIS_fnc_getParamValue,true];
			server setVariable ["OT_fastTravelType",["ot_start_fasttravel", 1] call BIS_fnc_getParamValue,true];
			server setVariable ["OT_fastTravelRules",["ot_start_fasttravelrules", 1] call BIS_fnc_getParamValue,true];
			[] remoteExec ['OT_fnc_loadGame',2,false];
		} else {
			createDialog "OT_dialog_start";
		};
	};
}else{
	"Loading" call OT_fnc_notifyStart;
};
OT_showPlayerMarkers = (["ot_showplayermarkers", 1] call BIS_fnc_getParamValue) isEqualTo 1;
OT_showTownChange = (["ot_showtownchange", 1] call BIS_fnc_getParamValue) isEqualTo 1;
OT_showEnemyGroups = (["ot_showenemygroups", 1] call BIS_fnc_getParamValue) isEqualTo 1;
OT_showEnemyCorpses = (["ot_showenemycorpses", 1] call BIS_fnc_getParamValue) isEqualTo 1;


waitUntil {sleep 1;!isNil "OT_NATOInitDone"};

private _aplayers = players_NS getVariable ["OT_allplayers",[]];
if ((_aplayers find (getplayeruid player)) isEqualTo -1) then {
	_aplayers pushback (getplayeruid player);
	players_NS setVariable ["OT_allplayers",_aplayers,true];
};
if(!isMultiplayer) then {
	private _generals = server getVariable ["generals",[]];
	if ((_generals find (getplayeruid player)) isEqualTo -1) then {
		_generals pushback (getplayeruid player);
		server setVariable ["generals",_generals,true];
	};
};
players_NS setVariable [format["name%1",getplayeruid player],name player,true];
players_NS setVariable [format["uid%1",name player],getplayeruid player,true];
spawner setVariable [format["%1",getplayeruid player],player,true];

player forceAddUniform (OT_clothes_locals call BIS_fnc_selectRandom);
// clear player
removeAllWeapons player;
removeAllAssignedItems player;
removeGoggles player;
removeBackpack player;
removeHeadgear player;
removeVest player;
player linkItem "ItemMap";

private _startup = server getVariable "StartupType";
private _newplayer = true;
private _furniture = [];
private _town = "";
private _pos = [];
private _housepos = [];

if(isMultiplayer || _startup == "LOAD") then {
	player remoteExec ["OT_fnc_loadPlayerData",2,false];
  waitUntil{sleep 0.5;player getVariable ["OT_loaded",false]};

	if (player getVariable["home",false] isEqualType []) then {
	  _newplayer = false;
	}else{
	  _newplayer = true;
	};


	if(isMultiplayer) then {
		//ensure player is in own group, not one someone else left
		private  _group = creategroup resistance;
		[player] joinSilent _group;
	};

	if(!_newplayer) then {
		_housepos = player getVariable "home";
		if(isNil "_housepos" || (count _housepos) isEqualTo 0) exitWith {_newplayer = true};
		_town = _housepos call OT_fnc_nearestTown;
		_pos = server getVariable _town;
		{
			if(_x call OT_fnc_hasOwner) then {
				if ((_x call OT_fnc_playerIsOwner) && !(_x isKindOf "LandVehicle") && !(_x isKindOf "Building")) then {
					_furniture pushback _x
				};
			};
		}foreach(_housepos nearObjects 50);
	};

	(group player) setVariable ["VCM_Disable",true];

	_recruits = server getVariable ["recruits",[]];
	_newrecruits = [];
	{
		_owner = _x select 0;
		_name = _x select 1;
		_civ = _x select 2;
		_rank = _x select 3;
		_loadout = _x select 4;
		_type = _x select 5;
		_xp = _x select 6;
		if(_owner isEqualTo (getplayeruid player)) then {
			if(typename _civ isEqualTo "ARRAY") then {
				_pos = _civ findEmptyPosition [5,20,_type];
				_civ =  group player createUnit [_type,_pos,[],0,"NONE"];
				[_civ,getplayeruid player] call OT_fnc_setOwner;
				_civ setVariable ["OT_xp",_xp,true];
				_civ setVariable ["NOAI",true,true];
				_civ setRank _rank;
				if(_rank isEqualTo "PRIVATE") then {_civ setSkill 0.2 + (random 0.3)};
				if(_rank isEqualTo "CORPORAL") then {_civ setSkill 0.3 + (random 0.3)};
				if(_rank isEqualTo "SERGEANT") then {_civ setSkill 0.4 + (random 0.3)};
				if(_rank isEqualTo "LIEUTENANT") then {_civ setSkill 0.6 + (random 0.3)};
				if(_rank isEqualTo "CAPTAIN") then {_civ setSkill 0.7 + (random 0.3)};
				if(_rank isEqualTo "MAJOR") then {_civ setSkill 0.8 + (random 0.2)};
				[_civ, (OT_faces_local call BIS_fnc_selectRandom)] remoteExecCall ["setFace", 0, _civ];
				[_civ, (OT_voices_local call BIS_fnc_selectRandom)] remoteExecCall ["setSpeaker", 0, _civ];
				_civ setUnitLoadout _loadout;
				_civ spawn OT_fnc_wantedSystem;
				_civ setName _name;
				_civ setVariable ["OT_spawntrack",true,true];

				[_civ] joinSilent nil;
				[_civ] joinSilent (group player);

				commandStop _civ;
			}else{
				if(_civ call OT_fnc_playerIsOwner) then {
					[_civ] joinSilent (group player);
				};
			};
		};
		_newrecruits pushback [_owner,_name,_civ,_rank,_loadout,_type];
	}foreach (_recruits);
	server setVariable ["recruits",_newrecruits,true];

	_squads = server getVariable ["squads",[]];
	_newsquads = [];
	_cc = 1;
	{
		_x params ["_owner","_cls","_group","_units"];
		if(_owner isEqualTo (getplayeruid player)) then {
			if(typename _group != "GROUP") then {
				_name = _cls;
				if(count _x > 4) then {
					_name = _x select 4;
				}else{
					{
						if((_x select 0) isEqualTo _cls) then {
							_name = _x select 2;
						};
					}foreach(OT_Squadables);
				};
				_group = creategroup resistance;
				_group setGroupIdGlobal [_name];
				{
					_x params ["_type","_pos","_loadout"];
					_civ = _group createUnit [_type,_pos,[],0,"NONE"];
					_civ setSkill 0.5 + (random 0.4);
					_civ setUnitLoadout _loadout;
					[_civ, (OT_faces_local call BIS_fnc_selectRandom)] remoteExecCall ["setFace", 0, _civ];
					[_civ, (OT_voices_local call BIS_fnc_selectRandom)] remoteExecCall ["setSpeaker", 0, _civ];
					_civ setVariable ["OT_spawntrack",true,true];
				}foreach(_units);
			};
			player hcSetGroup [_group,groupId _group,"teamgreen"];
			_cc = _cc + 1;
		};
		_newsquads pushback [_owner,_cls,_group,[]];
	}foreach (_squads);
	player setVariable ["OT_squadcount",_cc,true];
	server setVariable ["squads",_newsquads,true];
};

if (_newplayer) then {
    _clothes = (OT_clothes_guerilla call BIS_fnc_selectRandom);
	player forceAddUniform _clothes;
    player setVariable ["uniform",_clothes,true];
	private _money = 15000;
	private _diff = server getVariable ["OT_difficulty",1];
	if(_diff isEqualTo 0) then {
		_money = 15000;
	};
	if(_diff isEqualTo 2) then {
		_money = 15000;
	};
    player setVariable ["money",_money,true];
    [player,getplayeruid player] call OT_fnc_setOwner;
    if(!isMultiplayer) then {
        {
            if(_x != player) then {
             	deleteVehicle _x;
            };
        } foreach switchableUnits;
    };

    _town = server getVariable "spawntown";
    if(OT_randomSpawnTown) then {
        _town = OT_spawnTowns call BIS_fnc_selectRandom;
    };
	_house = _town call OT_fnc_getPlayerHome;
    _housepos = getpos _house;

    //Put a light on at home
    _light = "#lightpoint" createVehicle [_housepos select 0,_housepos select 1,(_housepos select 2)+2.2];
    _light setLightBrightness 0.11;
    _light setLightAmbient[.9, .9, .6];
    _light setLightColor[.5, .5, .4];

	//Free quad
	_pos = _housepos findEmptyPosition [5,100,"C_Quadbike_01_F"];

	if (count _pos > 0) then {
		_veh = "C_Quadbike_01_F" createVehicle _pos;
		[_veh,getPlayerUID player] call OT_fnc_setOwner;
		clearWeaponCargoGlobal _veh;
		clearMagazineCargoGlobal _veh;
		clearBackpackCargoGlobal _veh;
		clearItemCargoGlobal _veh;
		player reveal _veh;
		[player, _veh, true] call ace_vehiclelock_fnc_addKeyForVehicle;
	};

    [_house,getplayeruid player] call OT_fnc_setOwner;
    player setVariable ["home",_housepos,true];

    _furniture = (_house call OT_fnc_spawnTemplate) select 0;

    {
		if(typeof _x isEqualTo OT_item_Storage) then {
            _x addItemCargoGlobal ["ToolKit", 1];
			      _x addBackpackCargoGlobal ["B_AssaultPack_khk", 1];
		    	  _x addItemCargoGlobal ["ACE_Flashlight_Maglite_ML300L", 1];//removed NVGoggles_INDEP
			      _x addItemCargoGlobal ["ACRE_PRC343", 1];
			      _x addItemCargoGlobal ["U_C_E_LooterJacket_01_F", 1];
			      _x addItemCargoGlobal ["U_C_Mechanic_01_F", 1];
			      _x addItemCargoGlobal ["U_I_C_Soldier_Para_2_F", 1];
		      	_x addItemCargoGlobal ["H_Construction_basic_black_F", 1];
			      _x addItemCargoGlobal ["eo_racing_1", 1];
			      _x addItemCargoGlobal ["eo_safari_1", 1];
			      _x addItemCargoGlobal ["H_Booniehat_oli", 1];
			      _x addItemCargoGlobal ["H_Booniehat_tan", 1];
			      _x addItemCargoGlobal ["V_Pocketed_black_F", 1];
			      _x addItemCargoGlobal ["V_Pocketed_coyote_F", 1];
			      _x addItemCargoGlobal ["V_Pocketed_olive_F", 1];
        };
        [_x,getplayeruid player] call OT_fnc_setOwner;
    }foreach(_furniture);
    player setVariable ["owned",[[_house] call OT_fnc_getBuildingId],true];

};
_count = 0;
{
	if !(_x isKindOf "Vehicle") then {
		if(_x call OT_fnc_hasOwner) then {
			_x call OT_fnc_initObjectLocal;
		};
	};
	if(_count > 5000) then {
		_count = 0;
		titleText ["Loading... please wait", "BLACK FADED", 0];
	};
	_count = _count + 1;
}foreach((allMissionObjects "Building") + vehicles);

waitUntil {!isNil "OT_SystemInitDone"};
titleText ["Loading Session", "BLACK FADED", 0];
player setCaptive true;
player setPos (_housepos findEmptyPosition [1,20,typeof player]);
if !("ItemMap" in (assignedItems player)) then {
	player linkItem "ItemMap";
};
[_housepos] spawn {
	params ["_housepos"];
	waitUntil{ preloadCamera _housepos};
	titleText ["", "BLACK IN", 5];
	sleep 1;
	[[[format["%1, %2",(getpos player) call OT_fnc_nearestTown,OT_nation],"align = 'center' size = '0.7' font='PuristaBold'"],["","<br/>"],[format["%1/%2/%3",date#2,date#1,date#0]],["","<br/>"],[format["%1",[daytime,"HH:MM"] call BIS_fnc_timeToString],"align = 'center' size = '0.7'"],["s","<br/>"]]] spawn BIS_fnc_typeText2;
};

[] spawn {
	waitUntil{!(isNull (findDisplay 46))};
	(findDisplay 46) displayAddEventHandler ["KeyDown", "if ((_this#1) isEqualTo 1) then { [player] call OT_fnc_savePlayerData;	};"];
};

player addEventHandler ["WeaponAssembled",{
	params ["_me","_wpn"];
	private _pos = getPosATL _wpn;
	if(typeof _wpn in OT_staticWeapons) then {
		if(_me call OT_fnc_unitSeen) then {
			_me setCaptive false;
		};
	};
	if(isplayer _me) then {
		[_wpn,getplayeruid player] call OT_fnc_setOwner;
	};
}];

// Temp fix for guns disappearing
player addEventHandler ["InventoryOpened", {
    params ["_unit","_veh"];
    private _locked = false;
    if (_veh isKindOf "Vehicles" && !(_veh call OT_fnc_playerIsOwner)) then {
        private _isgen = call OT_fnc_playerIsGeneral;
        if (!(_isgen) && (_veh getVariable ["OT_locked",false])) exitWith {
            hint format["This inventory has been locked by %1",server getVariable "name"+(_veh call OT_fnc_getOwner)];
            _locked = true;
        };
    };
	/*
    if (_veh isKindOf "Man") then {
		private _holder = nearestObject [player, "WeaponHolderSimulated"];
		private _pos = getposATL _holder;
		private _item = weaponsItemsCargo _holder;
		private _vectorDirUp = [vectorDir _holder, vectorUp _holder];
		[{
			params ["_holder","_pos","_vectorDirUp","_item"];
			(((getposATL _holder) select 2) < 1 or isnull (findDisplay 602));
		},{
			params ["_holder","_pos","_vectorDirUp","_item"];
			if ((getposATL _holder) select 2 < 1) then {
				deletevehicle _holder;
				private _newholder = createVehicle ["WeaponHolderSimulated", _pos, [], 0, "NONE"];
				_newholder setVectorDirAndUp _vectorDirUp;
				_newholder setposATL _pos;
				_newholder addWeaponWithAttachmentsCargoGlobal [(_item select 0), 1];
			};
		},[_holder,_pos,_vectorDirUp,_item]] call CBA_fnc_waitUntilAndExecute;
    };
	*/
    _locked
}];


player addEventHandler ["InventoryOpened", {
	params ["","_veh"];
	private _locked = false;
	if !(_veh call OT_fnc_playerIsOwner) then {
		private _isgen = call OT_fnc_playerIsGeneral;
		if(!_isgen && (_veh getVariable ["OT_locked",false])) exitWith {
			hint format["This inventory has been locked by %1",server getVariable "name"+(_veh call OT_fnc_getOwner)];
			_locked = true;
		};
	};
	_locked
}];

player addEventHandler ["GetInMan",{
	params ["_unit","_position","_veh"];

	call OT_fnc_notifyVehicle;

	if !(_veh call OT_fnc_hasOwner) then {
		[_veh,getplayeruid player] call OT_fnc_setOwner;
		_veh setVariable ["stolen",true,true];
		if((_veh getVariable ["ambient",false]) && (random 100) > 30) then {
			["play", _veh] call BIS_fnc_carAlarm;
			[(getpos player) call OT_fnc_nearestTown,-5,"Stolen vehicle",player] call OT_fnc_support;
			//does anyone hear the alarm?
			_nummil = {side _x isEqualTo west} count (_veh nearObjects ["CAManBase",200]);
			if(_nummil > 0) then {
				player setCaptive false;
				[player] call OT_fnc_revealToNATO;
			};
		};
	} else {
		if !(_veh call OT_fnc_playerIsOwner) then {
			private _isgen = call OT_fnc_playerIsGeneral;
			if(!_isgen && (_veh getVariable ["OT_locked",false])) then {
				moveOut player;
				hint format["This vehicle has been locked by %1",server getVariable "name"+(_veh call OT_fnc_getOwner)];
			};
		};
	};

	_g = _veh getVariable ["vehgarrison",false];
	if(_g isEqualType "") then {
		_vg = server getVariable format["vehgarrison%1",_g];
		_vg deleteAt (_vg find (typeof _veh));
		server setVariable [format["vehgarrison%1",_g],_vg,false];
		_veh setVariable ["vehgarrison",nil,true];
		{
			_x setCaptive false;
		}foreach(crew _veh);
		[_veh] call OT_fnc_revealToNATO;
	};
	_g = _veh getVariable ["airgarrison",false];
	if(_g isEqualType "") then {
		_vg = server getVariable format["airgarrison%1",_g];
		_vg deleteAt (_vg find (typeof _veh));
		server setVariable [format["airgarrison%1",_g],_vg,false];
		_veh setVariable ["airgarrison",nil,true];
		{
			_x setCaptive false;
		}foreach(crew _veh);
		[_veh] call OT_fnc_revealToNATO;
	};
}];

{
	_pos = buildingpositions getVariable [_x,[]];
	if(count _pos isEqualTo 0) then {
		_bdg = OT_centerPos nearestObject parseNumber _x;
		_pos = position _bdg;
		buildingpositions setVariable [_x,_pos,true];
	};
}foreach(player getvariable ["owned",[]]);

if(isMultiplayer) then {
	player addEventHandler ["Respawn",OT_fnc_respawnHandler];
};

// Custom Keybinds
// 21=Y
_id = [21, [false, false, false], OT_fnc_keyHandler] call CBA_fnc_addKeyHandler;
// 5=4 (Keys 1-0 are 2-11)
_id = [5, [false, false, false], OT_fnc_holsterHandGun] call CBA_fnc_addKeyHandler;

player call OT_fnc_mapSystem;
//Scroll actions
{
    _x params ["_pos"];
    private _base = _pos nearObjects [OT_flag_IND,5];
    if((count _base) > 0) then {
        _base = _base#0;
        _base addAction ["Set As Home", {player setVariable ["home",getpos (_this select 0),true];"This FOB is now your home" call OT_fnc_notifyMinor},nil,0,false,true];
    };
}foreach(server getVariable ["bases",[]]);
/*
funcProcessDiaryLink = {
    processDiaryLink createDiaryLink ["Tutorial", _this, ""];
};

// <img image='\overthrow_main\flags\example1.paa'width='100' height='100' />
tutorialDiary1 = player createDiarySubject ["Tutorial","OT - Martial Law"];

tutorialDiary2 = player createDiaryRecord ["Tutorial", ["Gendarmerie","
	<font size='12' face='PuristaMedium'>A gendarmerie or gendarmery is a military component with jurisdiction in civil law enforcement.
	The term gendarme is derived from the medieval French expression gens d'armes, which translates to ""armed people"".
	In Overthrow, NATO will station gendarmerie in towns they control to keep the peace and stop any illegal activity,
	they can be spotted wearing blue uniforms. If those are killed, stability will drop in the town and more will be sent from the closest base.
	If there is no base with land access to the town then Stability will drop quickly. If the base is close enough they will walk,
	otherwise they will be sent in an offroad. The gendarmerie do not need to be physically in a town for stability to drop,
	if you kill them in transit it will still count for the town they are heading to. Killing gendarmerie will also drop your local standing
"]];

tutorialDiary3 = player createDiaryRecord ["Tutorial", ["Capturing a Town","
	<font size='12' face='PuristaMedium'>Inorder to capture a town you must drop its stability to 0,
	this can be done by completing a number of unsavoury activities such as selling drugs to civilians,killing police and NATO soldiers,
	and completing certain jobs. (Keep in mind some activities may raise the stability of a town, mainly the bulk selling of needed goods.).<br></br><br></br>

	Once the stability hits 0, the town will enter “anarchy” and NATO will react by either abandoning it, leaving you free to return order as you please,
	or launch an attack to claim it back and restore order. It's important to note NATO will only choose to abandon towns with tiny populations.
	Another key detail is that the size of NATO’s assault is based off the size of the town, and its distance from NATO outposts, so for your first takeover,
	its wise to choose a village somewhere remote.<br></br><br></br>Assuming NATO didn't choose to abandon the town,
	you will receive a 10 minute notice prior to the sidge where NATO wont send any further troops to the town and will instead be moving units into position to assault.
	Because of this, the short break offers a key opportunity to place HMG nests, mine roads (NATO tends to attack from the direction of the closest bases),
	and lay other guerilla traps that will greatly increase your chances against the overwhelming and superior troops that NATO has to offer.<br></br><br></br>

	Once the battle starts the timer will transform into a percentage marker, showing the resistance which side of the conflict is winning. If it's green, you're winning,
	if it's blue then NATO is winning. Inorder to gain score you must have more troops within a certain range of the town then NATO.
	If the marker hits 100% for NATO or the battle ends in a stalemate (which occurred after a large amount of time passes) you’ll lose the fight and the town's stability
	will reset and the occupying military force will remain for some time. Obviously the opposite is true for you and if the marker hits 100% on your side,
	the town will remain in anarchy and NATO will leave it be for a large period of time (later in the game they will have the option to attempt to recapture it.) .<br></br><br></br>

	Once the town is anarchy, you're granted the chance to move in and gain favour to get overship over the locale. Inorder to do this you must raise its
	stability over 50% then the people will flip to your side and the town will be marked with a green circle around it. There are two main ways to do this,
	either destroy gangs that pop up around the place or build a police station and have the officers slowly restore law. Once you finally gain the town you
	can look forward to a sizable amount of tax income and influence every 6 months from the residence of the place.
"]];

tutorialDiary4 = player createDiaryRecord ["Tutorial", ["Getting Started","
	<font size='12' face='PuristaMedium'>Welcome to Overthrow - Martial Law, where YOU are the resistance!<br></br><br></br>
	<font size='10' face='PuristaMedium'>There is no set way to play Overthrow, everything can be done multiple ways and you will not be given instructions at every turn,
	this can of course be quite daunting at first so here are some basic tips to give you some ideas.<br></br>

	<font size='10' face='PuristaMedium'>The Y Menu<br></br><br></br>

	<font size='10' face='PuristaMedium'>Most actions in Overthrow can be done by pressing the ""Y"" key on your keyboard. This menu is context sensitive and will change depending on if you are:<br></br>In a vehicle<br></br>Have recruits selected<br></br>Are near certain buildings such as the Workshop<br></br><br></br></font><font face='PuristaBold'>Background</font><font face='PuristaMedium'>NATO is currently occupying the nation and is in a heightened state after an assassination of a local grass-roots political figure just last night. Tensions are high as the public begins to question when the occupation of NATO forces will end and a local government is voted into power. <execute expression='tutorialDiary4 call funcProcessDiaryLink'>Gendarmerie</execute> forces are stationed in towns to try and keep the peace but random gunfire has broken out in some smaller towns. Therefore if any illegal activity or weapons are spotted by NATO they have orders to use maximum force. Be extremely careful to not brandish weapons around them or commit illegal acts unless you are prepared to fight.<br></br><br></br>Being seen and wanted<br></br>In the top right of your screen underneath your current money there will show a blue pair of eyes when NATO can currently see you, be careful what you do when that is showing. If they see anything suspicious you will get a ""WANTED"" text appear underneath signifying it's time to run, hide, or fight back! You will not receive a warning, NATO will shoot first and not bother asking questions.
"]];
*/

[] call OT_fnc_setupPlayer;
_introcam cameraEffect ["Terminate", "BACK" ];
camDestroy _introcam;
