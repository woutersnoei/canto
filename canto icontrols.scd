
(

e = ();

MIDIWindow(true);
e.port = MIDIClient.sources.detect({ |item| item.name == "Poort 1" }) !? _.uid ? 0;
MIDIIn.connect( 0, e.port );

(
e.m = MIDIOut(0, 
	MIDIClient.destinations.detect({ |item| 
		item.device.find( "iCON iControls_Pro" ).notNil 
	}) !? _.uid ? 0
).latency_(0);
);

e.midiMonitor = false;

e.sliderTouchSelect = true;

e.useSysex = false;

e.nSliders = 24; // 1 bank of 8  // added extra bank of 8 for other funcs
e.offset = 0;
e.currentFaderVals = 1!9;
e.initSliderValues = 0!e.nSliders;
e.initKnobValues = 0.5!e.nSliders;
e.initLabels = (_.asString)!e.nSliders;
e.initKnobLabels = ("knob"+_)!e.nSliders;

e.nSliders = e.nSliders.max(8);

e.actions = ();
e.autoPost = false; // debugmode
e.knobPushResets = true; // pushing knob resets knob position

e.knobsobRes = 1/128; // resolution for knobs
e.knobsobVelo = 1.25; // velocity dependence (1: none, >1: inc/dec more at higher velocity)

e.masterKnobRes = 0.1;

e.sofSetTime = 0.5; // time to change faders to new position at page / nudge change

e.actions[ \slider ] = (
	0: { |sl|  },
	'all': { |sl, i| if( e.autoPost ) { [i, \slider, sl.value ].postln }  }
	);

e.actions[ \touch ] = (
	0: { |sl, val| },
	'all': { |sl, val, i| if( e.autoPost ) { [i, \touch, val, sl.value ].postln } }
	);

e.actions[ \knob ] = (
	0: { |kn| },
	'all': { |kn, i| if( e.autoPost ) { [i, \knob, kn.value].postln } }
	);
	
e.actions[ \knobPush ] = (
	0: { |kn| },
	'all': { |kn, i| if( e.autoPost ) { [i, \knob, kn.value].postln } }
	);
	
e.actions[ \button ] = (
	'solo': ( 0: { |bt| }, 'all': { |bt, i| }),
	'on': ( 0: { |bt| }, 'all': { |bt, i| }),
	'rec': ( 0: { |bt| }, 'all': { |bt, i| }),
	'sel': ( 0: { |bt| }, 'all': { |bt, i| }),
	'all': { |bt, type, i| if( e.autoPost ) { [i, type, bt.value ].postln } }
	);
	
e.actions[ \bank ] = (
	'left': { |offset| },
	'right': { |offset| },
	'all': { |type, offset| if( e.autoPost ) { [\bank, type, offset ].postln } }
	);

e.actions[ \nudge ] = ( 
	'left': { |offset| },
	'right': { |offset| },
	'all': { |type, offset| if( e.autoPost ) { [\nudge, type, offset ].postln } }
	);
	
e.actions[ \master ] = { |sl| };
e.actions[ \masterKnob ] = { |kn| };
	
// show knob position via mute buttons
e.actions.knob.all = { |kn, i|
	e.knobDisplayTask.stop;
	8.do({ |i|
		if( (i - (kn.value * 7)).inRange( -0.75, 0.75 ) ) {
			e.hwSetButton( i, 1, \on );
		} {
			e.hwSetButton( i, 0, \on );
		};
	});
	e.knobDisplayTask = Task({
		1.wait;
		e.hwSetAll( [\on] );
	}).start;
};

// select fader via touch

e.sliderTouchSelect = e.sliderTouchSelect ? true;

e.active = true;

e.actions.touch.all = { |sl, val, i|
	if( e.sliderTouchSelect && { val == 1 } ) {
		e.buttons[\sel].do(_.valueAction_(0));
		e.buttons[\sel][i].valueAction = 1;
		e.selected = i;
	};
};
	
// easy shortcuts 

e.couple = { |evt, what, i = 0, key, spec, env, name, action| 
	if( key.notNil )
		{	if( key.class == Function )
				{  name = (spec ? "%*".format(i)).asString; // 2nd arg becomes name
					evt.actions[ what ][ i ] = key;
			}	{
				env = env ? currentEnvironment;
				name = name ? key.asString;
				spec = spec.asSpec; 
				evt.actions[ what ][ i ] = { |sl|
					env[ key ] = spec.map( sl.value ); 
					action.value( sl, env[ key ] );
				}; 
			};
			evt[ (slider: \labels, knob: \knobLabels )[ what ] ][ i ].valueAction = name;
			evt.skipJacks = evt.skipJacks ?? { Order() };
			evt.skipJacks[ i ].stop;
			if( key.class != Function )
				{ evt.skipJacks[ i ] = SkipJack( { 
					if( env[ key ].notNil ) { 
						evt[ (what ++ "s").asSymbol ][ i ].value = spec.unmap(env[ key ]); 
						evt.hwSet( what, i );
						}; } );
			};
		} {	evt.skipJacks = evt.skipJacks ?? { Order() };
			evt.skipJacks[ i ].stop;
			switch( what,
				\slider, { evt.labels[ i ].valueAction = i.asString; },
				\knob, {  evt.knobLabels[ i ].valueAction = i.asString;  
				});
			evt.actions[ what ][ i ] = nil;
			evt.sliders[ i ].valueAction = 0;
		};
};

e.coupleSlider = { |evt, i = 0, key, spec, env, name, action| 
	evt.couple( \slider, i, key, spec, env, name, action );
};

e.coupleKnob = { |evt, i = 0, key, spec, env, name, action| 
	evt.couple( \knob, i, key, spec, env, name, action );
};


// hardware set functions

e.hwSet = { |evt, what = \slider, i = 0|
	var j, knob;
	j = i - evt.offset;
	if( j.inclusivelyBetween(0,7) )
		{	switch( what,
				\slider, { evt.hwSetSlider( j, evt.sliders[i].value ) },
				\master, { 
					if( i == 0 ) { // do only once
						evt.hwSetSlider( 8, evt.masterSlider.value ) 
					};
				},
				\softSetSlider, {  evt.hwSoftSetSlider( j, evt.sliders[i].value ) },
				\knob, { 
					knob = evt.knobs[i];
					evt.hwSetKnob( j, knob.value, knob.hiliteColor.notNil, knob.centered  ) 
					},
				\level, { evt.hwSetLevel( j, evt.levelMeters[i].value ) },
				\on, { evt.hwSetButton( j, evt.buttons.on[i].value, \on ) },
				\solo, { evt.hwSetButton( j, evt.buttons.solo[i].value, \solo ) },
				\rec, { evt.hwSetButton( j, evt.buttons.rec[i].value, \rec ) },
				\sel, { evt.hwSetButton( j, evt.buttons.sel[i].value, \sel ) },
				\label, { evt.hwSetText( j, evt.labels[i].string, \label ) },
				\knobLabel, { evt.hwSetText( j, evt.knobLabels[i].string, \knob ) } );
		};
};

e.hwSetAll = { |evt, what = \slider|
	what = what.asArray;
	what.do({ |item|
		8.min(evt.nSliders).do({ |i| evt.hwSet( item, i + evt.offset ); });
	});
};

// direct set functions

e.hwSetSlider = { |evt, i, value|
	evt.m.bend( i, (value * 1023).asInt * 16 ); 
	evt.currentFaderVals[i] = value; // store value
};

/*
e.hwSoftSetSlider = { |evt, i, value, time|
	var startVal, interval = 0.02, nSteps;
	time = time ? evt.sofSetTime;
	evt.hwSoftSetTasks = evt.hwSoftSetTasks ?? { Order( evt.currentFaderVals.size ) };
	evt.hwSoftSetTasks[i].stop;
	startVal = evt.currentFaderVals[i];
	nSteps = (time * (1/interval)).round(1);
	evt.hwSoftSetTasks[ i ] = Task({
		var lastRawVal;
		nSteps.do({ |ii|
			var val, rawVal;
			val = ii.linlin(0, nSteps-1, startVal, value );
			rawVal = (val * 1023).asInt * 16;
			if( lastRawVal != rawVal ) // only update if actually changed (prevent midi overload)
				{ evt.m.bend( i, rawVal ); };
			evt.currentFaderVals[i] = val; // store value
			lastRawVal = rawVal;
			interval.wait;
		});
	}).start;
};
*/

e.hwSoftSetSlider = { |evt, i, value, time|
	var startVal, interval = 0.025, nSteps;
	time = time ? evt.sofSetTime;
	if( time > 0 ) {	
		evt.hwSoftSetTasks = evt.hwSoftSetTasks ?? { Order( evt.currentFaderVals.size ) };
		evt.hwSoftSetTasks[i].stop;
		startVal = evt.currentFaderVals[i];
		nSteps = ((time * (1/interval)) * ((startVal - value).abs.pow(1/8))).round(1);
		//[nSteps, startVal, value ].postln;
		if( nSteps > 0 ) {	
			evt.hwSoftSetTasks[ i ] = Task({
				var lastRawVal;
				nSteps.do({ |ii|
					var val, rawVal;
					interval.wait;
					val = ii.linlin(0, nSteps-1, 0,0.5pi).sin.linlin(0,1, startVal, value );
					//val = ii.linlin(0, nSteps-1, startVal,value);					//rawVal = (val * 1023).asInt * 16;
					rawVal = (val * 127).asInt * 128;
					if( lastRawVal != rawVal ) // only update if actually changed (prevent midi overload)
						{ evt.m.bend( i, rawVal ); };
					evt.currentFaderVals[i] = val; // store value
					lastRawVal = rawVal;
				});
			}).start;
		};
	} {
		evt.hwSetSlider( i, value );
	};
};
 
e.hwSetKnob = { |evt, i, value, hilite = true, centered = true|
	evt.m.control( 0, 16+32+i, 
		 (if( hilite )
		 		{ if ( centered )
		 			{ 16 }
		 			{ 32 };
		 		} { 0 }) +
		 	value.linlin(0,1,1,11).asInt ); 
};

e.hwSetButton = { |evt, i, value, type = \on|
	evt.m.noteOn( 0, i + (solo: 8, on: 16, rec: 0, sel: 24)[type], value * 127 ); 
};

e.hwSetLevel = { |evt, i, value|
	 evt.m.touch( i, value * 10 );
};

e.hwSetText = { |evt, i, string = "", type = \label| // \label or \knob
	var array; 
	if( evt.useSysex == true ) {
		array = Int8Array[ 16rf0, 0, 0, 16r66, 16r14, 16r12 ] ++ 
			Int8Array[ (i*7) + ( label: 0, knob: (8*7) )[ type ] ] ++ 
			string.extend(7,$ ).ascii.as( Int8Array ) ++ 
			Int8Array[ 16rf7 ];
		e.m.sysex( array );
	};		
};

// the window
e.w = Window( "i-Controls Pro", Rect(1440 - 467, 64, ((49 * e.nSliders) + 4), 250), false, scroll: true ).front;

if( e.nSliders <= 8 ) { e.w.view.hasHorizontalScroller = false };

e.w.decorate;
e.font = Font( "Helvetica", 9 );

e.labels = {|i| 
	TextField( e.w, 45@13 ).font_( e.font ).string_( e.initLabels[i] )
		.action_({ |tf| e.hwSet( \label, i); });
	}!e.nSliders;
	
e.knobLabels = {|i| 
	TextField( e.w, 45@13 ).font_( e.font ).string_(e.initKnobLabels[i] )
		.action_({ |tf| e.hwSet( \knobLabel, i ); });
	}!e.nSliders;

e.knobs = { |i| 
	SmoothSlider( e.w, 45@14 )
		.centered_( true )
		.value_( e.initKnobValues[i] )
		.action_({ |sl|
			if( e.active ) { 
				e.actions[\knob][i].value( sl );
				e.actions[\knob][\all].value( sl, i );
			};
			e.hwSet( \knob, i ); });
		}!e.nSliders;

e.soloMute = { |i|  [ 
		RoundButton( e.w, 20@14 ).states_([
				["s", Color.black, Color.white.alpha_(0.5)],
				["s", Color.black, Color.red.blend( Color.white, 0.25).alpha_(0.5)]])
			.border_(1).radius_(4).font_( e.font )
			.action_({ |bt| 
				if( e.active ) { 
					e.actions[\button][\solo][i].value( bt );
					e.actions[\button][\solo][\all].value( bt, i );
					e.actions[\button][\all].value( bt, \solo, i );
				};
				e.hwSet( \solo, i );
				}),
		RoundButton( e.w, 21@14 )
			.states_([	
				["on", Color.black, Color.green.alpha_(0.5)],
				["on", Color.black, Color.white.alpha_(0.5)]
				])
			.border_(1).radius_(4).font_( e.font )
			.action_({ |bt| 
				if( e.active ) { 
					e.actions[\button][\on][i].value( bt );
					e.actions[\button][\on][\all].value( bt, i );
					e.actions[\button][\all].value( bt, \on, i );
				};
				e.hwSet( \on, i ); 
				})
		]
	}!e.nSliders;

e.buttons = ();
e.buttons[ \solo ] = e.soloMute.collect(_[0]);
e.buttons[ \on ] = e.soloMute.collect(_[1]);
	
e.slidersLevelMeters = { |i| 
	[
	SmoothSlider( e.w, 31@(e.w.view.bounds.height - 106) )
		.value_( e.initSliderValues[i] )
		
		.action_({ |sl|
			if( e.active ) { 
				e.actions[\slider][i].value( sl );
				e.actions[\slider][\all].value( sl, i );
			};
			e.hwSet( \slider, i );
			})
			
		.mouseDownAction_({ |sl, x,y|
			if( e.active ) { 
				e.actions[\touch][i].value( sl, 1 );
				e.actions[\touch][\all].value( sl, 1, i );
			};
			{ sl.hiliteColor = Color.blue(0.5).alpha_(0.5); sl.refresh;}.defer;
			})
			
		.mouseUpAction_({ |sl, x,y|
			if( e.active ) { 
				e.actions[\touch][i].value( sl, 0 );
				e.actions[\touch][\all].value( sl, 0, i );
			};
			{ sl.hiliteColor = Color.blue.alpha_(0.5); }.defer;
			})
			
		.resize_(4),
	SmoothSlider( e.w, 10@30)
		.knobColor_( Color.clear )
		.knobSize_( 0 )
		.hiliteColor_( Gradient( Color.web.orange, Color.green, \v ) )
		.action_({ |li| e.hwSet( \level, i ); })
	];
	}!e.nSliders;
	
e.sliders = e.slidersLevelMeters.flop[0];
e.levelMeters = e.slidersLevelMeters.flop[1];
	
e.recordSelect = { |i|  [ 
		RoundButton( e.w, 20@14 ).states_([
				["rec", Color.black, Color.white.alpha_(0.5)],
				["rec", Color.black, Color.red.blend( Color.white, 0.25).alpha_(0.5)]
				]).resize_(7)
			.border_(1).radius_(4).font_( e.font )
			.action_({ |bt| 
				if( e.active ) { 
					e.actions[\button][\rec][i].value( bt );
					e.actions[\button][\rec][\all].value( bt, i );
					e.actions[\button][\all].value( bt, \rec, i );
				};
				e.hwSet( \rec, i );
				}),
		RoundButton( e.w, 21@14 )
			.states_([	
				["sl", Color.black, Color.white.alpha_(0.5)],
				["sl", Color.black, Color.web.orange.alpha_(0.5)]
				]).resize_(7)
			.border_(1).radius_(4).font_( e.font )
			.action_({ |bt| 
				if( e.active ) { 
					e.actions[\button][\sel][i].value( bt );
					e.actions[\button][\sel][\all].value( bt, i );
					e.actions[\button][\all].value( bt, \sel, i );
				};
				e.hwSet( \sel, i );
			 	}),
		]
	}!e.nSliders;
	
e.buttons[ \rec ] =  e.recordSelect.collect(_[0]);
e.buttons[ \sel ] =  e.recordSelect.collect(_[1]);
	
e.w.bounds = e.w.bounds.width_((49 * 8) + 2);

e.w.view.action = { |vw| 
	e.offset = ((vw.visibleOrigin.x - 26) / 49).ceil; 
	if( e.oldOffset != e.offset ) { e.doReset };
	e.oldOffset = e.offset;
	};
	
e.w.onClose = { 
	e.responders.do(_.remove);
	e.mw.close;
};

e.mw = Window( "M", Rect(1440 -70 , 64, 64, 250), false ).front;
e.mw.userCanClose = false;
e.mw.addFlowLayout;

e.masterKnob = SmoothSlider( e.mw, 56@20 );
e.masterKnob.centered = true;
e.masterKnob.value = 0.5;
e.masterKnob.action = { |sl| 
	if( e.active ) { 
		e.actions[ \masterKnob ].value( sl );
		e.actions[ \knob ][ \all ].value( sl );
	};
};

e.masterSlider = SmoothSlider( e.mw, 56@218 );
e.masterSlider.action = { |sl|
	if( e.active ) {  
		e.actions[ \master ].value( sl );
	};
	e.hwSetSlider( 8, sl.value );
};



// from controller
(
e.responders.do(_.remove);

e.responders = [	
	BendResponder({ |port, ch, val| 
		if( e.midiMonitor == true ) {
			[ \bend, ch: ch, val: val ].postln;
		};
		if( ch < 8 ) {
			e.sliders[ch+e.offset].valueAction = (val / 16) / 1023;
		} {
			e.masterSlider.valueAction =  (val / 16) / 1023;
		};
	}, e.port),
		
	CCResponder({ |port, ch, cc, val|
		var mul, velo, i;
		if( e.midiMonitor == true ) {
			[ \cc, ch: ch, cc: cc, val: val ].postln;
		};
		mul = 1/128;
		velo = 1.25;
		i = cc - 16;
		if( val >= 65 ) { val = (64-val) };
		val = (val.abs**e.knobsobVelo) * ( if( val.isNegative ) { -1 } { 1 } );
		if( cc == 60 ) {
			//e.knobs[i+e.offset].delta( val * e.knobsobRes );
			if( e.selected.notNil ) {
				e.sliders[ e.selected ].delta( val * e.knobsobRes * 0.1 );
			};
		} {
			e.knobs[i+e.offset].delta( val * e.knobsobRes );
		};
		}, e.port, chan: 0),
	
	NoteOnResponder({  |port, ch, nn, val|
		var knob;
		//(nn >> 3).postln;
		if( e.midiMonitor == true ) {
			[ \noteOn, ch: ch, nn3: nn >> 3, nn: nn, val: val ].postln;
		};
		switch( nn >> 3,
			0, { e.recordSelect[nn +e.offset][0].mouseDown; },
			1, { e.soloMute[nn +e.offset - 8][0].mouseDown; },
			2, { e.soloMute[nn +e.offset - 16][1].mouseDown; },
			3, { 
				e.recordSelect.flop[1].do({ |bt| bt.valueAction = 0 });
				e.recordSelect[nn +e.offset - 24][1].mouseDown; 
				e.selected = nn +e.offset - 24;
			},
			4, { knob = e.knobs[nn +e.offset - 32];
				if( e.knobPushResets )
				 { if( knob.centered )
					 { knob.valueAction = 0.5; }
					 {  knob.valueAction = 0.0; };
					};
				e.actions[ \knobPush ][ nn +e.offset - 32 ].value( knob );
				e.actions[ \knobPush ][ \all ].value( knob, nn+e.offset -32 );
				 },
			5, {	switch( nn,
					46, { e.offset = (e.offset - 8);
						e.offset = e.offset.clip(0,e.nSliders-8);
						e.actions[ \bank ][ \left ].value( e.offset );
						e.actions[ \bank ][ \all ].value( \left, e.offset );
						}, //bank back
					47, { e.offset = (e.offset + 8);
						e.offset = e.offset.clip(0,e.nSliders-8);
						e.actions[ \bank ][ \right ].value( e.offset );
						e.actions[ \bank ][ \all ].value( \right, e.offset );
						 }); //bank forward
				{e.w.view.visibleOrigin = (((e.offset*49)+1)@0); 
				 e.w.view.doAction; }.defer;
				},
			6, {	switch( nn,
					48, { e.offset = (e.offset - 1); knob = \left;  }, //nudge back
					49, { e.offset = (e.offset + 1); knob = \right;  }); //nudge forward
				e.offset = e.offset.clip(0,e.nSliders-8);
				e.actions[ \bank ][ knob ].value( e.offset );
				e.actions[ \bank ][ \all ].value( knob, e.offset );
				//e.offset.postln;
				{e.w.view.visibleOrigin = (((e.offset*49)+1)@0); 
				 e.w.view.doAction; }.defer;
				},
			12, {
				switch( nn, 
					97, { e.masterKnob.delta( e.masterKnobRes ) },
					96, {  e.masterKnob.delta( e.masterKnobRes.neg ) }
				);
			},
			13, { e.sliders[ nn +e.offset - 104 ].mouseDownAction
					.value( e.sliders[ nn +e.offset - 104 ] );  
			}
			)
		}, e.port, chan: 0),
	
	NoteOffResponder({  |port, ch, nn, val|
		if( e.midiMonitor == true ) {
			[ \noteOff, ch: ch, nn3: nn >> 3, nn: nn, val: val ].postln;
		};
		switch( nn >> 3,
			0, { e.recordSelect[nn +e.offset][0].mouseUp;  },
			1, { e.soloMute[nn +e.offset - 8][0].mouseUp; },
			2, { e.soloMute[nn +e.offset - 16][1].mouseUp; },
			3, { e.recordSelect[nn +e.offset - 24][1].mouseUp; },
			5, { switch( nn, 
				46, { 	e.actions[ \bank ][ \left ].value( 0, e.offset );
						e.actions[ \bank ][ \all ].value( 0, \left, e.offset ); },
				47, { 	e.actions[ \bank ][ \right ].value( 0, e.offset );
						e.actions[ \bank ][ \all ].value( 0, \right, e.offset ); } );
			},
			13, { e.sliders[ nn +e.offset - 104 ].mouseUpAction.value( e.sliders[ nn +e.offset - 104 ] );  }
			)
		}, e.port, chan: 0)
	];
);

// reset
e.doReset = { |evt, dur = 0.35|	
	var oldVals, visibleSliders;
	visibleSliders = e.sliders.select({ |item,i| (i-e.offset).inclusivelyBetween(0,7) });
	e.scrollTask !? { e.scrollTask.stop };
	e.hwSetAll( [ \slider, \master, \knob, \level, \on, \solo, \rec, \sel, \label, \knobLabel ] );
	};
	
e.doReset;

)