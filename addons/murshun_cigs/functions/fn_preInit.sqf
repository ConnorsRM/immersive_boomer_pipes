murshun_cigs_fnc_smoke = {
    params ["_unit", "_type"];

    private _multiplier = 1;

    switch (_type) do {
    case "cigarette": { _multiplier = 1 };
    case "cigar": { _multiplier = 2 };
	case "pipe": { _multiplier = 2.5 };
    };

    private _source = "logic" createVehicleLocal (getPos _unit);
    private _fog = "#particleSource" createVehicleLocal getPos _source;
    _fog setParticleParams ["\A3\data_f\cl_basic",
    "",
    "Billboard",
    0.5,
    2,
    [0, 0, 0],
    [0, 0.1, -0.1],
    1,
    1.2,
    1,
    0.1,
    [0.1 * _multiplier, 0.2 * _multiplier, 0.1 * _multiplier],
    [[0.2 * _multiplier, 0.2 * _multiplier, 0.2 * _multiplier, 0.3 * _multiplier], [0, 0, 0, 0.01], [1, 1, 1, 0]],
    [500],
    1,
    0.04,
    "",
    "",
    _source];
    _fog setParticleRandom [2, [0, 0, 0], [0.25, 0.25, 0.25], 0, 0.5, [0, 0, 0, 0.1], 0, 0, 10];
    _fog setDropInterval 0.005;

    _source attachTo [_unit, [0, 0.06, 0], "head"];

    sleep 0.4;

    deleteVehicle _source;
};

murshun_cigs_fnc_anim = {
    params ["_unit", "_gestureAnimation", "_playTimeSeconds"];

    if (!alive _unit) exitWith {};

    if (_unit getVariable ["ACE_isUnconscious", false]) exitWith {};

    // private _animation = animationState _unit;

    private _time = time;

    _unit forceWalk true;

    while {time < _time + _playTimeSeconds} do {
        _unit playActionNow _gestureAnimation;

        sleep (1/60);
    };

    _unit forceWalk false;

    if (alive _unit && !(_unit getVariable ["ACE_isUnconscious", false])) then {
        // [_unit, _animation] remoteExec ["switchMove"];
    };
};

murshun_cigs_removeItemFromMag = {
    params ["_player", "_mag"];

    private _matchesMags = magazinesAmmo _player select {_x select 0 == _mag};

    _player removeMagazineGlobal _mag;

    private _oldMag = _matchesMags select 0;

    if ((_oldMag select 1) > 1) then {
        _player addMagazine [_mag, (_oldMag select 1) - 1];
    } else {
        [format ["%1 is now empty.", getText (configFile >> "CfgMagazines" >> _mag >> "displayName")], 2.5, _player] spawn ace_common_fnc_displayTextStructured;
    };
};

murshun_cigs_playSound = {
    params ["_unit", "_class"];

    [_unit, _class] remoteExec ["say3D"];
};

murshun_cigs_fnc_useItem = {
    params ["_unit", "_player"];

    if (!("murshun_cigs_matches" in (magazines _player)) && !("murshun_cigs_lighter" in (magazines _player))) exitWith {
        [localize "STR_murshun_cigs_no_matches_or_lighter", 2.5, _player] spawn ace_common_fnc_displayTextStructured;
        false
    };

    switch (true) do {
    case ("murshun_cigs_lighter" in (magazines _player)): {
            [_player, "murshun_cigs_lighter"] call murshun_cigs_removeItemFromMag;

            [_unit, "murshun_cigs_lighter_01"] call murshun_cigs_playSound;
        };
    case ("murshun_cigs_matches" in (magazines _player)): {
            [_player, "murshun_cigs_matches"] call murshun_cigs_removeItemFromMag;

            [_unit, "murshun_cigs_matches_01"] call murshun_cigs_playSound;
        };
    };

    true
};

murshun_cigs_fnc_start_cig_your = {
    params ["_player"];

    if !([_player, _player] call murshun_cigs_fnc_useItem) exitWith {};

    [_player] spawn murshun_cigs_fnc_start_cig;
};

murshun_cigs_fnc_start_pipe_your = {
    params ["_player"];

    if !([_player, _player] call murshun_cigs_fnc_useItem) exitWith {};

    [_player] spawn murshun_cigs_fnc_start_pipe;
};

murshun_cigs_fnc_start_cig_their = {
    params ["_unit", "_player"];

    if !([_unit, _player] call murshun_cigs_fnc_useItem) exitWith {};

    _player playActionNow "PutDown";

    [_unit] remoteExec ["murshun_cigs_fnc_start_cig", _unit];
};

murshun_cigs_fnc_start_cig = {
    params ["_unit"];

    if (!(local _unit)) exitWith {};

    private _cigTime = 0;

    private _gogglesCurrent = goggles _unit;
    private _hmdCurrent = hmd _unit;

    private _cigTypeGear = "";

    if (_gogglesCurrent in murshun_cigs_cigsArray) then {
        _cigTypeGear = "GOGGLES";
    };

    if (_hmdCurrent in murshun_cigs_cigsArray) then {
        _cigTypeGear = "HMD";
    };

    if (_cigTypeGear == "") exitWith {};

    private _cigClass = configFile;

    switch (_cigTypeGear) do {
        case ("GOGGLES"): {
            _cigClass = configFile >> "CfgGlasses" >> _gogglesCurrent;
        };
        case ("HMD"): {
            _cigClass = configFile >> "CfgWeapons" >> _hmdCurrent;
        };
    };

    _cigTime = getNumber (_cigClass >> "immersion_cigs_initStateTime");

    if (_unit getVariable ["murshun_cigs_cigLitUp", false]) exitWith {};
    _unit setVariable ["murshun_cigs_cigLitUp", true, true];

    [_unit, "immersion_cigs_cig_in", 3] spawn murshun_cigs_fnc_anim;

    private _cigType = getText (_cigClass >> "immersion_cigs_type");

    sleep (3.5 + random 2);
    [_unit, _cigType] remoteExec ["murshun_cigs_fnc_smoke"];
    sleep (1 + random 1);
    [_unit, _cigType] remoteExec ["murshun_cigs_fnc_smoke"];

    private _maxTime = getNumber (_cigClass >> "immersion_cigs_maxTime");

    if (_maxTime == 0) then {
        _maxTime = 330;
    };

    while ({true}) do {
        switch (_cigTypeGear) do {
            case ("GOGGLES"): {
                _gogglesCurrent = goggles _unit;
                _cigClass = configFile >> "CfgGlasses" >> _gogglesCurrent;
            };
            case ("HMD"): {
                _hmdCurrent = hmd _unit;
                _cigClass = configFile >> "CfgWeapons" >> _hmdCurrent;
            };
        };

        private _gogglesNew = "";

        _nextCigState = getText (_cigClass >> "immersion_cigs_nextState");

        private _nextCigStateTime = 0;

        switch (_cigTypeGear) do {
            case ("GOGGLES"): {
                _nextCigStateTime = getNumber (configFile >> "CfgGlasses" >> _nextCigState >> "immersion_cigs_initStateTime");
            };
            case ("HMD"): {
                _nextCigStateTime = getNumber (configFile >> "CfgWeapons" >> _nextCigState >> "immersion_cigs_initStateTime");
            };
        };

        if (_cigTime >= _nextCigStateTime) then {
            _gogglesNew = _nextCigState;
        };

        if (_gogglesNew != "") then {
            switch (_cigTypeGear) do {
                case ("GOGGLES"): {
                    removeGoggles _unit;
                    _unit addGoggles _gogglesNew;
                };
                case ("HMD"): {
                    _unit removeWeapon _hmdCurrent;
                    _unit addWeapon _gogglesNew;
                };
            };

            _gogglesCurrent = _gogglesNew;
            _hmdCurrent = _gogglesNew;
        };

        private _time = (5.5 + random 2);

        _cigTime = _cigTime + _time;

        [_unit, _cigType] remoteExec ["murshun_cigs_fnc_smoke"];
        _unit setFatigue (getFatigue _unit + 0.01);

        private _timeToSleep = time + _time;

        private _shouldExitLoop = false;

        waitUntil {
            if (!(alive _unit && (_gogglesCurrent in murshun_cigs_cigsArray || _hmdCurrent in murshun_cigs_cigsArray) && (_unit getVariable ["murshun_cigs_cigLitUp", false]) && _cigTime <= _maxTime)) exitWith {
                _shouldExitLoop = true;

                true
            };

            if (_cigTypeGear == "GOGGLES" && _gogglesCurrent != goggles _unit) exitWith {
                _shouldExitLoop = true;

                true
            };

            if (_cigTypeGear == "HMD" && _hmdCurrent != hmd _unit) exitWith {
                _shouldExitLoop = true;

                true
            };

            time > _timeToSleep
        };

        if (_shouldExitLoop) exitWith {};
    };

    [_unit, "immersion_cigs_cig_out", 1] spawn murshun_cigs_fnc_anim;

    _unit setVariable ["murshun_cigs_cigLitUp", false, true];

    if (_cigTime >= _maxTime) then {
        switch (_cigTypeGear) do {
            case ("GOGGLES"): {
                removeGoggles _unit;
            };
            case ("HMD"): {
                _unit removeWeapon (hmd _unit);
            };
        };
    };
};

murshun_cigs_fnc_start_pipe = {
	params ["_unit"];
	if (!(local _unit)) exitWith {};
	
	private _pipeType = [_unit, false] call immersion_cigs_getPipeType;
	if(_pipeType == MURSHUN_CIGS_PIPE_INVALID) exitWith {};	
	
	private _pipeClass = [_unit, _pipeType] call immersion_cigs_getPipeClass;
	
	//get pipe time		
	if (_unit getVariable ["murshun_cigs_cigLitUp", false]) exitWith {};
	_unit setVariable ["murshun_cigs_cigLitUp", true, true];	
	
	//play light anim
	[_unit, "immersion_cigs_cig_in", 3] spawn murshun_cigs_fnc_anim;	
	
	//setup smoke loop
	private _smokeType = getText (_pipeClass >> "immersion_cigs_type");
	[_unit, _smokeType] remoteExec ["murshun_cigs_fnc_smoke"];
	sleep (1 + random 1);
	[_unit, _smokeType] remoteExec ["murshun_cigs_fnc_smoke"];
	
	private _stateTime = getNumber (_pipeClass >> "immersion_cigs_initStateTime");	
	private _stateMaxTime = getNumber (_pipeClass >> "immersion_cigs_maxTime");
	if (_stateMaxTime == 0) then {
		_stateMaxTime = 500;
	};
	
	//state update loop
	while ({true}) do {				
		//ensure type/class up to date to hand changes during sleep
		_pipeType = [_unit, false] call immersion_cigs_getPipeType;
		if(_pipeType == MURSHUN_CIGS_PIPE_INVALID) exitWith {};		
		_pipeClass = [_unit, _pipeType] call immersion_cigs_getPipeClass;
		
		//check next state and check for transition	
		_nextState = getText (_pipeClass >> "immersion_cigs_nextState");	
		
		private _nextStateTime = -1;
		switch(_pipeType) do {
			case (MURSHUN_CIGS_PIPE_GOGGLES): {				
				_nextStateTime = getNumber (configFile >> "CfgGlasses" >> _nextState >> "immersion_cigs_initStateTime");
			};
			case (MURSHUN_CIGS_PIPE_HMD): {
				_nextStateTime = getNumber (configFile >> "CfgWeapons" >> _nextState >> "immersion_cigs_initStateTime");
			};
		};
		
		if(_nextStateTime == -1) exitWith {};
		
		//if time exceeded threshold for next state, transition
		if (_stateTime >= _nextStateTime) then {
			if(_nextState != "") then {
				switch(_pipeType) do {
					case (MURSHUN_CIGS_PIPE_GOGGLES): {
						removeGoggles _unit;
						_unit addGoggles _nextState;
						_pipeClass = (configFile >> "CfgGlasses" >> _nextState);
					};
					case (MURSHUN_CIGS_PIPE_HMD): {
						_hmdCurrent = hmd _unit;
						_unit removeWeapon _hmdCurrent;
						_unit addWeapon _nextState;
						_pipeClass = (configFile >> "CfgWeapons" >> _nextState);
					};
				};				
			};
        };
		
		private _time = (5.5 + random 2);
		_stateTime = _stateTime + _time;
		hint (str _stateTime);
		
		//add fatigue, not sure why- but keep parity with cigs. _shrug_
		[_unit, _smokeType] remoteExec ["murshun_cigs_fnc_smoke"];
        _unit setFatigue (getFatigue _unit + 0.01);

		private _sleepTimer = time + _time;
		private _abortLoop = false;
		
		//detect smoke end states and flag update loop for abort1
		waitUntil {
			//if pipe class invalid, smoke terminated and state time below threshold. 
			if (!(alive _unit && (((configName _pipeClass) in murshun_cigs_pipePackedArr) || ((configName _pipeClass) in murshun_cigs_pipeLitArr)) && (_unit getVariable ["murshun_cigs_cigLitUp", false]) && _stateTime <= _stateMaxTime)) exitWith {
                _abortLoop = true;					
                true
			};
			
			//if they chucked their pipe
			if(_pipeType == MURSHUN_CIGS_PIPE_GOGGLES) then {
				if ((configName _pipeClass) != (goggles _unit)) exitWith {
					_abortLoop = true;
					true
				};
			};
			if(_pipeType == MURSHUN_CIGS_PIPE_HMD) then {				
				if ((configName _pipeClass) != (hmd _unit)) exitWith {
					_abortLoop = true;
					true
				};
			};
			
			//sleep time expired			
			time > _sleepTimer;
		};	
		
		if (_abortLoop) exitWith {};
	};
	
	//Smoking time is over	
	_unit setVariable ["murshun_cigs_cigLitUp", false, true];
	
	//if we reached pipe lifetime, replace with ashed
	if (_stateTime >= _stateMaxTime) then {				
		switch (_pipeType) do {
            case (MURSHUN_CIGS_PIPE_GOGGLES): {
				removeGoggles _unit;				
				_unit addGoggles "murshun_cigs_pipeashed";								
            };
            case (MURSHUN_CIGS_PIPE_HMD): {
				_unit removeWeapon (hmd _unit);				
				_unit addWeapon "murshun_cigs_pipeashed_nv";				
			};
		}
    };
};

murshun_cigs_fnc_stop_cig = {
    params ["_player"];

    _player setVariable ["murshun_cigs_cigLitUp", false, true];
};

murshun_cigs_fnc_stop_pipe = {
    params ["_player"];

    _player setVariable ["murshun_cigs_pipeLitUp", false, true];
};

murshun_cigs_fnc_pack_pipe = {
    params ["_player"];	
	if (!(local _player)) exitWith {};	
	
	private _pipeType = [_player, true] call immersion_cigs_getPipeType;
	
	//if not found, return no op	
	if(_pipeType == MURSHUN_CIGS_PIPE_INVALID) exitWith {};
	
	private _pipeClass = [_player, _pipeType] call immersion_cigs_getPipeClass;		
	
	//drill into packedstate
	private _packedState = "";
	_packedState = getText (_pipeClass >> "immersion_cigs_packedState");	
	hint (_packedState);
	if(_packedState != "") then {
		//everything as it should be
		//remove tobacco, change pipe to packed	
		_player removeItem "murshun_cigs_tobacco";
		
		switch (_pipeType) do {
			case (MURSHUN_CIGS_PIPE_GOGGLES): {
				removeGoggles _player;
				_player addGoggles _packedState;
			};
			case (MURSHUN_CIGS_PIPE_HMD): {
				private _hmdCurrent = hmd _player;	
				_player removeWeapon _hmdCurrent;
				_player addWeapon _packedState;
			};
		};
	};
};

murshun_cigs_fnc_dump_pipe = {
	params ["_player"];	
	if (!(local _player)) exitWith {};
	
	private _gogglesCurrent = goggles _player;
    private _hmdCurrent = hmd _player;	
	private _eqPipe = configFile;
	private _isNVG = false;
	
	//if hmd or googles packed or ashed dump
	if((_gogglesCurrent in murshun_cigs_pipePackedArr) || (_gogglesCurrent in murshun_cigs_pipeAshedArr )) then {
		_eqPipe = configFile >> "CfgGlasses" >> _gogglesCurrent;		
	};
	
	if((_hmdCurrent in murshun_cigs_pipePackedArr) || (_hmdCurrent in murshun_cigs_pipeAshedArr )) then {
		_isNVG = true;
		_eqPipe = configFile >> "CfgWeapons" >> _hmdCurrent;		
	};		
	
	private _emptyState = getText (_eqPipe >> "immersion_cigs_emptyState");		
	
	if(_emptyState != "") then {		
		if(_isNVG) then {			
			_player removeWeapon _hmdCurrent;
			_player addWeapon _emptyState;	
		} else {
			removeGoggles _player;
			_player addGoggles _emptyState;							
		};	
	};
};

murshun_cigs_fnc_take_cig_from_pack = {
    params ["_player"];

    [_player, "murshun_cigs_cigpack"] call murshun_cigs_removeItemFromMag;

    [_player, "murshun_cigs_unwrap"] call murshun_cigs_playSound;

    if (goggles _player == "") then {
        _player addItem "murshun_cigs_cig0";
    } else {
        if (hmd _player == "") then {
            _player addItem "murshun_cigs_cig0_nv";
        } else {
            _player addItem "murshun_cigs_cig0";
        };
    };
};

murshun_cigs_fnc_take_tobacco_from_tin = {
	params ["_player"];
	
	[_player, "murshun_cigs_tobaccotin"] call murshun_cigs_removeItemFromMag;
	
	//TODO replace with a sound that doesn't suck ass.
	[_player, "murshun_cigs_unwrap"] call murshun_cigs_playSound;
	_player addItem "murshun_cigs_tobacco";
};

if !(isClass (configFile >> "CfgPatches" >> "ace_common")) then {
    ace_common_fnc_displayTextStructured = {
        params ["_string"];

        hintSilent _string;
    };
};

if (isNil "immersion_cigs_giveItemsInSP") then {
    immersion_cigs_giveItemsInSP = true;
};
//enum for pipe types
MURSHUN_CIGS_PIPE_INVALID = -1;
MURSHUN_CIGS_PIPE_GOGGLES = 1;
MURSHUN_CIGS_PIPE_HMD = 2;

murshun_cigs_cigsArray = ["EWK_Cigar1", "EWK_Cigar2", "EWK_Cig1", "EWK_Cig2", "EWK_Cig3", "EWK_Cig4", "EWK_Glasses_Cig1", "EWK_Glasses_Cig2", "EWK_Glasses_Cig3", "EWK_Glasses_Cig4", "EWK_Glasses_Shemag_GRE_Cig6", "EWK_Glasses_Shemag_NB_Cig6", "EWK_Glasses_Shemag_tan_Cig6", "EWK_Cig5", "EWK_Glasses_Cig5", "EWK_Cig6", "EWK_Glasses_Cig6", "EWK_Shemag_GRE_Cig6", "EWK_Shemag_NB_Cig6", "EWK_Shemag_tan_Cig6"] + (("getNumber (_x >> 'immersion_cigs_isCig') == 1" configClasses (configFile >> "CfgGlasses")) apply {configName _x}) + (("getNumber (_x >> 'immersion_cigs_isCig') == 1" configClasses (configFile >> "CfgWeapons")) apply {configName _x});
murshun_cigs_pipePackedArr = ["murshun_cigs_pipepacked_nv", "murshun_cigs_pipepacked"];
murshun_cigs_pipeLitArr = ["murshun_cigs_pipelit_nv", "murshun_cigs_pipelit"];
murshun_cigs_pipeAshedArr = ["murshun_cigs_pipeashed_nv", "murshun_cigs_pipeashed"];
murshun_cigs_pipeEmptyArr = ["murshun_cigs_pipeempty_nv", "murshun_cigs_pipeempty"];



immersion_cigs_canStartSmoking = {
    params ["_unit"];

    (((goggles _unit) in murshun_cigs_cigsArray) || ((hmd _unit) in murshun_cigs_cigsArray)) && !(_unit getVariable ['murshun_cigs_cigLitUp', false]) && !(_unit getVariable ['murshun_cigs_pipeLitUp', false])
};

immersion_cigs_canStopSmoking = {
    params ["_unit"];

    (((goggles _unit) in murshun_cigs_cigsArray) || ((hmd _unit) in murshun_cigs_cigsArray)) && (_unit getVariable ['murshun_cigs_cigLitUp', false])
};

immersion_cigs_canStartPipe = {
    params ["_unit"];

    (((goggles _unit) in murshun_cigs_pipePackedArr) || ((hmd _unit) in murshun_cigs_pipePackedArr)) && !(_unit getVariable ['murshun_cigs_cigLitUp', false]) && !(_unit getVariable ['murshun_cigs_pipeLitUp', false])
};

immersion_cigs_canDumpPipe = {
    params ["_unit"];
	
	(((goggles _unit) in murshun_cigs_pipeAshedArr) || ((hmd _unit) in murshun_cigs_pipeAshedArr) || ((goggles _unit) in murshun_cigs_pipePackedArr) || ((hmd _unit) in murshun_cigs_pipePackedArr)) && !(_unit getVariable ['murshun_cigs_cigLitUp', false]) && !(_unit getVariable ['murshun_cigs_pipeLitUp', false])
};

immersion_cigs_canStopPipe = {
    params ["_unit"];

    (((goggles _unit) in murshun_cigs_pipeLitArr) || ((hmd _unit) in murshun_cigs_pipeLitArr)) && (_unit getVariable ['murshun_cigs_pipeLitUp', false])
};

immersion_cigs_canTakeCigFromPack = {
    params ["_unit"];

    "murshun_cigs_cigpack" in (magazines _unit)
};

immersion_cigs_canTakeTobaccoFromTin = {
    params ["_unit"];

    "murshun_cigs_tobaccotin" in (magazines _unit)
};

immersion_cigs_canPackPipe = {
	params ["_unit"];
	_items = items _unit;
	(((goggles _unit) in murshun_cigs_pipeEmptyArr) || ((hmd _unit) in murshun_cigs_pipeEmptyArr)) && ("murshun_cigs_tobacco" in _items)	
};

immersion_cigs_getPipeType =
{
	params ["_unit", "_isEmpty"];
	
	private _equippedGoogles = goggles _unit;
    private _equippedHmd = hmd _unit;
	private _type = MURSHUN_CIGS_PIPE_INVALID;
	
	//Lookup current eq'ed pipe for class lookup
	//no need for string comp, here's an 'enum'	
	if(_isEmpty) then {
	    if ((_equippedGoogles in murshun_cigs_pipeEmptyArr) || (_equippedGoogles in murshun_cigs_pipeAshedArr)) then {		
			_type = MURSHUN_CIGS_PIPE_GOGGLES;		
		};

		if ((_equippedHmd in murshun_cigs_pipeEmptyArr) || (_equippedHmd in murshun_cigs_pipeAshedArr)) then {		
			_type = MURSHUN_CIGS_PIPE_HMD;		
		};
	} else {
	    if ((_equippedGoogles in murshun_cigs_pipePackedArr) || (_equippedGoogles in murshun_cigs_pipeLitArr)) then {		
			_type = MURSHUN_CIGS_PIPE_GOGGLES;		
		};

		if ((_equippedHmd in murshun_cigs_pipePackedArr) || (_equippedHmd in murshun_cigs_pipeLitArr)) then {		
			_type = MURSHUN_CIGS_PIPE_HMD;		
		};
	};
	
	_type
};

immersion_cigs_getPipeClass = {
	params ["_unit", "_type"];
	private _equippedClass = configFile;
	
	switch(_type) do {
		case (MURSHUN_CIGS_PIPE_GOGGLES): {
			private _equippedGoggles = goggles _unit;
			_equippedClass = configFile >> "CfgGlasses" >> _equippedGoggles;
		};
		case (MURSHUN_CIGS_PIPE_HMD): {
			private _equippedHMD = hmd _unit;
			_equippedClass = configFile >> "CfgWeapons" >> _equippedHMD;
		};
	};
	
	_equippedClass
}
