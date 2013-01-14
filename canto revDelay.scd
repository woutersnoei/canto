(
~canto = ~canto ? EM();

~canto.cutbus = Bus( \control, 1, 1 );

~canto.revDelay = ~canto.revDelay ? EM();

(
SynthDef( "canto_revDelay", { |in = 0, private = 0, amp = 0.1, 
	preDelay = 0.05, delay = 0, lowCut = 200, gate = 1|
	
	var trig;
	var bufs;
	var input;
	var out;
	var env;
	
	trig = In.kr(1) > 0;
	bufs = 5.collect({ LocalBuf(16384, 1).clear });
	trig = PulseDivider.kr( trig, 5, (4..0) );
	input = In.ar( in + (private * (NumOutputBuses.ir + NumInputBuses.ir) ) );
	input = BLowCut.ar( input, lowCut.lag(0.25).clip(20,20000) );
	input = DelayN.ar( input, preDelay );
	out = trig.collect({ |tr, i|
		var end, run, pos;
		end = trig.wrapAt(i+1);
		run = SetResetFF.kr( tr, end ).varlag(0.05);
		end = TDelay.kr( end, delay );
		RecordBuf.ar( input, bufs[i], 0, run, 0, 1, 0, tr );
		pos = Timer.kr( tr + end ) * SampleRate.ir;
		(1-run) * PlayBuf.ar( 1, bufs[i], -1, end, pos, 0 );
		//SinOsc.ar(440,0,0.01) * run
	});
	
	out = out.collect({ |sig, i|
		RoundPan.ar( ~canto.numChan ? 4, sig, LFDNoise3.kr(0.05, 2) );
	}).sum;
	
	out = RemoveBadValues.ar( out );
	
	Out.ar(0, Env.cutoff(0.1).kr(2,gate) * out * amp );
}).load(s);


SynthDef( "canto_revDelay_quadIn", { |in = 0, private = 0, amp = 0.1, 
	preDelay = 0.05, delay = 0, lowCut = 200, gate = 1|
	
	var trig;
	var bufs;
	var input;
	var out;
	var env;
	
	trig = In.kr(1) > 0;
	bufs = 5.collect({ LocalBuf(16384, 1).clear });
	trig = PulseDivider.kr( trig, 5, (4..0) );
	input = In.ar( in + [1,3] + (private * (NumOutputBuses.ir + NumInputBuses.ir) ) ).sum;
	input = BLowCut.ar( input, lowCut.lag(0.25).clip(20,20000) );
	input = DelayN.ar( input, preDelay );
	out = trig.collect({ |tr, i|
		var end, run, pos;
		end = trig.wrapAt(i+1);
		run = SetResetFF.kr( tr, end ).varlag(0.05);
		end = TDelay.kr( end, delay );
		RecordBuf.ar( input, bufs[i], 0, run, 0, 1, 0, tr );
		pos = Timer.kr( tr + end ) * SampleRate.ir;
		(1-run) * PlayBuf.ar( 1, bufs[i], -1, end, pos, 0 );
		//SinOsc.ar(440,0,0.01) * run
	});
	
	out = out.collect({ |sig, i|
		RoundPan.ar( ~canto.numChan ? 4, 
			LFDNoise3.kr(0.2).range(-0.5,1).max(0) * sig, 
			LFDNoise3.kr(0.05, 2) );
	}).sum;
	
	out = RemoveBadValues.ar( out );
	
	Out.ar(0, Env.cutoff(0.1).kr(2,gate) * out * amp );
}).load(s);


);

~canto.revDelay.global = ~canto.revDelay.global ? EM();

[
	\delay, 0,
	\amp, 0.1,
	\lowCut, 200,
	\preDelay, 0.05
].pairsDo({ |key,value|
	~canto.revDelay.global[ key ] = value;
	~canto.revDelay.global[ key.asSetter ] = { |evt, val|
		evt[ key ] = val ? value;
		evt.synth.set( key, val ? value);
	};
});

~canto.revDelay.global.start = { |evt|
	evt.end;
	evt.synth = Synth( "canto_revDelay_quadIn", [ \private, 0 ] ++ 
		evt.getPairs([ 'delay', 'amp', 'preDelay' ])
	);
};

~canto.revDelay.global.end = { |evt|
	evt.synth.release;
	evt.synth = nil;
};

(
~canto.revDelay.global.iconnect = { |evt, index = 0|
	
	e.actions.slider[index] = { |sl|
		evt.amp = \amp.asSpec.map( sl.value );
	};
	
	e.actions.knob[index] = { |sl|
		evt.delay = sl.value * 0.3;
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
		.put( \synth, {
			e.active = false;
			e.buttons.rec[index].valueAction = evt.synth.notNil.binaryValue;
			e.active = true;
		})
		.put( \delay, {
			e.active = false;
			e.knobs[index].valueAction = evt.delay / 0.3;
			e.active = true;
		});
	[ \amp, \synth, \delay ].do({ |item| evt.changed(item) });
};
);


~canto.revDelay.input = ~canto.revDelay.global.copy;

~canto.revDelay.input.start = { |evt|
	evt.end;
	evt.synth = Synth( "canto_revDelay", [ \private, 1 ] ++ 
		evt.getPairs([ 'delay', 'amp', 'preDelay' ])
	);
};

if( e.notNil ) { 
	~canto.revDelay.global.iconnect( 10 );
	~canto.revDelay.input.iconnect( 11 );
 };

(
if( ~canto.revDelayWindow.notNil && { ~canto.revDelayWindow.isClosed.not } ) {
	~canto.revDelayWindow.close;
};

~canto.revDelayWindow = Window( "canto revDelays", Rect(554, 377, 257, 190) ).front;

~canto.revDelayWindow.addFlowLayout;

RoundView.useWithSkin( (font: Font( "Helvetica", 9 ) ),
	{	
	
	[ \input, \global ].do({ |which|
		var res = 1, max = 5;
		var ctrl, filterSliders, powerButton;
		
		ctrl = SimpleController( ~canto.revDelay[ which ] );
		
		powerButton = SmoothButton( ~canto.revDelayWindow, 16@16 )
			.label_( [ 'power', 'power' ] )
			.hiliteColor_( Color.green )
			.value_( ~canto.revDelay[ which ].synth.notNil.binaryValue )
			.action_({ |bt|
				switch( bt.value, 
					1, {  ~canto.revDelay[ which ].start },
					0, {  ~canto.revDelay[ which ].end }
				);
			});
			
		ctrl.put( \synth, {
			powerButton.value = ~canto.revDelay[ which ].synth.notNil.binaryValue;
		});
		
		StaticText( ~canto.revDelayWindow, 200@16 ).string_( which );
		
				 ~canto.revDelayWindow.view.decorator.nextLine;
			
		[ 'amp', \amp.asSpec,
		  'delay', [0,0.3,\lin,0].asSpec,
		  \lowCut, \freq.asSpec,
		  'preDelay', [0,0.2,\lin,0,0.05].asSpec,
		 ].pairsDo({ |key, spec|
			 var sl;
			 sl = EZSmoothSlider(  ~canto.revDelayWindow, 250@13, key, spec, 
			 	{ |sl|
				 	~canto.revDelay[ which ].perform( key.asSetter, sl.value );
			 	}, ~canto.revDelay[ which ][ key ] );
			 ctrl.put( key, { sl.value = ~canto.revDelay[ which ][ key ].value });
		 });		 
		~canto.revDelayWindow.addToOnClose({ ctrl.remove; });
	
	});
});
);
)

