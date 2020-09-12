closeDialog 0;
private ["_wpos","_wid"];
if (vehicle player != player) then {
	private _vehpos = getpos vehicle player;
	private _warehouse = _vehpos call OT_fnc_nearestWarehouse;
	_warehouse params ["_wpos","_wid"];
	OT_currentWarehouse = _wid;
	private _name = _wpos call OT_fnc_nearestTown;
	createDialog "OT_dialog_warehouse";
} else {
	createDialog "OT_dialog_warehouse";
};
call OT_fnc_refreshWarehouse;
lbSetCurSel [1500, 0];