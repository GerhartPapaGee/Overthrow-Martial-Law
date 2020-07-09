// Assault Position/Building
// version 1.41
// by nkenny

// init
params ["_unit",["_target",objNull],["_range",30]];

// check if stopped 
//if (!(_unit checkAIFeature "PATH") || {!(_unit checkAIFeature "MOVE")}) exitWith {};
if (stopped _unit || {!(attackEnabled _unit)}) exitWith {false};

// settings
_unit setUnitPosWeak "UP";

// Near buildings + sort near positions + add target actual location
_buildings = [_target,_range,true,true] call lambs_danger_fnc_nearBuildings;
_buildings pushBack (getPosATL _target);
_buildings = _buildings select {_x distance2d _target < (4 + random 3)};    // adds more fuzziness

// exit without buildings? -- Assault or delay!
if (count _buildings < 2 || {random 1 > 0.8}) exitWith {

    // Outdoors or indoors with 20% chance to move out
    if (!(_unit call lambs_danger_fnc_indoor) || {random 1 > 0.8}) then {

    // execute move
    _unit doMove (_unit getHideFrom _target);

    // debug
    if (lambs_danger_debug_functions) then {systemchat format ["%1 assaulting position (%2m)",side _unit,round (_unit distance2d _target)];};
    };
};

// execute move 
_unit doMove ((selectRandom _buildings) vectorAdd [0.7 - random 1.4,0.7 - random 1.4,0]);

// debug
if (lambs_danger_debug_functions) then {systemchat format ["%1 checking buildings (%2m)",side _unit,round (_unit distance2d _target)];};
 
// end
true