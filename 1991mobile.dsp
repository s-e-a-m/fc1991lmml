declare name "Michelangelo Lupone. Mobile Locale - 1991";
declare version "001";
declare author "Giuseppe Silvi";
declare copyright "Giuseppe Silvi 2019";
declare reference "giuseppesilvi.com";
declare description "Michelangelo Lupone, Mobile Locale - FLY30 Porting";

import("stdfaust.lib");

//----------------------------------------------------------------------- GROUPS
maingroup(x) = hgroup("[01] MAIN", x);
qaqfgroup(x) = maingroup(hgroup("[01] QA & QF", x));
oscgroup(x) = qaqfgroup(hgroup("[01] OSCILLATOR", x));
delgroup(x) = qaqfgroup(hgroup("[02] DELAY", x));
ergroup(x) = maingroup(hgroup("[02] EARLY REFLECTIONS", x));

//-------------------------------------------------- UNIPOLAR POITIVE OSCILLATOR
poscil = oscgroup(os.oscsin(freq) : *(amp) : +(amp))
   with{
     posctrl = vgroup("[01] POSC", x);
     freq = posctrl(vslider("[01] QF FRQ [style:knob] [midi:ctrl 2]", 0.1,0.1,320,0.01)) : si.smoo;
     amp = posctrl(vslider("[02] QA AMP [midi:ctrl 81]", 0.5,0.0,0.5,0.01)) : si.smoo;
   };

//process = poscil;

//------------------------------------------------------------------------ QA&QF
qaqf(x) = de.fdelayltv(1,writesize, readindex, x) : *(gain) <: _,*(0),_,*(0)
  with{
    writesize = ba.sec2samp(0.046);
    readindex = poscil*(writesize);
    gain = delgroup(vslider("[03] QA GAIN [midi:ctrl 82]", 0,0,5,0.01) : si.smoo);
  };

//process = qaqf;

//------------------------------------------------------------ EARLY REFLECTIONS
er8comb = _ <:
  g1*(0.5*(fi.fb_comb(maxdel,er1,b0,aN) + fi.fb_comb(maxdel,er2,b0,aN))),
  g2*(0.5*(fi.fb_comb(maxdel,er3,b0,aN) + fi.fb_comb(maxdel,er4,b0,aN))),
  g3*(0.5*(fi.fb_comb(maxdel,er5,b0,aN) + fi.fb_comb(maxdel,er6,b0,aN))),
  g4*(0.5*(fi.fb_comb(maxdel,er7,b0,aN) + fi.fb_comb(maxdel,er8,b0,aN)))
    with{
      maxdel = ma.SR/10 : int;
      er1 = ba.sec2samp(0.087) : int;
      er2 = ba.sec2samp(0.026) : int;
      er3 = ba.sec2samp(0.032) : int;
      er4 = ba.sec2samp(0.053) : int;
      er5 = ba.sec2samp(0.074) : int;
      er6 = ba.sec2samp(0.047) : int;
      er7 = ba.sec2samp(0.059) : int;
      er8 = ba.sec2samp(0.022) : int;
      b0 = .5; // gain applied to delay-line input and forwarded to output
      aN = .5; // minus the gain applied to delay-line output before sum
      g1 = ergroup(vslider("[01] ER GAIN1 [style:knob][midi:ctrl 83]", 0,0,1.5,0.01)) : si.smoo;
      g2 = ergroup(vslider("[02] ER GAIN2 [style:knob][midi:ctrl 84]", 0,0,1.5,0.01)) : si.smoo;
      g3 = ergroup(vslider("[03] ER GAIN3 [style:knob][midi:ctrl 85]", 0,0,1.5,0.01)) : si.smoo;
      g4 = ergroup(vslider("[04] ER GAIN4 [style:knob][midi:ctrl 86]", 0,0,1.5,0.01)) : si.smoo;
  };

ermix = +++:>*(0.25);

//------------------------------------------------------------------------ WA&ZA
waza = _ <: wa, za <: _,_,_,_
  with{
    fdelgroup(x) = maingroup(hgroup("[03] FEEDBACK DELAY", x));
    tableSize = 96000; // 0.5 ma.SR at 192000
    delsize1 = ba.sec2samp(0.46) : int;
    // WA
    recIndex1 = (+(1) : %(delsize1)) ~ *(1);
    readIndex1 = 1.02246093/float(delsize1) : (+ : ma.decimal) ~ _ : *(float(delsize1)) : int;
    fdel1 = rwtable(tableSize,0.0,recIndex1,_,readIndex1);
    wa = *(wag) : ( ro.cross(2) : - : fdel1) ~ *(waf);
    // ZA
    delsize2 = ba.sec2samp(0.23) : int;
    recIndex2 = (+(1) : %(delsize2)) ~ *(1);
    readIndex2 = 0.99699327/float(delsize2) : (+ : ma.decimal) ~ _ : *(float(delsize2)) : int;
    fdel2 = rwtable(tableSize,0.0,recIndex2,_,readIndex2);
    za = *(zag) : ( ro.cross(2) : - : fdel2) ~ *(zaf);
    // WA&ZA INTERFACE
    waf = fdelgroup(vslider("[01] WA FEEDBACK [style:knob] [midi:ctrl 3]", 0.,0.,1.0,0.01)) : si.smoo;
    wag = fdelgroup(vslider("[01] WA GAIN [style:knob][midi:ctrl 87]", 0.,0.,1.0,0.01)) : si.smoo;
    zaf = fdelgroup(vslider("[01] ZA FEEDBACK [style:knob] [midi:ctrl 4]", 0.,0.,1.0,0.01)) : si.smoo;
    zag = fdelgroup(vslider("[01] ZA GAIN [style:knob][midi:ctrl 88]", 0.,0.,1.0,0.01)) : si.smoo;
};

//------------------------------------------------------------------------- MAIN
//------------------------------------- here only the objects described in score
main = _ <: qaqf, (er8comb <: si.bus(4), (ermix : waza)) :> _,_,_,_;


input = hgroup("[01] INPUT", *(ingain) : inmeter)
  with{
    ingain = vslider("[00] GAIN [midi:ctrl 1]", 0, -70, +12, 0.1) : ba.db2linear : si.smoo;
    inmeter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[01] METER [unit:dB]", -70, +5));
  };

//---------------------------------------------------------------- OUTPUT SECTION
outs = hgroup("[99] OUTPUT METERS", ch1meter, ch2meter, ch3meter, ch4meter)
  with{
    ch1meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[01] CH 1[unit:dB]", -70, +5));
    ch2meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[02] CH 2[unit:dB]", -70, +5));
    ch3meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[03] CH 3[unit:dB]", -70, +5));
    ch4meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[04] CH 4[unit:dB]", -70, +5));
  };

//----------------------------------------------------------------------- LR-MIX
lrmix = _,_; // only for monitoring, not for live

process = hgroup("",input : main : outs) ; // :> lrmix ;
