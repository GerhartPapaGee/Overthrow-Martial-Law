if (!isServer || !OT_whTransferring) exitWith {};
OT_whTransferring = true;
params ["_warehouse","_cls","_num"];
private _ret = true;
private _d = _warehouse getVariable [format["%1",_cls],[_cls,0,[0]]];
if(_d isEqualType []) then {
	_d params ["","_in"];

	if(_num > _in || _num isEqualTo -1) then {
		_num = _in;
	};
	if(_num isEqualTo 0) then {_ret = false};

	private _newnum = _in - _num;
	if(_newnum > 0) then {
		_warehouse setVariable [format["warehouse-%1",_cls],[_cls,_newnum],true];
	}else{
		_warehouse setVariable [format["warehouse-%1",_cls],nil,true];
	};
}else{
	_ret = false;
	_warehouse setVariable [format["warehouse-%1",_cls],nil,true];
};
OT_whTransferring = false;
_ret
