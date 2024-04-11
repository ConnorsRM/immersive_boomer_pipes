if (!hasInterface) exitWith {};

private _addVanillaActions = {
        player addAction [localize "STR_murshun_cigs_start_cig", {
            params ["_target", "_caller"];
            [_caller] spawn murshun_cigs_fnc_start_cig_your
        }, nil, 0, false, true, "", "if (_target != player) exitWith {false}; [_this] call immersion_cigs_canStartSmoking", 5, false];
        player addAction [localize "STR_murshun_cigs_stop_cig", {
            params ["_target", "_caller"];
            [_caller] spawn murshun_cigs_fnc_stop_cig
        }, nil, 0, false, true, "", "if (_target != player) exitWith {false}; [_this] call immersion_cigs_canStopSmoking", 5, false];
        player addAction [localize "STR_murshun_cigs_take_cig_from_pack", {
            params ["_target", "_caller"];
            [_caller] spawn murshun_cigs_fnc_take_cig_from_pack
        }, nil, 0, false, true, "", "if (_target != player) exitWith {false}; 'murshun_cigs_cigpack' in (magazineCargo uniformContainer player) || 'murshun_cigs_cigpack' in (magazineCargo vestContainer player)", 5, false];
        player addAction [localize "STR_murshun_cigs_start_someones_cig", {
            params ["_target", "_caller"];
            [cursorObject, _caller] spawn murshun_cigs_fnc_start_cig_their
        }, nil, 0, false, true, "", "if !(cursorObject isKindOf 'Man') exitWith {false}; ((goggles cursorObject) in murshun_cigs_cigsArray) && !(cursorObject getVariable ['murshun_cigs_cigLitUp', false]) && (alive cursorObject)", 5, false];
		player addAction [localize "STR_murshun_cigs_start_pipe", {
            params ["_target", "_caller"];
            [_caller] spawn murshun_cigs_fnc_start_pipe_your
        }, nil, 0, false, true, "", "if (_target != player) exitWith {false}; [_this] call immersion_cigs_canStartPipe", 5, false];
		player addAction [localize "STR_murshun_cigs_stop_stop", {
            params ["_target", "_caller"];
            [_caller] spawn murshun_cigs_fnc_stop_pipe
        }, nil, 0, false, true, "", "if (_target != player) exitWith {false}; [_this] call immersion_cigs_canStopPipe", 5, false];
		player addAction [localize "STR_murshun_cigs_take_tobacco_from_tin", {
            params ["_target", "_caller"];
            [_caller] spawn murshun_cigs_fnc_take_tobacco_from_tin
        }, nil, 0, false, true, "", "if (_target != player) exitWith {false}; 'murshun_cigs_tobaccotin' in (magazineCargo uniformContainer player) || 'murshun_cigs_tobaccotin' in (magazineCargo vestContainer player)", 5, false];
    };

if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    call _addVanillaActions;

    player addEventHandler ["Respawn", _addVanillaActions];
} else {
    private _action = ["murshun_cigs_start_someones_cig", localize "STR_murshun_cigs_start_someones_cig", "murshun_cigs\UI\light_cig.paa", {
        params ["_target", "_player"];
        [_target, _player] spawn murshun_cigs_fnc_start_cig_their
    }, {
        params ["_target", "_player"];
        ((goggles _target) in murshun_cigs_cigsArray) && !(_target getVariable ['murshun_cigs_cigLitUp', false]) && (alive _target)
    }] call ace_interact_menu_fnc_createAction;
    ["CAManBase", 0, ["ACE_Head"], _action, true] call ace_interact_menu_fnc_addActionToClass;
};

player addEventHandler ["Respawn", {
    player setVariable ["murshun_cigs_cigLitUp", false];
}];

player addEventHandler ["InventoryClosed", {
    params ["_unit", "_container"];

	//fast path, most frequent case. If not EQ in both slots, no chance for conflict.
	if((goggles _unit == "") || ( hmd _unit == "") ) exitWith {};

	//gross, wish there was just else if statements.
    if (goggles _unit in murshun_cigs_cigsArray && hmd _unit in murshun_cigs_cigsArray) then {
        _unit addItem (hmd _unit);

        _unit unlinkItem (hmd _unit);		
    } else {
		if (goggles _unit in murshun_cigs_pipeEmptyArr && hmd _unit in murshun_cigs_pipeEmptyArr) then {
			_unit addItem (hmd _unit);

			_unit unlinkItem (hmd _unit);
		}
		else {
			if (goggles _unit in murshun_cigs_pipepacked_nv && hmd _unit in murshun_cigs_pipepacked_nv) then {
				_unit addItem (hmd _unit);

				_unit unlinkItem (hmd _unit);
			}
			else {
				if (goggles _unit in murshun_cigs_pipeAshedArr && hmd _unit in murshun_cigs_pipeAshedArr) then {
					_unit addItem (hmd _unit);

					_unit unlinkItem (hmd _unit);
				}
				else {
					if (goggles _unit in murshun_cigs_pipeLitArr && hmd _unit in murshun_cigs_pipeLitArr) then {
						_unit addItem (hmd _unit);

						_unit unlinkItem (hmd _unit);
					};
				};
			};
		};
	};	
	
}];

if (!isMultiplayer && !is3DENPreview && immersion_cigs_giveItemsInSP) then {
    player addItem "murshun_cigs_cigpack";
    player addItem "murshun_cigs_lighter";
};
