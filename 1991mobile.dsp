declare name "Michelangelo Lupone. Mobile Locale - 1991";
declare version "001";
declare author "Giuseppe Silvi";
declare copyright "Giuseppe Silvi 2019";
declare reference "giuseppesilvi.com";
declare description "Michelangelo Lupone, Mobile Locale - FLY30 Porting";

import("stdfaust.lib");

oscgroup(x) = hgroup("[01] OSCILLATOR", x);

poscil = oscgroup(os.oscsin(freq) : *(amp) : +(amp))
  with{
    freq = vslider("[01] QF [style:knob]", 0.1,0.1,320,0.01) : si.smoo;
    amp = vslider("[02] QA [style:knob]", 0.5,0.0,0.5,0.01) : si.smoo;
  };

qaqf(x) = de.fdelayltv(1,writesize, poscil*(writesize), x) : *(gain) <: _,_*(0),_,*(0)
  with{
    writesize = ba.sec2samp(0.046);
    gain = oscgroup(vslider("[03] GAIN [style:knob]", 0,0,5,0.01) : si.smoo);
  };

er8comb = _ <:
  0.5*(fi.fb_comb(ma.SR, ba.sec2samp(0.087),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.026),.5,.5)),
  0.5*(fi.fb_comb(ma.SR, ba.sec2samp(0.032),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.053),.5,.5)),
  0.5*(fi.fb_comb(ma.SR, ba.sec2samp(0.074),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.047),.5,.5)),
  0.5*(fi.fb_comb(ma.SR, ba.sec2samp(0.059),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.022),.5,.5)) <:
  *(gain), *(gain), *(gain), *(gain),_,_,_,_
    with{
      gain = hgroup("[02] ER COMB",vslider("[01] ER OUT [style:knob]", 0,0,1.5,0.01) : si.smoo);
  };

envelop         = abs : max ~ -(1.0/ma.SR) : max(ba.db2linear(-70)) : ba.linear2db;

inhmeter(x)		= attach(x, envelop(x) : hbargraph("[01] IN [unit:dB]", -70, +5));

h1meter(x)		= attach(x, envelop(x) : hbargraph("[1] CH 1[unit:dB]", -70, +5));
h2meter(x)		= attach(x, envelop(x) : hbargraph("[2] CH 2[unit:dB]", -70, +5));
h3meter(x)		= attach(x, envelop(x) : hbargraph("[3] CH 3[unit:dB]", -70, +5));
h4meter(x)		= attach(x, envelop(x) : hbargraph("[4] CH 4[unit:dB]", -70, +5));

tableSize = 48000;

delsize1 = ba.sec2samp(0.46) : int;
recIndex1 = (+(1) : %(delsize1)) ~ *(1);
readIndex1 = 1.02246093/float(ma.SR) : (+ : ma.decimal) ~ _ : *(float(tableSize)) : int;
fdel1 = rwtable(tableSize,0.0,recIndex1,_,readIndex1);

delsize2 = ba.sec2samp(0.23) : int;
recIndex2 = (+(1) : %(delsize2)) ~ *(1);
readIndex2 = 0.99699327/float(ma.SR) : (+ : ma.decimal) ~ _ : *(float(tableSize)) : int;
fdel2 = rwtable(tableSize,0.0,recIndex2,_,readIndex2);

fdelgroup(x) = hgroup("[03] FEEDBACK DELAY", x);

waf = fdelgroup(vslider("[01] WA FEEDBACK [style:knob]", 0.,0.,1.0,0.01)) : si.smoo;
wag = fdelgroup(vslider("[01] WA GAIN [style:knob]", 0.,0.,1.0,0.01)) : si.smoo;
wa = *(wag) : ( - : fdel1) ~ *(waf);

zaf = fdelgroup(vslider("[01] ZA FEEDBACK [style:knob]", 0.,0.,1.0,0.01)) : si.smoo;
zag = fdelgroup(vslider("[01] ZA GAIN [style:knob]", 0.,0.,1.0,0.01)) : si.smoo;
za = *(zag) : ( - : fdel2) ~ *(zaf);

fbdel = 0.25*(_+_+_+_) <: wa, za <: _,_,_,_;

ingain = hslider("[00] INPUT GAIN", 0, -70, +12, 0.1) : ba.db2linear : si.smoo;
process = _*(ingain) : inhmeter <: hgroup("[01] MAIN", qaqf, er8comb : si.bus(8), fbdel) :> vgroup("[99]OUTPUT METERS", h1meter,h2meter,h3meter,h4meter) :> _,_;
