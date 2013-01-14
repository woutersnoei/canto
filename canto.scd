// Canto Ostinato :: Simeon Ten Holt
//
// version for harp and electronics
// W. Snoei 2012

(

~canto = ~canto ? EM();

~canto.latency = (64 + 64)/44100;

~canto.path = thisProcess.nowExecutingPath.dirname;

~canto.fileNames = [
	"midi import",
	"play",
	"window",
	"icontrols",
	"reverb",
	"recbuf",
	//"loop",
	"delays",
	"revDelay",
	"freeze",
	"fastFreeze",
	"clicks",
	"bass drum",
	"nanokontrol",
].collect({ |item| ~canto.path +/+ "canto" + item ++ ".scd" });

~canto.fileNames.do(_.load);

~canto.fileWindow !? _.close;

~canto.fileWindow = Window( "canto files", 
		Rect( 9, 366, 130, (~canto.fileNames.size * 20) + 4 ) 
).front;

~canto.fileWindow.addFlowLayout;

~canto.fileNames.do({ |item|
	RoundButton( ~canto.fileWindow, 122 @ 16 )
		.label_( item.basename )
		.action_({ Document.open( item ) });
});

)