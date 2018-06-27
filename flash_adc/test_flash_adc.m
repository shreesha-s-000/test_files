clear;

% subcircuit of one slice of flash adc

fsnet.cktname = 'Flash ADC slice';
% vref and resbot are terminals of the resistor
fsnet.nodenames = {'vref', 'resbot',  'vsig', 'vout', 'gnd'};
fsnet.terminalnames = {'vref', 'resbot', 'vsig', 'vout', 'gnd'};

fsnet = add_element(fsnet, my_comparator(), ...
    'cmp1', {'vsig', 'vref', 'vout', 'gnd'}, ...
    {{'smooth_k', 50.0}, {'out_high', 1.0}});
fsnet = add_element(fsnet, resModSpec(), ...
    'R1', {'vref', 'resbot'}, {{'R', 1e3}});

% completed subcircuit of one slice of flash adc 


% flash adc circuit

cktnetlist.cktname = 'test-flash-adc';

cktnetlist.nodenames = {'vref_top', 'vref1', 'vref2', 'vref3', ...
    'vcmp1', 'vcmp2', 'vcmp3', ...
    'vsig'}; 
cktnetlist.groundnodename = 'gnd';

% add the extra resistor
cktnetlist = add_element(cktnetlist, resModSpec(), ...
	'R1', {'vref_top','vref1'}, {{'R', 1e3}});

% add voltage sources
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'vsig_src', {'vsig','gnd'}, {}, {{'E', {'DC', 0.5}}});

cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
    'vref_src', {'vref_top','gnd'}, {}, {{'E', {'DC', 1.0}}});

% add flash slices
cktnetlist = add_subcircuit(cktnetlist, fsnet, 'cmp1', ...
    {'vref1', 'vref2', 'vsig', 'vcmp1', 'gnd'}, {});
cktnetlist = add_subcircuit(cktnetlist, fsnet, 'cmp2', ...
    {'vref2', 'vref3', 'vsig', 'vcmp2', 'gnd'}, {});
cktnetlist = add_subcircuit(cktnetlist, fsnet, 'cmp3', ...
    {'vref3', 'gnd', 'vsig', 'vcmp3', 'gnd'}, {});


% setup outputs
cktetlist = add_output(cktnetlist, 'vsig');
cktetlist = add_output(cktnetlist, 'vcmp1');
cktetlist = add_output(cktnetlist, 'vcmp2');
cktetlist = add_output(cktnetlist, 'vcmp3');


% get DAE
DAE = MNA_EqnEngine(cktnetlist);


% transient simulation
fclk = 1.0e6;
Nfft = 256.0;
fsigbin = 117.0;
fsig = (fsigbin/Nfft)*fclk;

tranfunc = @(t, args) (args.A*sin(2*pi*args.f*t + args.phi)+0.5);
tranfuncargs.A = 0.49; tranfuncargs.f = fsig; tranfuncargs.phi = 0;
DAE = feval(DAE.set_utransient, 'vsig_src:::E', tranfunc, tranfuncargs, DAE);

xinit = zeros(feval(DAE.nunks, DAE), 1);
tstart = 0; tstep = (1.0/fclk)/50.0; tstop = (Nfft+10.0)*(1.0/fclk);

TRANobj = transient(DAE, xinit, tstart, tstep, tstop);

% plot output
% feval(TRANobj.plot, TRANobj);


% sample the output of flash
[tpts, vals] = feval(TRANobj.getsolution, TRANobj);
% feval(DAE.unknames,DAE)
% required output rows: 5, 6, 7

tleave = 2.0;
tvalssamp = linspace(tleave/fclk, (Nfft+tleave)/fclk, floor(Nfft)+1);
tvalssamp = tvalssamp(1:end-1);
vcmp1samp = interp1(tpts, vals(5,:), tvalssamp);
vcmp2samp = interp1(tpts, vals(6,:), tvalssamp);
vcmp3samp = interp1(tpts, vals(7,:), tvalssamp);

% quantize to 1 or 0
[~, vcmp1samp] = quantiz(vcmp1samp, [0.5], [0,1]);
[~, vcmp2samp] = quantiz(vcmp2samp, [0.5], [0,1]);
[~, vcmp3samp] = quantiz(vcmp3samp, [0.5], [0,1]);

% thermometer to binary
vdec = vcmp1samp + vcmp2samp + vcmp3samp;

% figure(2)
% plot(tvalssamp, vdec, 'b*-');
% figure(3)
% plot(tpts, vals(8,:), 'r*-');

% fft of decimal output
% no windowing required 
vdecfft = fft(vdec);
vdecfft = abs(vdecfft);
vdecfft = vdecfft .* vdecfft;

% figure(4)
% semilogy(vdecfft, 'b*-');

% signal power
sigpwr = vdecfft(floor(fsigbin)+1);

% noise power
vdecfft(1) = 0.0;
vdecfft(floor(fsigbin)+1) = 0;
noisepwr = sum(vdecfft(1:floor(Nfft)/2));

% sqnr and enob
sqnr = 10.0*log10(sigpwr/noisepwr)
enob = (sqnr-1.76)/6.02





