(

~canto = ~canto ? EM();

~canto.clicks = ~canto.clicks ? EM();

~canto.clicks.spd = 2;

~canto.clicks.amp = 0.2;
~canto.clicks.modSpeed = 0.1;
~canto.clicks.pan = 1;
~canto.clicks.freq = [20, 2000];
~canto.clicks.filter = [50,20000];
~canto.clicks.res = 0.05;

~canto.clicks.notes = { 64.rand }!8;

#[ amp, modSpeed, pan, filter, freq, res, notes ].do({ |item|
	~canto.clicks[ item.asSetter ] = { |evt, value|
		if( value.notNil ) {
			evt[ item ] = value;
			evt.synth.set( item, value );
		};
	};
});

/*
~canto.clicks[ \freq_ ] = { |evt, value = #[20,4000]|
	evt[ \freq ] = value;
	evt.synth.set( \minFreq, value[0], \maxFreq, value[1] );
};
*/


~canto.clicks[ \spd_ ] = { |evt, value = 2|
	evt[ \spd ] = value;
	evt.synth.set( \spds, TempoClock.tempo * 60 * ( (..3) + value ) );
};

~canto.clicks.start = { |evt, clear = false|
	if( clear ) { evt.end };
	if( evt.synth.isNil or: { evt.sn.isRunning.not }) {
		evt.synth = Synth( "canto_clicks", 
			evt.getPairs( #[ amp, modSpeed, pan, freq, filter, res, notes ] ) ++
			[ \spds, TempoClock.tempo * 60 * ( (..3) + evt[ \spd ] ) ] 
		).register;
	};
};

~canto.clicks.end = { |evt|
	evt.synth.release;
	evt.synth = nil;
};

(
~canto.clicks.iconnect = { |evt, index = 0|
	
	var combspec;
	combspec = [0.00125,0.4,\exp].asSpec;
	
	e.actions.slider[index] = { |sl|
		evt.amp = \amp.asSpec.map( sl.value );
	};
	e.actions.knob[index] = { |sl|
		evt.res = combspec.map( sl.value );
	};
		
	e.actions.button.rec[index] = { |bt|
		switch( bt.value.asInt,
			1, { evt.start },
			0, { evt.end }
		);
	};

	evt.ctrl.remove;
	evt.ctrl = SimpleController( evt )
		.put( \amp, { 
			e.active = false;
			e.sliders[index].valueAction = \amp.asSpec.unmap( evt.amp );
			e.active = true;
		})
		.put( \res, {
			e.active = false;
			e.knobs[index].valueAction = combspec.unmap( evt.res );
			e.active = true;
		})
		.put( \synth, {
			e.active = false;
			e.buttons.rec[index].valueAction = evt.synth.notNil.binaryValue;
			e.active = true;
		});
				
		[ \amp, \res, \synth ].do({ |item| evt.changed(item) });
};
);

if( e.notNil ) { 
	~canto.clicks.iconnect( 5 ); 
	//~canto.clicks2.iconnect( 4 ); 
};


~canto.clicksCtrl.remove;
~canto.clicksCtrl = SimpleController( ~canto );
~canto.clicksCtrl.put( \bar, { |...args|
	var notes;
	notes = ~canto.getCellBar( ~canto.bar, ~canto.currentIndex );
	if( notes.notNil ) {
		~canto.clicks.notes = ~canto.getCellBar( ~canto.bar, ~canto.currentIndex )
			.flop[4].as(Set).as(Array).sort.wrapAt((..7))
	};
});


(
~canto.clicks.n = 4;

SynthDef( "canto_clicks", { |modSpeed = 0.1, pan = 0.25, gate = 1, amp = 0.1, 
		freq = #[20, 4000], filter = #[ 50, 20000 ], res = 0.05|
	var spds, trg, env;
	var sig;
	var notes;
	
	notes = \notes.kr( { 64.rand }!8 ).midicps;
	
	
	trg = T2A.ar( In.kr(1) > 0.9 );
	spds = \spds.kr( 285 ! ~canto.clicks.n );
	filter = filter.lag(0.5);
	
	sig = spds.collect({ |spd| 
		var trig, env;
		var note, noteMul, frx;
		trig = TDuty.ar( 60/spd, trg ) - 0.001;
		note = Demand.ar( trig, 0, Drand( notes, inf ) );
		noteMul = Demand.ar( trig, 0, 
			Dwhite( 0.1,1, inf)
		);
		frx =  Latch.ar( freq, trig );
		noteMul = noteMul.explin( 0.1, 1, (frx[0] / note).ceil, (frx[1] / note).floor )
			.round(1).max(1);
		
		note = (note * noteMul).clip(20,20000);
		//note.poll( trig );
		trig = Trig.ar( trig, LFDNoise3.kr(modSpeed).exprange(1/10000,1/200) ) * GrayNoise.ar(1);
		trig = CombC.ar( Delay2.ar(trig), 1/20, 1/note, res );
		
		trig = BLowCut.ar( trig, 
			LFDNoise3.kr(modSpeed).exprange(filter[0],0.75.linexp( 0,1, *filter)).clip(20,20000),
			4 
		);
		trig = BHiCut.ar( trig, 
			LFDNoise3.kr(modSpeed).exprange(0.25.linexp( 0,1, *filter), filter[1]).clip(20,20000), 
			4 
		);
		
		RoundPan.ar( 4, trig * 0.25, LFDNoise3.kr(modSpeed) * pan);
	}).sum;
	
	env = Env.asr(0.1,1,0.1).kr(2,gate);
	Out.ar( 0, sig * env * amp.lag(0.1) );
}).load(s);
);


(
if( ~canto.clicksWindow.notNil && { ~canto.clicksWindow.isClosed.not } ) {
	~canto.clicksWindow.close;
};

~canto.clicksWindow = Window( "canto clicks", Rect(550, 600, 264, 180) ).front;

~canto.clicksWindow.addFlowLayout;

RoundView.useWithSkin( ( font: Font( "Helvetica", 9 ) ),
	{
	[ ~canto.clicks ].do({ |evt, i|
		var ctrl, powerButton, activeButton, filterSlider;
		
		ctrl = SimpleController( evt);	
		
		powerButton = SmoothButton( ~canto.clicksWindow, 16@16 )
			.label_( [ 'power', 'power' ] )
			.hiliteColor_( Color.green )
			.value_( evt.synth.notNil.binaryValue )
			.action_({ |bt|
				switch( bt.value, 
					1, {  evt.start },
					0, {  evt.end }
				);
			});
			
		ctrl.put( \synth, {
			powerButton.value = evt.synth.notNil.binaryValue;
		});
		
		StaticText( ~canto.clicksWindow, 200@16 ).string_( "clicks" );
	
		 ~canto.clicksWindow.view.decorator.nextLine;
		 
		[ 
		  \amp, \amp.asSpec,
		  \res, [0.00125,0.4,\exp].asSpec,
		  \modSpeed, [0.1,20,\exp,0,0.1].asSpec,
		  \pan, [0.25,1].asSpec,
		  \spd, [2,100,\exp,1,2].asSpec
		 ].pairsDo({ |key, spec|
			 var sl;
			 sl = EZSmoothSlider( ~canto.clicksWindow, 250@13, key, spec, 
			 	{ |sl|
				 	evt.perform( key.asSetter, sl.value );
			 	}, evt[ key ] );
			 ctrl.put( key, { sl.value =  evt[ key ] });
		 });
		 
		 [ 
		  \freq, \freq.asSpec,
		  \filter, \freq.asSpec
		 ].pairsDo({ |key, spec|
			 var sl;
			 sl = EZSmoothRanger( ~canto.clicksWindow, 250@13, key, spec, 
			 	{ |sl|
				 	evt.perform( key.asSetter, sl.value );
			 	}, evt[ key ] );
			 ctrl.put( key, { sl.value = evt[ key ] });
		 });
		 		
		~canto.clicksWindow.addToOnClose({ ctrl.remove; });
	});
});

)


)

/*

~canto.clicks.start( true );
~canto.clicks.end;
~canto.clicks.setting = 0;

~canto.clicks.modrange = 0.5;

~canto.clicks.setFilters;
~canto.clicks.setFilters({ [true,false].wchoose([1/4,3/4]); }!5);

~canto.clicks.resetFilters;

(
~canto.clicks.synth.set( \rlpf, { 1000 exprand: 10000 }!5 );
~canto.clicks.synth.set( \rhpf, { 100 exprand: 1000 }!5 );
~canto.clicks.synth.set( \res, { 0.05 exprand: 5 }!5 );
)

(
~canto.clicks.synth.set( \rlpf, 20000!5 );
~canto.clicks.synth.set( \rhpf, 20!5);
~canto.clicks.synth.set( \res, 0.5.sqrt!5 );
)

~canto.clicks.synth.set( \lag, 0.05 );

~canto.clicks.spd = 5;

~canto.clicks.active = 1;

~canto.clicks.active = 1;

~canto.clicks.sn.set( \t_clear, 1 );

~canto.clicks.leak = 0;

~canto.clicks.pan = 0

*/