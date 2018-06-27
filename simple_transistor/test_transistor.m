clear;

cktnetlist.cktname = 'test-transistor';

cktnetlist.nodenames = {'n1', 'n2', 'n3', 'n4'};
cktnetlist.groundnodename = 'gnd';

cktnetlist = add_element(cktnetlist, resModSpec(), ...
	'R1', {'n1','n2'}, {{'R', 5e3}});
cktnetlist = add_element(cktnetlist, capModSpec(), ...
	'C1', {'n2','gnd'}, {{'C', 1e-16}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vbias', {'n3','n4'}, {}, {{'E', {'DC', 1.0}}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vdd', {'n1','gnd'}, {}, {{'E', {'DC', 2.5}}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vsig', {'n4','gnd'}, {}, {{'E', {'DC', 0.0}}});
cktnetlist = add_element(cktnetlist, SH_MOS_ModSpec(), ...
	'M1', {'n2','n3', 'gnd'}, {{'Type', 'N'}});

cktnetlist = add_output(cktnetlist, 'n4');
cktnetlist = add_output(cktnetlist, 'n3');
cktnetlist = add_output(cktnetlist, 'n2');

DAE = MNA_EqnEngine(cktnetlist);

dcop = op(DAE);
feval(dcop.print, dcop);

% xinit = zeros(feval(DAE.nunks, DAE), 1);
display(feval(DAE.nunks, DAE));

% Display DAE's inputs:
feval(DAE.inputnames, DAE)
tstart = 0; tstep = 0.25e-10; tstop = 5e-9;
tranfunc = @(t, args) (args.A*sin(2*pi*args.f*t + args.phi)+0.1);
tranfuncargs.A = 0.1; tranfuncargs.f = 1e9; tranfuncargs.phi = 0;
% input is set, the DC input will not be used in transient simulation
DAE = feval(DAE.set_utransient, 'Vsig:::E', tranfunc, tranfuncargs, DAE);
% Set the initial condition to the DC op point above
xinit = feval(dcop.getsolution, dcop);
% rerun transient simulation and plot the cktnetlist-defined outputs:
TRANobj = transient(DAE, xinit, tstart, tstep, tstop);
feval(TRANobj.plot, TRANobj);
% plot every circuit unknown (ie, its state vector) in another figure 
% souts = StateOutputs(DAE);
% feval(TRANobj.plot, TRANobj, souts);

% check if the dcop is still the same as before
dcop2 = op(DAE);
[~, iters, success] = feval(dcop2.getsolution, dcop2);
printf('number of iters = %f\n', iters);
printf('is dc op successfull = %f\n', success);
feval(dcop2.print, dcop2);


