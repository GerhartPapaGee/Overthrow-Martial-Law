diag_log format ["nearestRealEstate params:%1", _this];
private ["_buildings","_building","_gotbuilding","_price","_lease","_sell","_totaloccupants"];

private _buildings =  _this nearObjects ["Building",15];
private _gotbuilding = false;
private _building = objNULL;

private _sorted = [_buildings,[_this],{_x distance _input0},"ASCEND"] call BIS_fnc_SortBy;

if(!isNil "modeTarget") then {
	_sorted = _sorted - [modeTarget];
};

{
	if ((typeof _x) in (OT_allBuyableBuildings+OT_allBuildableBuildings+OT_allRepairableRuins+OT_allRepairableBuildings+OT_garrisonBuildings)) exitWith {
		_building = _x;
		_gotbuilding = true;
	};
}foreach(_sorted);
_ret = false;
if(_gotbuilding) then {
	_ret = _building call OT_fnc_getRealEstateData;
	_ret = [_building,_ret select 0,_ret select 1,_ret select 2,_ret select 3];
	if((_ret select 1) isEqualTo -1) then {_ret = false};
};
_ret
