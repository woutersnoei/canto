(
e.faderAuto = Order();
e.faderAutoEnabled = true;
e.faderAutoWaitTime = 0.5;

e.actions[ \touch ][ \all ] = { |sl,val,i|
	//[ val, i, Process.elapsedTime ].postln;
	if( e.faderAuto[ i ].isNil ) {
		e.faderAuto[ i ] = ();
	};
	if( val.asInt == 1 ) { // touch down
		if( e.faderAuto[i].task.isNil or: { e.faderAuto[i].task.isPlaying.not } ) {
			if( e.faderAuto[i].lastClick.isNil ) {
				e.faderAuto[i].lastClick = Process.elapsedTime;
			} {
				if( (Process.elapsedTime - e.faderAuto[i].lastClick)
					.inclusivelyBetween(0.2, e.faderAutoWaitTime).not ) {
					e.faderAuto[i].lastClick = Process.elapsedTime; // ignore
				} {
					// start recording
					e.faderAuto[i].lastClick = nil;
					e.faderAuto[i].timeValuePairs = [];
					e.faderAuto[i].recording = true;
					"recording %\n".postf( i );
				}
			};
		} {
			e.faderAuto[i].task.stop;
			e.faderAuto[i].task = nil;
			e.faderAuto[i].lastClick = nil;
		};
	} { // touch up
		if( e.faderAuto[i].recording == true ) {
			e.faderAuto[i].recording = false;
			"ended recording %\n".postf( i );
			e.faderAuto[i].task.stop;
			if( e.faderAuto[i].timeValuePairs.size > 0 ) {
				e.faderAuto[i].task = Task({
					var lastTime;
					loop {
						lastTime = e.faderAuto[i].timeValuePairs[0];
						e.faderAuto[i].timeValuePairs.pairsDo({ |time, value|
							(time - lastTime).wait;
							lastTime = time;
							e.sliders[i].valueAction = value;
						});
					};
				}).start;
				"started playing %\n".postf( i );
			} {
				e.faderAuto[i].task = nil;
			};
		};
	};
};

e.actions.slider[ \all ] = { |sl, i|
	if( e.faderAutoEnabled == true ) {	
		if( e.faderAuto[i].notNil && { e.faderAuto[i].recording == true }) {
			e.faderAuto[i].timeValuePairs = e.faderAuto[i].timeValuePairs
				.addAll( [ Process.elapsedTime, sl.value ] );
		};
	};
};
)