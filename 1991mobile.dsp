declare name "Michelangelo Lupone. Mobile Locale - 1991";
declare version "020";
declare author "Giuseppe Silvi";
declare license "GNU-GPL-v3";
declare copyright "(c)SEAM 2019";
declare description "Michelangelo Lupone, Mobile Locale - FLY30 Porting";
declare options "[midi:on]";

import("stdfaust.lib");
import("../faust-libraries/seam.lib");

//----------------------------------------------------------------------- GROUPS
maingroup(x) = hgroup("[01] MAIN", x);
qaqfgroup(x) = maingroup(hgroup("[01] QA and QF", x));
oscgroup(x) = qaqfgroup(hgroup("[01] OSCILLATOR", x));
delgroup(x) = qaqfgroup(hgroup("[02] DELAY", x));
ergroup(x) = maingroup(hgroup("[02] EARLY REFLECTIONS", x));
fdelgroup(x) = maingroup(hgroup("[03] FEEDBACK DELAY", x));

//-------------------------------------------------- UNIPOLAR POITIVE OSCILLATOR
poscil = oscgroup(os.oscsin(freq) : *(amp) : +(amp) <: attach(_, vbargraph("[03] INDEX",0.,1.)))
   with{
     posctrl(x) = vgroup("[01] OSC", x);
     //freq = posctrl(vslider("[01] QF FRQ [style:knob] [midi:ctrl 1]", 0.1,0.1,320,0.01)) : si.smoo;
     freq = posctrl(nentry("[01] QF [midi:ctrl 1]
                    [style:radio{
                    '320Hz':320;
                    '22Hz':22;
                    '8Hz':8;
                    '0.1Hz':0.1}]", 320, 0, 320, 1)) : si.smoo;
     amp = posctrl(vslider("[02] QA [midi:ctrl 81]", 1.0,0.0,1.0,0.01)) : *(0.5) : si.smoo;
   };

//process = poscil;

//------------------------------------------------------------------------ QA&QF
qaqf(x) = de.fdelayltv(1,writesize, readindex, x) : *(gain) <: _,*(0),_,*(0)
  with{
    writesize = ba.sec2samp(0.046);
    readindex = poscil*(writesize);
    gain = delgroup(vslider("[03] QA [midi:ctrl 82]", 0, 0, 1, 0.01) : si.smoo);
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
      g1 = ergroup(vslider("[01] ER 1 [midi:ctrl 83]", 0,0,1,0.01)) : si.smoo;
      g2 = ergroup(vslider("[02] ER 2 [midi:ctrl 84]", 0,0,1,0.01)) : si.smoo;
      g3 = ergroup(vslider("[03] ER 3 [midi:ctrl 85]", 0,0,1,0.01)) : si.smoo;
      g4 = ergroup(vslider("[04] ER 4 [midi:ctrl 86]", 0,0,1,0.01)) : si.smoo;
  };

ermix = +++:>*(0.25);

//------------------------------------------------------------------------ WA&ZA
waza = _ <: wa, za <: _,_,_,_
  with{
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
    wgroup(x) = fdelgroup(vgroup("[01] WA", x));
    waf = wgroup(vslider("[01] WAFB [style:knob] [midi:ctrl 7]", 0.,0.,1.0,0.01)) : si.smoo;
    wag = wgroup(vslider("[02] WAG [midi:ctrl 87]", 0.,0.,1.0,0.01)) : si.smoo;
    zgroup(x) = fdelgroup(vgroup("[02] ZA", x));
    zaf = zgroup(vslider("[01] ZAFB [style:knob] [midi:ctrl 8]", 0.,0.,1.0,0.01)) : si.smoo;
    zag = zgroup(vslider("[02] ZAG [midi:ctrl 88]", 0.,0.,1.0,0.01)) : si.smoo;
};

//------------------------------------------------------------------------------
//------------------------------------------------------------------------- MAIN
//------------------------------------- here only the objects described in score
main = _ <: qaqf, (er8comb <: si.bus(4), (ermix : waza)) :> _,_,_,_;

//---------------------------------------------- INPUT MICROPHONES AND INPUT MIX
amic = hgroup("[01] MIC A", chstrip : *(ingain) : inmeter);
bmic = hgroup("[02] MIC B", chstrip : *(ingain) : inmeter);
cmic = hgroup("[03] MIC C", chstrip : *(ingain) : inmeter);
dmic = hgroup("[04] MIC D", chstrip : *(ingain) : inmeter);
emic = hgroup("[05] MIC E", chstrip : *(ingain) : inmeter);
fmic = hgroup("[06] MIC F", chstrip : *(ingain) : inmeter);
gmic = hgroup("[07] MIC G", chstrip : *(ingain) : inmeter);
hmic = hgroup("[07] MIC H", chstrip : *(ingain) : inmeter);

input = hgroup("[01] INPUT MIX", inpeq : svmeter);

ingain = vslider("[02] GAIN", 0, -70, +12, 0.1) : ba.db2linear : si.smoo;
inmeter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[03] METER [unit:dB]", -70, +5));

microphones = si.bus(18) <: hgroup("[01] MIC A B C D", amic, bmic, cmic, dmic), hgroup("[02] MIC E F G H", emic, fmic, gmic, hmic);

//------------------------------------------------------------------------------
//--------------------------------------------------------------- OUTPUT SECTION
//------------------------------------------------------- 4ch 1-3 LEFT 2-4 RIGHT
// outs = hgroup("[99] OUTPUT METERS", outfbank , ch2meter, ch3meter, ch4meter)
//   with{
//     ch1meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[01] CH 1[unit:dB]", -70, +5));
//     ch2meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[02] CH 2[unit:dB]", -70, +5));
//     ch3meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[03] CH 3[unit:dB]", -70, +5));
//     ch4meter(x) = attach(x, an.amp_follower(0.150, x) : ba.linear2db : vbargraph("[04] CH 4[unit:dB]", -70, +5));
//   };

outs = par(i, 4, out(i));

//----------------------------------------------------------------------- LR-MIX
lrmix = _,_; // only for monitoring, not for live

process = tgroup("PANELS", microphones :> hgroup("[03] MAIN", input : main : outs));// :> lrmix ;
