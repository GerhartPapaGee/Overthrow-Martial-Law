private _pos = _this;
([(server getvariable ["NATOobjectives",[]]) + (server getvariable ["NATOcomms",[]]) + (server getVariable ["bases",[[]]]),[],{(_x select 0) distance _pos},"ASCEND"] call BIS_fnc_SortBy) select 0
