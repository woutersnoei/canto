NanoKONTROL();

~canto.amp = 0.0!14;

~canto.sharpness = 16.5!14;

~canto.nanoLastChecked = thisThread.seconds!8;

~canto.hpfCtrl.remove;
~canto.hpfCtrl = SimpleController( ~canto.hpf );

~canto.noteDurCtrl.remove;
~canto.noteDurCtrl = SimpleController( ~canto.noteDur );

([ 2, 3, 4, 5, 6, 7, 8, 9]+1).do({ |item, i|
	NanoKONTROL.sliders[0][i].action_({ |sl| 
		var now;
		~canto.amp[item] = \amp.asSpec.map(sl.value) * 0.1;
		now = thisThread.seconds;
		if( (now - ~canto.nanoLastChecked[i]) > 1 ) {
			"%: '%'\n".postf( i+1, ~canto.instruments[item] );
		};
		~canto.nanoLastChecked[i] = now;
	});
	NanoKONTROL.knobs[0][i].action_({ |sl| 
		~canto.sharpness[item] = sl.value.linlin(0,1,32,1);
	});
	NanoKONTROL.buttons[0][i].action_({ |bt| 
		if( bt.value.asInt == 1 ) {
			~canto.instruments[item] = ~canto.defNames.clipAt( 
			 	~canto.defNames.indexOf( ~canto.instruments[item] ) + 1
			 );
			 "% to '%'\n".postf( i+1, ~canto.instruments[item] );
		};
	});
	NanoKONTROL.buttons[0][i+9].action_({ |bt| 
		if( bt.value.asInt == 1 ) {
			~canto.instruments[item] = ~canto.defNames.clipAt( 
			 	~canto.defNames.indexOf( ~canto.instruments[item] ) - 1
			 );
			 "% to '%'\n".postf( i+1, ~canto.instruments[item] );
		};
	});
	
	/*
	e.actions.slider[i+16] = { |sl| ~canto.hpf[ item ] = sl.value.linexp(0,1,20,2000) };
	~canto.hpfCtrl.put( item, { 
			e.active = false;
			e.sliders[i+16].valueAction = ~canto.hpf[ item ].explin(20,2000,0,1);
			e.active = true;
	});
	
	e.actions.knob[i+16] = { |sl| 
		~canto.noteDur[ item ] = sl.value.linlin(0,1,0,2).max(1/5).round(1/5);
	};
	~canto.noteDurCtrl.put( item, { 
			e.active = false;
			e.knobs[i+16].valueAction = ~canto.noteDur[ item ].linlin(0,2,0,1);			e.active = true;
	});
	e.buttons.rec[i+16].valueAction = 1;
	*/
	
});

// verb on slider 9
NanoKONTROL.sliders[0][8].action_({ |sl| 
	q.verb.views.amp.valueAction = sl.value;
});	

// mod on knob 9
NanoKONTROL.knobs[0][8].action_({ |sl| 
	~canto.mod = sl.value!13;
});	

// set panning mode
NanoKONTROL.buttons[0][8].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			 ~canto.setFastPan;
		}
	);
};

NanoKONTROL.buttons[0][17].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			 ~canto.setSlowPan;
		}
	);
};


NanoKONTROL.buttons[0][19].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			~canto.start;
		}
	);
};

NanoKONTROL.buttons[0][20].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			 ~canto.currentIndex = (~canto.currentIndex + 1).wrap( 0, ~canto.cells.size );
		}
	);
};

NanoKONTROL.buttons[0][18].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			 ~canto.currentIndex = (~canto.currentIndex - 1).wrap( 0, ~canto.cells.size );
		}
	);
};

NanoKONTROL.buttons[0][22].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			~canto.end;
		}
	);
};

NanoKONTROL.buttons[0][21].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			~canto.setSlowChange;
		}
	);
};

NanoKONTROL.buttons[0][23].action = { |bt| 
	switch( bt.value.asInt,
		1, { 
			~canto.setFastChange;
		}
	);
};

// tempo via buttons
e.buttons.rec[15].valueAction = 1;
e.buttons.solo[15].valueAction = 1;
e.buttons.on[15].valueAction = 1;
// e.actions.slider[15] = { |sl| TempoClock.tempo = sl.value.linlin(0,1,50,70).round(0.1)/60 };
e.actions.slider[15] = nil;
e.actions.button.on[15] = { |bt| 
	 if( bt.value == 0 ) {
		 TempoClock.tempo = (TempoClock.tempo + (0.1 / 60)).min( 70/60 );
	 };
	 bt.valueAction = 1;
};
e.actions.button.solo[15] = { |bt| 
	 if( bt.value == 0 ) {
		 TempoClock.tempo = (TempoClock.tempo - (0.1 / 60)).max( 50/60 );
	 };
	 bt.valueAction = 1;
};

~canto.tempoJack !? _.stop;
~canto.tempoJack = SkipJack( {
	e.active = false;
	e.sliders[15].valueAction = (TempoClock.tempo * 60).linlin(50,70,0,1);
	e.active = true;
} );