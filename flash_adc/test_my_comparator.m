clear;

MOD = my_comparator();
check_ModSpec(MOD, 0);
% success = check_ModSpec(MOD, 1);
% printf('is my comparator a valid ModSpec model: %d\n', success);

cktnetlist.cktname = 'test-comparator';

cktnetlist.nodenames = {'n1', 'n2', 'n3'}; 
cktnetlist.groundnodename = 'gnd';

cktnetlist = add_element(cktnetlist, resModSpec(), ...
	'R1', {'n3','gnd'}, {{'R', 10e3}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vsigp', {'n1','gnd'}, {}, {{'E', {'DC', 0.5}}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vsign', {'n2','gnd'}, {}, {{'E', {'DC', 0.5}}});
cktnetlist = add_element(cktnetlist, my_comparator(), ...
    'cmp1', {'n1', 'n2', 'n3', 'gnd'}, ...
    {{'smooth_k', 50.0}});

cktnetlist = add_output(cktnetlist, 'n1');
cktnetlist = add_output(cktnetlist, 'n2');
cktnetlist = add_output(cktnetlist, 'n3');

% get DAE
DAE = MNA_EqnEngine(cktnetlist);

% run qss analysis
dcop = op(DAE);
feval(dcop.print, dcop);

% run transient analysis
tstart = 0; tstep = 1e-9/100.0; tstop = 5e-9;

tranfunc = @(t, args) (args.A*sin(2*pi*args.f*t + args.phi)+0.5);
tranfuncargs.A = 0.2; tranfuncargs.f = 1e9; tranfuncargs.phi = 0;
tranfuncargs2.A = 0.2; tranfuncargs2.f = 1e9; tranfuncargs2.phi = pi;

DAE = feval(DAE.set_utransient, 'Vsigp:::E', tranfunc, tranfuncargs, DAE);
DAE = feval(DAE.set_utransient, 'Vsign:::E', tranfunc, tranfuncargs2, DAE);

% Set the initial condition to the DC op point above
xinit = feval(dcop.getsolution, dcop);
% transient simulation and plot the cktnetlist-defined outputs:
TRANobj = transient(DAE, xinit, tstart, tstep, tstop);
feval(TRANobj.plot, TRANobj);

% plot every circuit unknown (ie, its state vector) in another figure 
% souts = StateOutputs(DAE);
% feval(TRANobj.plot, TRANobj, souts);



