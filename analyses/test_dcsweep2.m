clear;

cktnetlist.cktname = 'test_dcsweep2';

cktnetlist.nodenames = {'n1', 'n2'};
cktnetlist.groundnodename = 'gnd';

cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vgate', {'n1','gnd'}, {}, {{'E', {'DC', 1.0}}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vdd', {'n2','gnd'}, {}, {{'E', {'DC', 2.5}}});
cktnetlist = add_element(cktnetlist, SH_MOS_ModSpec(), ...
	'm1', {'n2', 'n1', 'gnd'}, {{'Type', 'N'}});

% cktnetlist = add_output(cktnetlist, 'e(n1)');
% cktnetlist = add_output(cktnetlist, 'e(n2)');
cktnetlist = add_output(cktnetlist, 'i(Vdd)', -1.0);

DAE = MNA_EqnEngine(cktnetlist);

printf('printing input names\n');
feval(DAE.inputnames, DAE)
printf('printing unknown names\n');
feval(DAE.unknames, DAE)
printf('printing output names\n');
feval(DAE.outputnames, DAE)
printf('done printing\n');

% % qss
% dcop = op(DAE);
% feval(dcop.print, dcop);
% 
% % tran
% fsig = 1e9;
% tranfunc = @(t, args) (args.A*sin(2*pi*args.f*t + args.phi)+0.5);
% tranfuncargs.A = 0.49; tranfuncargs.f = fsig; tranfuncargs.phi = 0;
% DAE = feval(DAE.set_utransient, 'Vgate:::E', tranfunc, tranfuncargs, DAE);
% 
% % xinit = zeros(feval(DAE.nunks, DAE), 1);
% xinit = dcop.getSolution(dcop);
% tstart = 0; tstep = (1.0/fsig)/50.0; tstop = (1.0/fsig)*2.0;
% 
% TRANobj = transient(DAE, xinit, tstart, tstep, tstop);
% 
% % plot output
% feval(TRANobj.plot, TRANobj);

% dcsweep2
swpobj = dcsweep2(DAE, [], 'Vgate:::E', 0.0:0.2:2.5, 'Vdd:::E', 0.0:0.2:2.5);
% plot
feval(swpobj.plot, swpobj, 3);


