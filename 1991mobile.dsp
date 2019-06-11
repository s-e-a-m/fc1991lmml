import("stdfaust.lib");
//
// inspect(i, lower, upper) = _ <: attach(_ ,
//                                        _ : vbargraph("sig_%i [style:numerical]",
//                                                        lower,
//                                                        upper));

oscillator = hgroup("[01] OSCILLATOR", os.oscsin(freq) : *(ampl) : +(offset))
  with{
    freq = vslider("[01] FREQUENCY [style:knob]", 1,0.1,320,0.1) : si.smoo;
    ampl = vslider("[02] AMPLITUDE [style:knob]", 0,0,1,0.01) : si.smoo;
    offset = vslider("[03] OFFSET [style:knob]", 0,0,1,0.01) : si.smoo;
};

delay_line(step,x) = de.fdelayltv(1,ba.sec2samp(0.046), ba.sec2samp(0.046)*(step), x)
  with{
    step = oscillator;
  };

gain = vslider("[02] GAIN [style:knob]", 0,0,5,0.01) : si.smoo;

early_reflections_8_comb_filters = _ <:
  fi.fb_comb(ma.SR, ba.sec2samp(0.087),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.026),.5,.5),
  fi.fb_comb(ma.SR, ba.sec2samp(0.032),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.053),.5,.5),
  fi.fb_comb(ma.SR, ba.sec2samp(0.074),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.047),.5,.5),
  fi.fb_comb(ma.SR, ba.sec2samp(0.059),.5,.5) + fi.fb_comb(ma.SR, ba.sec2samp(0.022),.5,.5) <: _,_,_,_,+++;

// linee di ritardo con scrittura e lettura indipendenti
// parametri condivisi
tableSize = 262144;
counter = +(1)~_;
// parametri particolari UNO
del1 = 0.046;
step1 = 1.02246093;
maxdel1 = ba.sec2samp(del1) : int;
recIndex1 = (counter : %(maxdel1));
readIndex1 = step1/float(ma.SR) : (+ : ma.decimal) ~ _ : *(float(maxdel1)) : int;
rw_del1 = _ : rwtable(tableSize,0.0,recIndex1,_,readIndex1);
rw_del_fb1 = *(1.0) : (- : rw_del1) ~ *(1.0);
// parametri particolari DUE
del2 = 0.023;
step2 = 0.99609327;
maxdel2 = ba.sec2samp(del2) : int;
recIndex2 = (counter : %(maxdel2));
readIndex2 = step2/float(ma.SR) : (+ : ma.decimal) ~ _ : *(float(maxdel2)) : int;
rw_del2 = _ : rwtable(tableSize,0.0,recIndex2,_,readIndex2);
rw_del_fb2 = *(1.0) : (- : rw_del2) ~ *(1.0);

run = oscillator, _ <: delay_line, !,_ : *(gain), early_reflections_8_comb_filters <: _,_,_,_,_,rw_del_fb1,!,!,!,!,!,rw_del_fb2;

info = vgroup("INFO",
       hgroup("[01] System", sr_info, block_info),
       hgroup("[02] Delays", del1_info, del2_info))
  with{
    sr_info = ma.SR : hbargraph("[01] SR [style:numerical]",0,192000);
    block_info = ma.BS : hbargraph("[02] BS [style:numerical]",0,4092);
    del1_info = maxdel1 : hbargraph("[01] Max Delay 1 [style:numerical] [unit:samples]",0,262144);
    del2_info = maxdel2 : hbargraph("[02] Max Delay 2 [style:numerical] [unit:samples]",0,262144);
  };

process = run, info;
