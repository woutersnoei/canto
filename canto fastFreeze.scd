(

~canto = ~canto ? EM();

~canto.fastFreeze = ~canto.fastFreeze ? EM();

~canto.fastFreeze.amp = 0.2;
~canto.fastFreeze.leak = 0;
~canto.fastFreeze.active = 1;
~canto.fastFreeze.spd = 2;

~canto.fastFreeze.modrange = 0;
~canto.fastFreeze.lpf = 20000;
~canto.fastFreeze.hpf = 200;

~canto.fastFreeze.rhpf = 20!5;
~canto.fastFreeze.rlpf = 20000!5;
~canto.fastFreeze.res = (0.5.sqrt)!5;
~canto.fastFreeze.lag = 0.05;

~canto.fastFreeze.pan = 1;

~canto.fastFreeze.setting = 0;

#[ amp, active, spd, modrange, lpf, hpf, leak, rhpf, rlpf, res, lag, pan ].do({ |item|
	~canto.fastFreeze[ item.asSetter ] = { |evt, value|
		if( value.notNil ) {
			evt[ item ] = value;
			evt.synth.set( item, value );
		};
	};
});

~canto.fastFreeze.rlpfRange = [1000,10000];
~canto.fastFreeze.rhpfRange = [100,1000];
~canto.fastFreeze.resRange =  [0.05,5];

~canto.fastFreeze.setFilters = { |evt, which = true|
	which = which.asCollection.wrapExtend(5);
	which.do({ |item, i|
		if( item ) {
			evt.rlpf[i] = evt.rlpfRange[0] exprand: evt.rlpfRange[1];
			evt.rhpf[i] = evt.rhpfRange[0] exprand: evt.rhpfRange[1];
			evt.res[i] = evt.resRange[0] exprand: evt.resRange[1];
		};
	});
	evt.rlpf = evt.rlpf; 
	evt.rhpf = evt.rhpf; 
	evt.res = evt.res; 
};

~canto.fastFreeze.resetFilters = { |evt|
	evt.rhpf = 20!5;
	evt.rlpf = 20000!5;
	evt.res = (0.5.sqrt)!5;
};

~canto.fastFreeze.start = { |evt, clear = false|
	if( clear ) { evt.end };
	if( evt.synth.isNil or: { evt.sn.isRunning.not }) {
		evt.synth = Synth( "canto_fastFreeze", 
			evt.getPairs( #[ amp, active, spd, modrange, lpf, hpf, leak,
				 rhpf, rlpf, res, lag, pan ] ) 
		).register;
	};
};

~canto.fastFreeze.end = { |evt|
	evt.synth.release;
	evt.synth = nil;
};

(
~canto.fastFreeze.iconnect = { |evt, index = 0|
	
	var spdspec;
	spdspec = [1,20,\exp].asSpec;
	
	e.actions.slider[index] = { |sl|
		evt.amp = \amp.asSpec.map( sl.value );
	};
	e.actions.knob[index] = { |sl|
		evt.modrange = sl.value;
		evt.spd = spdspec.map( sl.value );
	};
	e.actions.slider[index+1] = { |sl|
		var lpf, hpf, width;
		width = (1-e.knobs[index+1].value) / 2;
		#hpf, lpf = sl.value.linlin( 0, 1,  0+width,   1-width) + [width.neg, width];
		evt.lpf = \freq.asSpec.map(lpf);
		evt.hpf = \freq.asSpec.map(hpf);
	};
	e.actions.knob[index+1] = { |sl|
		var lpf, hpf, width;
		width = (1-sl.value) / 2;
		#hpf, lpf = e.sliders[index+1].value
			.linlin( 0, 1, 0 + width,  1 - width) + [width.neg, width];
		evt.lpf = \freq.asSpec.map(lpf);
		evt.hpf = \freq.asSpec.map(hpf);
	};
	
	e.actions.button.rec[index] = { |bt|
		switch( bt.value.asInt,
			1, { evt.start },
			0, { evt.end }
		);
	};
	e.actions.button.on[index] = { |bt|
		if( bt.value.asInt == 1 ) {
			evt.synth.set( \t_clear, 1 );
			e.buttons.on[index].valueAction = 0;
		};
	};
	e.actions.button.solo[index] = { |bt|
		evt.active = bt.value;
	};
	
	e.actions.button.on[index+1] = { |bt|
		if( bt.value.asInt == 1 ) {
			evt.setFilters({ [true,false].wchoose([1/4,3/4]); }!5);
			e.buttons.on[index+1].valueAction = 0;
		};
	};
	e.actions.button.solo[index+1] = { |bt|
		if( bt.value.asInt == 1 ) {
			evt.resetFilters;
			e.buttons.solo[index+1].valueAction = 0;
		};
	};

	evt.ctrl.remove;
	evt.ctrl = SimpleController( evt )
		.put( \amp, { 
			e.active = false;
			e.sliders[index].valueAction = \amp.asSpec.unmap( evt.amp );
			e.active = true;
		})
		.put( \modrange, {
			e.active = false;
			e.knobs[index].valueAction = evt.modrange;
			e.active = true;
		})
		.put( \synth, {
			e.active = false;
			e.buttons.rec[index].valueAction = evt.synth.notNil.binaryValue;
			e.active = true;
		})
		.put( \active, {
			e.active = false;
			e.buttons.solo[index].valueAction = evt.active;
			e.active = true;
		})
		.put( \hpf, {
			var lpf, hpf, width, center;
			hpf = \freq.asSpec.unmap( evt.hpf );
			lpf = \freq.asSpec.unmap( evt.lpf );
			width = (lpf - hpf)/2;
			center = (hpf + width).linlin(0+width,1-width,0,1);
			e.active = false;
			e.sliders[index+1].valueAction = center;
			e.knobs[index+1].valueAction = 1-(width*2);
			e.active = true;
		})
		.put( \lpf, {
			var lpf, hpf, width, center;
			hpf = \freq.asSpec.unmap( evt.hpf );
			lpf = \freq.asSpec.unmap( evt.lpf );
			width = (lpf - hpf)/2;
			center = (hpf + width).linlin(0+width,1-width,0,1);
			e.active = false;
			e.sliders[index+1].valueAction = center;
			e.knobs[index+1].valueAction = 1-(width*2);
			e.active = true;
		});
		
		[ \amp, \modrange, \active, \hpf ].do({ |item| evt.changed(item) });
};
);

~canto.fastFreeze2 = ~canto.fastFreeze.copy;

~canto.fastFreeze2.rhpf = 20!5;
~canto.fastFreeze2.rlpf = 20000!5;
~canto.fastFreeze2.res = (0.5.sqrt)!5;

if( e.notNil ) { 
	~canto.fastFreeze.iconnect( 3 ); 
	~canto.fastFreeze2.iconnect( 5 ); 
};

(
SynthDef( "canto_fastFreeze", { |amp = 0.1, active = 1, spd = 5, modrange = 0, gate = 1,
		lpf = 20000, hpf = 250, t_clear = 0, leak = 0,
		rlpf = #[20000,20000,20000,20000,20000],
		rhpf = #[20,20,20,20,20],
		res = #[1.414,1.414,1.414,1.414,1.414],
		lag = 0.05,
		pan = 1
	|
	var fft, sig, buf1, buf2;
	var bufsig, lasbufsig, phasor;
	var modsig, msig, freqs;
	var env, fb;
	var trig;
	modrange = modrange.lag(5).clip(0,1);
	spd = spd.lag(5);
	sig = PrivateIn.ar(1) * active;
	
	trig = Trig.kr(In.kr(1), 0.01);
	rlpf = Demand.kr( trig, trig > 0.9, Dseq(rlpf,inf) ).lag(lag)
		.blend( 20000, Line.kr(1,0,1) ).clip(20,20000);
	rhpf = Demand.kr( trig, trig > 0.9, Dseq(rhpf,inf) ).lag(lag)
		.blend( 20, Line.kr(1,0,1) ).clip(20,20000);
	res = Demand.kr( trig, trig > 0.9, Dseq(res,inf) ).lag(lag)
		.blend( 1.414, Line.kr(1,0,1) ).clip(0.01,10);

	modsig = PinkNoise.ar(1.dup);
	modsig = (modsig * (1-(modrange.sqrt))) + ( Splay.ar( 
			SinOsc.ar( Rand(0.5.dup(6),1.5) * spd.lag(2), Rand(0.dup(6), 2pi )).max(0) ** 4 
		) * modsig * modrange * 2);
	modsig = BHiCut.ar( modsig, lpf.clip(20,20000).lag(4), 3 );
	modsig = BLowCut.ar( modsig, hpf.clip(20,20000).lag(4), 3 );
	
	buf1 = LocalBuf(1024).clear;
	buf2 = LocalBuf(1024).clear;
	fft = FFT( buf1, sig );
	phasor = Phasor.ar(0,2,0,1024, 512);
	bufsig = BufRd.ar( 1, buf1, phasor, 1, 1 );
	lasbufsig = (BufRd.ar( 1, buf2, phasor, 1, 1 ) * 1).max( bufsig  ).clip(-100,100);
	fb = (1-leak) * (1-Trig.kr(t_clear, 1024 / SampleRate.ir));
	BufWr.ar( (bufsig + lasbufsig) * fb, buf2, phasor, 1 ); 
	
	sig = modsig.collect({ |ms|
		var modfft;
		modfft = FFT( LocalBuf(1024), ms );
		modfft = PV_MagMul( modfft, buf2 );
		IFFT( modfft ) * 0.2;
	});
	
	sig = BHiPass.ar( sig * Line.kr(-1,1,2048/SampleRate.ir).max(0), rhpf, res );
	sig = BLowPass.ar( sig, rlpf, res );
	pan = LFDNoise3.kr(0.05).range(pan.neg, pan);
	
	sig = sig.collect({ |sig, i|
		RoundPan.ar( ~canto.numChan ? 4, sig, [-0.25,0.25][i] + pan );
	}).sum;
	
	sig = RemoveBadValues.ar(sig);
	
	Out.ar(0,sig * amp.lag(1) * Env.cutoff(2).kr(2,gate) );
}).load(s);
);


(
if( ~canto.fastFreezeWindow.notNil && { ~canto.fastFreezeWindow.isClosed.not } ) {
	~canto.fastFreezeWindow.close;
};

~canto.fastFreezeWindow = Window( "canto fastFreezes", Rect(860, 250, 264, 340) ).front;

~canto.fastFreezeWindow.addFlowLayout;

RoundView.useWithSkin( ( font: Font( "Helvetica", 9 ) ),
	{
	[ ~canto.fastFreeze, ~canto.fastFreeze2 ].do({ |evt, i|
		var ctrl, powerButton, activeButton, filterSlider;
		
		ctrl = SimpleController( evt);	
		
		powerButton = SmoothButton( ~canto.fastFreezeWindow, 16@16 )
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
		
		StaticText( ~canto.fastFreezeWindow, 200@16 ).string_( "fastFreeze" );
		
		SmoothButton( ~canto.fastFreezeWindow, 40@16 )
			.label_( [ "clear" ] )
			.action_({ |bt|
				evt.synth.set( \t_clear, 1 );
			});
			
		activeButton = SmoothButton( ~canto.fastFreezeWindow, 40@16 )
				.label_( [ "active", "active" ] )
				.hiliteColor_( Color.green )
				.value_( evt.active )
				.action_({ |bt|
					evt.active = bt.value;
				});
				
		SmoothButton( ~canto.fastFreezeWindow, 80@16 )
			.label_( [ "setFilters" ] )
			.action_({ |bt|
				evt.setFilters({ [true,false].wchoose([1/4,3/4]); }!5);
			});
		
		SmoothButton( ~canto.fastFreezeWindow, 80@16 )
			.label_( [ "resetFilters" ] )
			.action_({ |bt|
				evt.resetFilters;
			});
				
		ctrl.put( \active, {
			activeButton.value = evt.active;
		});
	
		 ~canto.fastFreezeWindow.view.decorator.nextLine;
				
		[ 
		  \amp, \amp.asSpec,
		  \pan, [0.25,1,\lin,0,0].asSpec,
		  \leak, [0,1, 8.0,0,0].asSpec,
		  \spd, [1,20,\exp].asSpec,
		  \modrange, [0,1].asSpec,
		  \lag, [0.025, 1, \exp].asSpec,
		 ].pairsDo({ |key, spec|
			 var sl;
			 sl = EZSmoothSlider( ~canto.fastFreezeWindow, 250@13, key, spec, 
			 	{ |sl|
				 	evt.perform( key.asSetter, sl.value );
			 	}, evt[ key ] );
			 ctrl.put( key, { sl.value =  evt[ key ] });
		 });
		 
		filterSlider = EZSmoothRanger(  ~canto.fastFreezeWindow, 250@10, "filter", \freq.asSpec,
			 	{ |sl|
				 	
				 	evt.hpf = sl.value[0];
				 	evt.lpf = sl.value[1];
			 	}, [ evt.hpf, evt.lpf] );
			 	
		ctrl.put( \hpf, { filterSlider.value =  [ evt.hpf, filterSlider.value[1]] });
		ctrl.put( \lpf, { filterSlider.value =  [ filterSlider.value[0], evt.lpf] });
		
		~canto.fastFreezeWindow.addToOnClose({ ctrl.remove; });
	});
});

)


)

/*

~canto.fastFreeze.start( true );
~canto.fastFreeze.end;
~canto.fastFreeze.setting = 0;

~canto.fastFreeze.modrange = 0.5;

~canto.fastFreeze.setFilters;
~canto.fastFreeze.setFilters({ [true,false].wchoose([1/4,3/4]); }!5);

~canto.fastFreeze.resetFilters;

(
~canto.fastFreeze.synth.set( \rlpf, { 1000 exprand: 10000 }!5 );
~canto.fastFreeze.synth.set( \rhpf, { 100 exprand: 1000 }!5 );
~canto.fastFreeze.synth.set( \res, { 0.05 exprand: 5 }!5 );
)

(
~canto.fastFreeze.synth.set( \rlpf, 20000!5 );
~canto.fastFreeze.synth.set( \rhpf, 20!5);
~canto.fastFreeze.synth.set( \res, 0.5.sqrt!5 );
)

~canto.fastFreeze.synth.set( \lag, 0.05 );

~canto.fastFreeze.spd = 5;

~canto.fastFreeze.active = 1;

~canto.fastFreeze.active = 1;

~canto.fastFreeze.sn.set( \t_clear, 1 );

~canto.fastFreeze.leak = 0;

~canto.fastFreeze.pan = 0

*/