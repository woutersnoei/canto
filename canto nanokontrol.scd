NanoKONTROL();

~canto.amp = 0.0!14;

~canto.sharpness = 16.5!14;

([ 2, 3, 4, 5, 6, 7, 8, 9]+1).do({ |item, i|
	NanoKONTROL.sliders[0][i].action_({ |sl| 
		~canto.amp[item] = \amp.asSpec.map(sl.value) * 0.1;
	});
	NanoKONTROL.knobs[0][i].action_({ |sl| 
		~canto.sharpness[item] = sl.value.linlin(0,1,32,1);
	});
	NanoKONTROL.buttons[0][i].action_({ |bt| 
		if( bt.value.asInt == 1 ) {
			~canto.instruments[item] = ~canto.defNames.clipAt( 
			 	~canto.defNames.indexOf( ~canto.instruments[item] ) + 1
			 );
		};
	});
	NanoKONTROL.buttons[0][i+9].action_({ |bt| 
		if( bt.value.asInt == 1 ) {
			~canto.instruments[item] = ~canto.defNames.clipAt( 
			 	~canto.defNames.indexOf( ~canto.instruments[item] ) - 1
			 );
		};
	});
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