(
~canto = ~canto ? EM();

/*
~canto.latency =  ~canto.latency ? (1024 + 64)/44100; // audio i/o latency Babyface: (1024 + 64)/44100
*/

~canto.cutbus = Bus( \control, 1, 1 );

~canto.delay = ~canto.delay ? EM();

(
SynthDef( "canto_randdelay", { |in = 0, private = 0, time = 1, amp = 0.1, latency = 0.02,
		modSpeed = 5, modAmt = 0, pshift = 0, pdisp = 0, tvar = 0,
		vari = 0,  gate = 1, lowcut = #[200,200,200,200,200], hicut = #[20000,20000,20000,20000,20000]|
	var delays, input, index;
	var trig;
	var times;
	var mod;
	var env;
	
	times = \times.kr( 0!20 ).clump(5);
	time = time.lag(1);
	mod = SinOsc.kr( (modSpeed / time) * Rand(0.9.dup(10), 1.1), Rand(0.dup(10),2pi), modAmt.lag(1) );
	
	input = In.ar( in + (private * (NumOutputBuses.ir + NumInputBuses.ir) ) );
	delays = DelayC.ar( input, 2.1, 
		((((1,1.5..9)/5) * time) + mod) - (latency + (tvar.lag(5) /2))
	);
	delays = BLowCut.ar( delays, lowcut.lag(0.1).clip(20,20000), 4 );
	delays = BHiCut.ar( delays, hicut.lag(0.1).clip(20,20000), 4 );
	//index = TIRand.kr(0.dup(4),4, TDelay.kr( In.kr(1), (time/5) - 0.05 ) );
	trig = TDelay.kr( In.kr(1), (time/5) - 0.05 );
	index = times.collect({ |times| Demand.kr( trig, trig > 0.9, Dseq( times, inf ) ); });
	index = (index + TIRand.kr(0.dup(4), vari, trig ));
	//Poll.kr( trig > 0.9, index );
	delays = delays.collect({ |item, i|
		var ampx;
		i = i/2;
		ampx = InRange.kr( index, i-0.25, i+0.25 );
		ampx = Slew.kr( ampx, 20, 20 );
		item * ampx;
	});
	
	delays = PitchShift.ar( delays.sum, 0.2, pshift.midiratio, pdisp.midiratio-1, tvar );
	delays = RemoveBadValues.ar( delays );
	Out.ar(0, Env.cutoff(0.1).kr(2,gate) * delays * amp );
}).load(s);



SynthDef( "canto_randdelay_quadin", { |in = 0, private = 0, time = 1, amp = 0.1, latency = 0.02,
		modSpeed = 5, modAmt = 0, pshift = 0, pdisp = 0, tvar = 0,
		vari = 0,  gate = 1, lowcut = #[200,200,200,200,200], hicut = #[20000,20000,20000,20000,20000]|
	var delays, input, index;
	var trig;
	var times;
	var mod;
	var env;
	
	times = \times.kr( 0!20 ).clump(5);
	time = time.lag(1);
	mod = SinOsc.ar( 
		(modSpeed / time) * Rand(0.9.dup(10), 1.1), Rand(0.dup(10),2pi), modAmt.lag(1) 
	);
	
	input = WhiteNoise.ar(1e-10);
	input = input + In.ar( in + (private * (NumOutputBuses.ir + NumInputBuses.ir) ) + [0,2]).mean;
	
	
	//input = input.wrapExtend( times.size );
	
	delays = DelayC.ar( input, 2.1, 
		((((1,1.5..9)/5) * time) + mod) - (latency + (tvar.lag(5) /2))
	);
	delays = BLowCut.ar( delays, lowcut.lag(0.1).clip(20,20000), 4 );
	delays = BHiCut.ar( delays, hicut.lag(0.1).clip(20,20000), 4 );
	//index = TIRand.kr(0.dup(4),4, TDelay.kr( In.kr(1), (time/5) - 0.05 ) );
	trig = TDelay.kr( In.kr(1), (time/5) - 0.05 );
	index = times.collect({ |times| Demand.kr( trig, trig > 0.9, Dseq( times, inf ) ); });
	index = (index + TIRand.kr(0.dup(4), vari, trig ));
	//Poll.kr( trig > 0.9, index );
	delays = delays.collect({ |item, i|
		var ampx;
		i = i/2;
		ampx = InRange.kr( index, i-0.25, i+0.25 );
		ampx = Slew.kr( ampx, 20, 20 );
		item * ampx;
	});
	
	delays = PitchShift.ar( delays.sum, 0.2, pshift.midiratio, pdisp.midiratio-1, tvar );
	delays = RemoveBadValues.ar( delays );
	Out.ar(0, Env.cutoff(0.1).kr(2,gate) * delays * amp );
}).load(s);

);

~canto.delay.global = ~canto.delay.global ? EM();

[
	\lowcut, #[200,200,200,200,200],
	\hicut, #[20000,20000,20000,20000,20000],
	\times, 0!20,
	\vari, 0,
	\amp, 0.1,
	\modSpeed, 1,
	\modAmt, 0,
	\pshift, 0,
	\pdisp, 0,
	\tvar, 0,
	\time, 1/TempoClock.tempo
].pairsDo({ |key,value|
	~canto.delay.global[ key ] = value;
	~canto.delay.global[ key.asSetter ] = { |evt, val|
		evt[ key ] = val ? value;
		evt.synth.set( key, val ? value);
	};
});

~canto.delay.global.timesRes = 1;
~canto.delay.global.timesMax = 4;


~canto.delay.global.updateTime = { |evt| evt.time = 1/TempoClock.tempo; };

~canto.delay.global.setTimes = { |evt, time| 
	time = (time ?? { { (0.0 rrand: evt.timesMax).round(evt.timesRes); }!20; }).asCollection;
	if( time.size != 20 ) { time = time.wrapExtend( 20 ) };
	evt.times = time;
};

~canto.delay.global.setSingleTime = { |evt, time| 
	time = time ?? { (0.0 rrand: evt.timesMax).round(evt.timesRes) };
	evt.times = time!20;
};

~canto.delay.global.setQuadTime = { |evt, time| 
	time = (time ?? { {(0.0 rrand: evt.timesMax).round(evt.timesRes)}!4 }).asCollection;
	if( time.size != 4 ) { time = time.wrapExtend( 4 ) };
	evt.times = time.stutter(5);
};

~canto.delay.global.setSyncTimes = { |evt, time| 
	time = (time ?? { {(0.0 rrand: evt.timesMax).round(evt.timesRes)}!5 }).asCollection;
	if( time.size != 5 ) { time = time.wrapExtend( 5 ) };
	evt.times = time.dup(4).flatten(1);
};

~canto.delay.global.lowcut_ = { |evt, lowcut|
	lowcut = (lowcut ? #[200,200,200,200,200]).asCollection;
	if( lowcut.size != 5 ) { lowcut = lowcut.wrapExtend(5) };
	evt[ \lowcut ] = lowcut;
	evt.synth.set( \lowcut, lowcut );
};

~canto.delay.global.hicut_ = { |evt, hicut|
	hicut = (hicut ? #[20000,20000,20000,20000,20000]).asCollection;
	if( hicut.size != 5 ) { hicut = hicut.wrapExtend(5) };
	evt[ \hicut ] = hicut;
	evt.synth.set( \hicut, hicut );
};


~canto.delay.global.start = { |evt|
	evt.end;
	evt.synth = Synth( "canto_randdelay_quadin", [ \latency, 0, \private, 0 ] ++ 
		evt.getPairs([ 'lowcut', 'hicut', 'times', 'vari', 'amp', 'modSpeed', 'modAmt', 
			'pshift', 'pdisp', 'tvar', 'time' ]
		)
	);
};

~canto.delay.global.end = { |evt|
	evt.synth.release;
	evt.synth = nil;
};

(
~canto.delay.global.iconnect = { |evt, index = 0|
	
	e.actions.slider[index] = { |sl|
		evt.amp = \amp.asSpec.map( sl.value );
	};
	
	e.actions.knob[index] = { |sl|
		evt.vari = (sl.value * 5).round( 1 );
	};
	
	e.actions.button.rec[index] = { |bt|
		switch( bt.value.asInt,
			1, { evt.start },
			0, { evt.end }
		);
	};
	
	e.actions.button.on[index] = { |bt|
		evt.timesRes = 1;
		evt.setTimes;
	};
	
	e.actions.button.solo[index] = { |bt|
		evt.timesRes = 0.5;
		evt.setTimes;
	};
	
	e.actions.slider[index+1] = { |sl|
		evt.modSpeed = sl.value.linexp(0,1,1,1000);
	};
	
	e.actions.knob[index+1] = { |sl|
		evt.modAmt = sl.value * 0.001;
	};
	
	e.actions.button.on[index+1] = { |bt|
		switch( bt.value.asInt,
			1, { evt.pshift = 12 },
			0, { evt.pshift = 0 }
		);
	};
	
	e.actions.button.solo[index+1] = { |bt|
		switch( bt.value.asInt,
			1, { evt.tvar = 0.1 },
			0, { evt.tvar = 0 }
		);
	};
	
	
	evt.ctrl.remove;
	evt.ctrl = SimpleController( evt )
		.put( \amp, { 
			e.active = false;
			e.sliders[index].valueAction = \amp.asSpec.unmap( evt.amp );
			e.active = true;
		})
		.put( \synth, {
			e.active = false;
			e.buttons.rec[index].valueAction = evt.synth.notNil.binaryValue;
			e.active = true;
		})
		.put( \vari, {
			var vari;
			e.active = false;
			vari = evt.vari.asInt;
			if( (e.knobs[index].value * 5).round(1).asInt != vari ) {
				e.knobs[index].valueAction = vari;
			};
			e.active = true;
		})
		.put( \modSpeed, {
			e.active = false;
			e.sliders[index+1].valueAction = evt.modSpeed.explin(1,1000,0,1);
			e.active = true;
		})
		.put( \modAmt, {
			e.active = false;
			e.knobs[index+1].valueAction = evt.modAmt / 0.001;
			e.active = true;
		})
		.put( \timesRes, {
			e.active = false;
			e.buttons.on[index].valueAction = (evt.timesRes > 0.75).binaryValue;
			e.buttons.solo[index].valueAction = (evt.timesRes < 0.75).binaryValue;
			e.active = true;
		})
		.put( \modAmt, {
			e.active = false;
			e.knobs[index+1].valueAction = evt.modAmt / 0.001;
			e.active = true;
		})
		.put( \pshift, {
			e.active = false;
			e.buttons.on[index+1].valueAction = (evt.pshift > 6).binaryValue;
			e.active = true;
		})
		.put( \tvar, {
			e.active = false;
			e.buttons.solo[index+1].valueAction = (evt.tvar > 0.05).binaryValue;
			e.active = true;
		})
		;
	[ \amp, \synth, \vari, \timesRes, \pshift, \tvar ].do({ |item| evt.changed(item) });
};
);


~canto.delay.input = ~canto.delay.global.copy;

~canto.delay.input.start = { |evt|
	evt.end;
	evt.synth = Synth( "canto_randdelay", [ \latency, ~canto.latency , \private, 1 ] ++ 
		evt.getPairs([ 'lowcut', 'hicut', 'times', 'vari', 'amp', 'modSpeed', 'modAmt', 
			'pshift', 'pdisp', 'tvar', 'time' ]
		)
	);
};

~canto.delayCtrl.remove;
~canto.delayCtrl = SimpleController( ~canto );
~canto.delayCtrl.put( \bar, { |...args|
	~canto.delay.global.updateTime;
	~canto.delay.input.updateTime;
});

if( e.notNil ) { 
	~canto.delay.global.iconnect( 8 );
	~canto.delay.input.iconnect( 10 );
 };

(
if( ~canto.delayWindow.notNil && { ~canto.delayWindow.isClosed.not } ) {
	~canto.delayWindow.close;
};

~canto.delayWindow = Window( "canto delays", Rect(1136, 264, 266,500) ).front;

~canto.delayWindow.addFlowLayout;

RoundView.useWithSkin( (font: Font( "Helvetica", 9 ) ),
	{	
	
	[ \input, \global ].do({ |which|
		var ctrl, filterSliders, powerButton;
		var maxBox, resButton;
		
		ctrl = SimpleController( ~canto.delay[ which ] );
		
		powerButton = SmoothButton( ~canto.delayWindow, 16@16 )
			.label_( [ 'power', 'power' ] )
			.hiliteColor_( Color.green )
			.value_( ~canto.delay[ which ].synth.notNil.binaryValue )
			.action_({ |bt|
				switch( bt.value, 
					1, {  ~canto.delay[ which ].start },
					0, {  ~canto.delay[ which ].end }
				);
			});
			
		ctrl.put( \synth, {
			powerButton.value = ~canto.delay[ which ].synth.notNil.binaryValue;
		});
		
		StaticText( ~canto.delayWindow, 200@16 ).string_( which );
		
		SmoothButton( ~canto.delayWindow, 40@16 )
			.label_( [ "sync" ] )
			.action_({ |bt|
				~canto.delay[ which ].updateTime;
			});
		
		maxBox = SmoothNumberBox( ~canto.delayWindow, 25@16 )
			.value_(  ~canto.delay[ which ].timesMax )
			.step_(1)
			.scroll_step_(1)
			.clipLo_(2)
			.clipHi_(9)
			.action_({ |nb|
				 ~canto.delay[ which ].timesMax = nb.value;
			});
			
		resButton = SmoothButton( ~canto.delayWindow, 25@16 )
			.label_( [ "1", "0.5" ] )
			.value_( (~canto.delay[ which ].timesRes < 0.75).binaryValue )
			.action_({ |bt|
				switch( bt.value, 
					1, {  ~canto.delay[ which ].timesRes = 0.5; },
					0, { ~canto.delay[ which ].timesRes = 1; }
				);
			});
			
		 ~canto.delayWindow.view.decorator.nextLine;
		
		[ "Times", "SingleTime", "QuadTime", "SyncTimes" ].do({ |item|
			SmoothButton( ~canto.delayWindow, 60@15 )
				.label_( item )
				.action_({ |bt|
					~canto.delay[ which ].perform( ("set" ++ item).asSymbol, nil )
				});
		});
			
		[ 'amp', \amp.asSpec,
		  'vari', [0,5,\lin,1].asSpec,
		  'pshift', [-12,12,\lin,1,0].asSpec,
		  'pdisp', [0,12,\lin,0.1,0].asSpec,
		  'tvar', [0, 0.1, \lin, 0 ].asSpec,
		  'modAmt', [0, 0.001, \lin, 0,0 ].asSpec,
		  'modSpeed', [1,1000,\exp,1,5].asSpec
		 ].pairsDo({ |key, spec|
			 var sl;
			 sl = EZSmoothSlider(  ~canto.delayWindow, 250@13, key, spec, 
			 	{ |sl|
				 	~canto.delay[ which ].perform( key.asSetter, sl.value );
			 	}, ~canto.delay[ which ][ key ] );
			 ctrl.put( key, { sl.value = ~canto.delay[ which ][ key ].value });
		 });
		 
		 filterSliders = 5.collect({ |i|
			  EZSmoothRanger(  ~canto.delayWindow, 250@10, "cut %".format(i+1), \freq.asSpec,
			 	{ |sl|
				 	
				 	~canto.delay[ which ].lowcut = ~canto.delay[ which ].lowcut.copy.put(i, sl.value[0]);
				 	~canto.delay[ which ].hicut = ~canto.delay[ which ].hicut.copy.put(i, sl.value[1]);
				 	
			 	}, [ ~canto.delay[ which ].lowcut[i], ~canto.delay[ which ].hicut[i] ]  );
		 });
		 
		 ctrl.put( \lowcut, {
			 filterSliders.do({ |sl, i|
			 	sl.value = [ ~canto.delay[ which ].lowcut[i], sl.value[1] ];
			 });
		 });
		 
		  ctrl.put( \hicut, {
			 filterSliders.do({ |sl, i|
			 	sl.value = [ sl.value[0], ~canto.delay[ which ].hicut[i] ];
			 });
		 });
		 
		 ctrl.put( \timesMax, {
			 maxBox.value = ~canto.delay[ which ].timesMax;
		 });
		 
		 ctrl.put( \timesRes, {
			 resButton.value = (~canto.delay[ which ].timesRes < 0.75).binaryValue;
		 });
		 
		~canto.delayWindow.addToOnClose({ ctrl.remove; });
	
	});
});
);
)


/*


~canto.delay.global.hicut;

~canto.delay.input.start;

~canto.delay[ 'global' ].lowcut.copy.put(0,400)

~canto.delay.global.updateTime;
~canto.delay.global.start;
~canto.delay.global.end;

~canto.delay.global.amp = 0.5;

~canto.delay.global.setTimes( nil, 1, 9 );
~canto.delay.global.setSingleTime( nil, 0.5, 9 );
~canto.delay.global.setQuadTime( nil, 1, 9 );
~canto.delay.global.setSyncTimes( nil, 1, 9 );

~canto.delay.global.vari = 0;

~canto.delay.global.times = 2!20;

~canto.delay.global.lowcut = [200,2000,200,2000,200];

~canto.delay.global.hicut = 3000;

~canto.delay.global.pshift = 12;
~canto.delay.global.pdisp = 2;
~canto.delay.global.tvar = 0.01;

~canto.delay.global.pshift = 0;
~canto.delay.global.pdisp = 0.01;
~canto.delay.global.tvar = 0;

~canto.delay.global.modAmt = 0.0;
~canto.delay.global.modSpeed = 1/TempoClock.tempo;

*/

/*
(
SynthDef( "canto_reversedelay", { |in = 0, private = 0, time = 1, amp = 0.1, latency = 0.02|
	var delays, index;
	var input;
	input = In.ar( in + (private * (NumOutputBuses.ir + NumInputBuses.ir) ) );
	delays = DelayC.ar( input, 1.5,   );
	Out.ar(0, delays.sum * amp );
}).load(s);
*/

/*
(
SynthDef( "canto_randdelay", { |in = 0, private = 0, time = 1, amp = 0.1, latency = 0.02,
		vari = 0, lowcut = #[200,200,200,200,200]|
	var delays, input, index;
	var trig;
	var times;
	
	times = \times.kr( 0!20 ).clump(5);
	
	input = In.ar( in + (private * (NumOutputBuses.ir + NumInputBuses.ir) ) );
	delays = DelayC.ar( input, 1.5, (((1..5)/5) * time) - latency );
	delays = BLowCut.ar( delays, lowcut.lag(0.1).clip(20,20000) );
	//index = TIRand.kr(0.dup(4),4, TDelay.kr( In.kr(1), (time/5) - 0.05 ) );
	trig = TDelay.kr( In.kr(1), (time/5) - 0.05 );
	index = times.collect({ |times| Demand.kr( trig, trig > 0.9, Dseq( times, inf ) ); });
	index = (index + TIRand.kr(0.dup(4), vari, trig )).wrap(0,4);
	delays = delays.collect({ |item, i|
		var ampx;
		ampx = InRange.kr( index, i-0.5, i+0.5 );
		ampx = Slew.kr( ampx, 20, 20 );
		item * ampx;
	});
	Out.ar(0, delays.sum * amp );
}).load(s);

);
*/


/*
~canto.delay.synth = Synth( "canto_randdelay", [ \time, 1/TempoClock.tempo, \latency, 0 ] );


~canto.delay.synth.set( \times, { (0 rrand: 9) / 2 }!20 );

~canto.delay.synth2.set( \times, { (0 rrand: 5)  }!20 );

~canto.delay.synth2.set( \modAmt, 0.0001, \modSpeed, 5 );

~canto.delay.synth2.set( \pshift,0, \pdisp, 0, \tvar, 0 );

~canto.delay.synth.set( \times, ([1.5,1.5,1.5,1.5,1.5]!4).flat );

~canto.delay.synth.set( \vari, 2 );
~canto.delay.synth.set( \lowcut, 100!5 );

~canto.delay.synth.set( \amp, 0.33);

~canto.delay.synth.free;
~canto.delay.synth2.free;

~canto.delay.synth2 = Synth( "canto_randdelay", [ 
	\time, 1/TempoClock.tempo, 
	\private, 1,
	\latency, ~canto.latency 
	]
);
*/
