clear;

MOD = my_differentiator();
check_ModSpec(MOD, 0);
% success = check_ModSpec(MOD, 1);
% printf('is my comparator a valid ModSpec model: %d\n', success);

cktnetlist.cktname = 'test-my-differentiator';

cktnetlist.nodenames = {'n1', 'n2'}; 
cktnetlist.groundnodename = 'gnd';

cktnetlist = add_element(cktnetlist, resModSpec(), ...
	'R1', {'n2','gnd'}, {{'R', 10e3}});
cktnetlist = add_element(cktnetlist, vsrcModSpec(), ...
	'Vsig', {'n1','gnd'}, {}, {{'E', {'DC', 0.5}}});
cktnetlist = add_element(cktnetlist, my_differentiator(), ...
    'd1', {'n1', 'n2', 'gnd'});

cktnetlist = add_output(cktnetlist, 'n1');
cktnetlist = add_output(cktnetlist, 'n2');

% get DAE
DAE = MNA_EqnEngine(cktnetlist);

% run qss analysis
dcop = op(DAE);
feval(dcop.print, dcop)

% run transient analysis
tstart = 0; tstep = 1.0/50.0; tstop = 10.0;

tranfunc = @(t, args) (args.A*sin(t + args.phi)+0.5);
tranfuncargs.A = 0.2; tranfuncargs.phi = 0;

DAE = feval(DAE.set_utransient, 'Vsig:::E', tranfunc, tranfuncargs, DAE);

% Set the initial condition to the DC op point above
xinit = feval(dcop.getsolution, dcop);
% transient simulation and plot the cktnetlist-defined outputs:
TRANobj = transient(DAE, xinit, tstart, tstep, tstop);
feval(TRANobj.plot, TRANobj);
% 
% % plot every circuit unknown (ie, its state vector) in another figure 
% % souts = StateOutputs(DAE);
% % feval(TRANobj.plot, TRANobj, souts);
% 
% 
% 
