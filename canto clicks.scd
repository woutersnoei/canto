(
x.do(_.free);
x = 4.collect({ |i| 
	{ |spd = 285, modSpeed = 0.1|
		var trig, env;
		trig = T2A.ar( In.kr(1) > 0.9 );
		trig = TDuty.ar( 60/spd, trig ); 
		trig = Trig.ar( trig, LFDNoise3.kr(modSpeed).exprange(1/10000,1/200) ) * GrayNoise.ar(1);
		trig = BLowCut.ar( trig, LFDNoise3.kr(modSpeed).exprange(50,5000).clip(20,20000), 5 );
		trig = BHiCut.ar( trig, LFDNoise3.kr(modSpeed).exprange(200,20000).clip(20,20000), 5 );
		//env = Env([1,0],[2]).kr(2);
		RoundPan.ar( 4, trig * 0.1, LFDNoise3.kr(modSpeed) );
	}.play( args: [\spd, 57 * (i+2)] );
});
)

x.do({ |item, i| item.set( \spd, 57 * (i+2)); });

x.do({ |item, i| item.set( \modSpeed, 2); });
x.do({ |item, i| item.set( \modSpeed, 0.1); });
x.do(_.free);