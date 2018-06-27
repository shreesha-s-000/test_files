clear;

cktnetlist.cktname = 'test_ac';

cktnetlist.nodenames = {'n1', 'n2', 'n3'};
cktnetlist.groundnodename = 'gnd';

vGateBiasVal = 1.0;

cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vgate', {'n1','gnd'}, {}, {{'E', {'DC', vGateBiasVal}}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vdd', {'n2','gnd'}, {}, {{'E', {'DC', 2.5}}});
cktnetlist = add_element(cktnetlist, SH_MOS_ModSpec(), ...
    'm1', {'n3', 'n1', 'gnd'}, {{'Type', 'N'}});
cktnetlist = add_element(cktnetlist, resModSpec(), ...
    'r1', {'n2', 'n3'}, {{'R', 5e3}});
cktnetlist = add_element(cktnetlist, capModSpec(), ...
    'c1', {'n3', 'gnd'}, {{'C', 1e-12}});

cktnetlist = add_output(cktnetlist, 'e(n1)');
cktnetlist = add_output(cktnetlist, 'e(n3)');
cktnetlist = add_output(cktnetlist, 'i(Vdd)', -1.0);

DAE = MNA_EqnEngine(cktnetlist);

printf('printing input names\n');
feval(DAE.inputnames, DAE)
printf('printing unknown names\n');
feval(DAE.unknames, DAE)
printf('printing output names\n');
feval(DAE.outputnames, DAE)
printf('done printing\n');

% qss
dcop = op(DAE);
feval(dcop.print, dcop);
xinit = dcop.getSolution(dcop);

% % tran
% fsig = 1e6;
% tranfunc = @(t, args) (args.A*sin(2*pi*args.f*t + args.phi)+vGateBiasVal);
% tranfuncargs.A = 0.05; tranfuncargs.f = fsig; tranfuncargs.phi = 0;
% DAE = feval(DAE.set_utransient, 'Vgate:::E', tranfunc, tranfuncargs, DAE);
% 
% tstart = 0; tstep = (1.0/fsig)/50.0; tstop = (1.0/fsig)*2.0;
% 
% TRANobj = transient(DAE, xinit, tstart, tstep, tstop);
% 
% % plot output
% feval(TRANobj.plot, TRANobj);

% ac analysis
Ufargs.string = 'no args used'; 
Uffunc = @(f, args) 1;
DAE = feval(DAE.set_uLTISSS, 'Vgate:::E', Uffunc, Ufargs, DAE);

% run the AC analysis
uqss = feval(DAE.uQSS, DAE);
sweeptype = 'DEC'; fstart=1; fstop=1e10; nsteps=100;
acobj = ac(DAE, xinit, uqss, fstart, fstop, nsteps, sweeptype);

% plot frequency sweeps of system outputs (overlay all on 1 plot)
feval(acobj.plot, acobj);

% % plot frequency sweeps of state variable outputs (overlay on 1 plot)
% feval(acobj.plot, acobj, stateoutputs);
% 
% % print results for all stateouputs
% feval(acobj.print, acobj, StateOutputs(DAE));
% 
% %get the solution
% [fpts, sol_at_all_fs] = feval(acobj.getsolution, ac); % n x #fpts matrix

             


