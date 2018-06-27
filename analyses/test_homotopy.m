clear;



% MOD = ee_model();
% MOD = add_to_ee_model(MOD, 'name', 'vEQcubicINi');
% MOD = add_to_ee_model(MOD, 'terminals', {'p', 'n'});
% MOD = add_to_ee_model(MOD, 'explicit_outs', {'vpn'});
% MOD = add_to_ee_model(MOD, 'params', {'A', 3, 'B', -2, 'C', 1});
% MOD = add_to_ee_model(MOD, 'params', {'I', 1});
% %% note: scaling the current to, eg, mA currently causes numerical problems
% %% in homotopy - because MAPP does not yet have proper scaling support.
% %% Replace the two lines above by the two lines below to see the problem:
% % MOD = add_to_ee_model(MOD, 'params', {'A', 3e9, 'B', -2e3, 'C', 1});
% % MOD = add_to_ee_model(MOD, 'params', {'I', 1e-3});
% fe = @(S) S.A*(S.ipn-S.I)^3 + S.B*(S.ipn-S.I) + S.C; % vpn = cubic in ipn
% MOD = add_to_ee_model(MOD, 'fe', fe);
% MOD = finish_ee_model(MOD);
% 
% check_ModSpec(MOD, 0); % 2nd arg: 1 => verbose output, 0 => final result only
% 
% % set up a circuit netlist for characteristic curves (vsrc across the device)
% clear ntlst;
% ntlst.cktname = 'vsrc+hys_element';
% ntlst.nodenames = {'1'};
% ntlst.groundnodename = 'gnd';
% ntlst = add_element(ntlst, vsrcModSpec(), 'vsrc', {'1', 'gnd'}, {}, ...
% {'DC', 0});
% ntlst = add_element(ntlst, MOD, 'hys_element', {'1', 'gnd'});
% ntlst = add_output(ntlst, 'i(vsrc)', -1); % current through voltage source
% % scaled by -1
% ntlst = add_output(ntlst, 'v(1)'); % voltage at node 1
% 
% % set up a DAE from the ckt netlist
% DAE = MNA_EqnEngine(ntlst);
% 
% % run homotopy on the circuit
% lambdaName = 'vsrc:::E'; % voltage of vsrc
% inputORparm = 'input';
% startLambda = 0; stopLambda = 2; lambdaStep = 0.01;
% initguess = 0;
% 
% homObj = homotopy(DAE, lambdaName, inputORparm, initguess, startLambda, ...
% lambdaStep, stopLambda);
% 
% feval(homObj.plot, homObj); % plot DAE-defined outputs wrt lambda
% feval(homObj.plotVsArcLen, homObj); % plot DAE-defined outputs wrt arc-length
% feval(homObj.plot, homObj, StateOutputs(DAE)); % plot all unknowns wrt lambda






% DAE for a BJT Schmitt Trigger circuit
DAE =  BJTschmittTrigger('BJTschmittTrigger');
Vinval = 0.6;
DAE = feval(DAE.set_uQSS, 'Vin', Vinval, DAE); % fix input Vin to DC value 0.6

lambdaName = 'VCC'; % VCC is a parameter of the DAE
inputORparm = 'param';
startLambda = 0;
stopLambda = 5;
lambdaStep = 0.1;

% this system is very sensitive to the initial guess (this DAE does not
% implement init/limiting to help regular DC solution)
diodedrop = 0.7;
initguess = [Vinval-diodedrop; ...
Vinval-diodedrop; ...
0.75*(Vinval-diodedrop); ...
0.75*(Vinval-diodedrop)-diodedrop];

homObj = homotopy(DAE, lambdaName, inputORparm, initguess, startLambda, ...
lambdaStep, stopLambda);

feval(homObj.plot, homObj); % plot DAE-defined outputs wrt lambda
feval(homObj.plotVsArcLen, homObj); % plot DAE-defined outputs wrt arc-length
feval(homObj.plot, homObj, StateOutputs(DAE)); % plot all unknowns wrt lambda

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%% Example 3: homotopy wrt an input of a BJT Schmitt Trigger circuit %%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % DAE for a BJT Schmitt Trigger circuit
% DAE =  BJTschmittTrigger('BJTschmittTrigger');
% 
% lambdaName = 'Vin'; % Vin is an input of the DAE
% inputORparm = 'input';
% startLambda = 5; % sweeping from high to low value
% stopLambda = 0;
% lambdaStep = 0.01;
% maxLambdaStep = lambdaStep; % this is needed for this example
% 
% % this system is very sensitive to the initial guess (this DAE does not
% % implement init/limiting to help regular DC solution)
% initguess = [4.3656;4.3678;3.2742;5.0000]; % had to be found by
% % continuation forward
% 
% homObj = homotopy(DAE, lambdaName, inputORparm, initguess, startLambda, ...
% lambdaStep, stopLambda, maxLambdaStep);
% 
% feval(homObj.plot, homObj); % plot DAE-defined outputs wrt lambda
% feval(homObj.plotVsArcLen, homObj); % plot DAE-defined outputs wrt arc-length
% feval(homObj.plot, homObj, StateOutputs(DAE)); % plot all unknowns wrt lambda
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%% Example 4: back-to-back MOS inverters (simple CMOS latch) %%%%
% %%%%            with lambda = the VDD of one of the inverters  %%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% clear ntlst;
% ntlst.cktname = 'simple CMOS latch';
% ntlst.nodenames = {'1', '2', 'vdd1', 'vdd2'};
% ntlst.groundnodename = 'gnd';
% ntlst = add_element(ntlst, vsrcModSpec(), 'Vdd1', {'vdd1', 'gnd'}, {}, ...
% {'DC', 2});
% ntlst = add_element(ntlst, vsrcModSpec(), 'Vdd2', {'vdd2', 'gnd'}, {}, ...
% {'DC', 2});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv1_N', {'2', '1', 'gnd'},...
% {{'Type', 'N'}, {'Beta', 1.0001e-3}});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv1_P', {'2', '1', 'vdd1'},...
% {{'Type', 'P'}, {'Beta', 1e-3}});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv2_N', {'1', '2', 'gnd'},...
% {{'Type', 'N'}, {'Beta', 1.000e-3}});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv2_P', {'1', '2', 'vdd2'},...
% {{'Type', 'P'}, {'Beta', 1.0001e-3}});
% ntlst = add_output(ntlst, 'v(1)'); % voltage at node 1
% ntlst = add_output(ntlst, 'v(2)'); % voltage at node 2
% 
% % set up a DAE from the ckt netlist
% DAE = MNA_EqnEngine(ntlst);
% 
% % run homotopy on the circuit
% lambdaName = 'Vdd1:::E'; inputORparm = 'input';
% startLambda = 2; stopLambda = 0; lambdaStep = 0.01;
% homObj = homotopy(DAE, lambdaName, inputORparm, 0, ...
% 0, lambdaStep, 3.9);
% homObj.plot(homObj);
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%% Example 5: back-to-back MOS inverters (simple CMOS latch using  %%%%
% %%%%            the Schichman-Hodges MOS model) with lambda = VDD.   %%%%
% %%%%            sweep goes through a bifurcation.                    %%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% clear ntlst;
% ntlst.cktname = 'simple CMOS latch';
% ntlst.nodenames = {'1', '2', 'vdd'};
% ntlst.groundnodename = 'gnd';
% ntlst = add_element(ntlst, vsrcModSpec(), 'Vdd', {'vdd', 'gnd'}, {}, ...
% {'DC', 2});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv1_N', {'2', '1', 'gnd'},...
% {{'Type', 'N'}, {'Beta', 1.0001e-3}});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv1_P', {'2', '1', 'vdd'},...
% {{'Type', 'P'}, {'Beta', 1e-3}});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv2_N', {'1', '2', 'gnd'},...
% {{'Type', 'N'}, {'Beta', 1.000e-3}});
% ntlst = add_element(ntlst, SH_MOS_ModSpec(), 'Minv2_P', {'1', '2', 'vdd'},...
% {{'Type', 'P'}, {'Beta', 1.0001e-3}});
% ntlst = add_output(ntlst, 'v(1)'); % voltage at node 1
% ntlst = add_output(ntlst, 'v(2)'); % voltage at node 2
% 
% % set up a DAE from the ckt netlist
% DAE = MNA_EqnEngine(ntlst);
% %dcop = op(DAE); dcop.print(dcop); % finds the middle solution (unstable)
% dcop = op(DAE, [2;0;2;0], 'init', 0); dcop.print(dcop); % latch state 1
% initguessState1 = feval(dcop.getsolution, dcop);
% dcop = op(DAE, [0;2;2;0], 'init', 0); dcop.print(dcop); % latch state 2
% initguessState2 = feval(dcop.getsolution, dcop);
% 
% % run homotopy
% % Note that this circuit/homotopy features a simple bifurcation.
% % Below a critical value of VDD, there is only 1
% % solution (the Middle solution); above this value, there are
% % 3 solutions, as expected for a bistable circuit: the Middle, State1 and
% % State2 solutions, with the Middle solution dynamically unstable. The
% % bifurcation happens at this critical value of VDD.
% 
% % MAPP's homotopy currently does not handle tracking all the branches at
% % a bifurcation (though it does detect and report stepping over one).
% % What we do below is run homotopy thrice to get the three
% % bifurcating tracks separately, then plot them together to see the the
% % complete structure of DC solutions.
% %
% lambdaName = 'Vdd:::E'; inputORparm = 'input';
% startLambda = 2; stopLambda = 0; lambdaStep = 0.01;
% %The following doesn't work because MNA_EqnEngine does not yet have
% %parameter derivative support. Should probably hack it in ArcContDAE for
% %for efficiency.
% %lambdaName = 'Minv1_N:::Beta'; inputORparm = 'param';
% %startLambda = 0; stopLambda = 1e-3; lambdaStep = 1e-5;
% maxLambda = 4; minLambda = -1;
% 
% homObj1 = homotopy(DAE, lambdaName, inputORparm, initguessState1, ...
% startLambda, lambdaStep, stopLambda, ...
% [], maxLambda, minLambda);
% 
% sol1 = homObj1.getsolution(homObj1); %homObj1.plot(homObj1);
% 
% homObj2 = homotopy(DAE, lambdaName, inputORparm, initguessState2, ...
% startLambda, lambdaStep, stopLambda, ...
% [], maxLambda, minLambda);
% 
% sol2 = homObj2.getsolution(homObj2); % homObj2.plot(homObj2);
% 
% % this one goes over a bifurcation (watch the diagnostic output)
% homObjM = homotopy(DAE, lambdaName, inputORparm, 0, ...
% 0, lambdaStep, 3.9, ...
% [], maxLambda, minLambda);
% solM = homObjM.getsolution(homObjM); % homObjM.plot(homObjM);
% 
% % plot them all together, in 2- and 3-D. Here is a situation where getting
% % the numerical data for the homotopy tracks (using homObj.getsolution())
% % is useful.
% figure(); % 2D plot
% v1idx = feval(DAE.unkidx, 'e_1', DAE); v2idx = feval(DAE.unkidx, 'e_2', DAE);
% plot(sol2.yvals(end,:), sol2.yvals(v1idx,:), 'bo-', ...
% sol1.yvals(end,:), sol1.yvals(v1idx,:), 'b.-', ...
% solM.yvals(end,:), solM.yvals(v1idx,:), 'c+-');
% hold on;
% plot(sol2.yvals(end,:), sol2.yvals(v2idx,:), 'go-', ...
% sol1.yvals(end,:), sol1.yvals(v2idx,:), 'g.-', ...
% solM.yvals(end,:), solM.yvals(v2idx,:), 'r+-');
% grid on; axis tight;
% xlabel('lambda=Vdd');
% ylabel('v1 and v2');
% legend({'v1 (State2)', 'v1 (State1)', 'v1 (Middle)', 'v2 (State2)', ...
% 'v2 (State1)', 'v2 (Middle)' });
% title('simple CMOS latch with VDD ramped: multiple homotopy tracks overlaid');
% 
% figure(); % 3D plot to show the simple bifurcation better
% plot3(solM.yvals(end,:), solM.yvals(v1idx,:), solM.yvals(v2idx,:), 'r.-');
% hold on;
% plot3(sol1.yvals(end,:), sol1.yvals(v1idx,:), sol1.yvals(v2idx,:), 'b.-');
% plot3(sol2.yvals(end,:), sol2.yvals(v1idx,:), sol2.yvals(v2idx,:), 'g.-');
% xlabel('lambda=Vdd');
% ylabel('v1');
% zlabel('v2');
% grid on; axis tight;
% title('simple CMOS latch with VDD ramped: multiple homotopy tracks overlaid');
% legend({'Middle Track', 'State1 Track', 'State2 Track'});
% view(50, -10);
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%% Example 6: hysteresis/folds in cross-coupled MVS diffpair       %%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% DAE =  MNA_EqnEngine(MVSxCoupledDiffpairIsrc_ckt());
% 
% % This ckt has DC convergence problems at Iin=-1e-3. The following initguess
% % was found by running a homotopy to -1e-3 starting from 0, as follows:
% % hom = homotopy(DAE, 'Iin:::I', 'input', [], 0, 5e-5, 1e-3, [], 1e-3, -1e-3);
% % homsol = feval(hom.getsolution, hom);
% % initguess = homsol.yvals(1:(end-1),end)
% initguess = [0.7520;5.0366;0.9634;5;-2e-3;4.1844;0.1002;0.1116;0.0998];
% 
% % homotopy wrt an input (Iin)
% hom = homotopy(DAE, 'Iin:::I', 'input', initguess, -1e-3, 5e-5, 1e-3);
% feval(hom.plot, hom); souts = StateOutputs(DAE); feval(hom.plot, hom, souts);
% 
% % %% homotopy wrt a parameter
% % the following init guess (upper bistable state) obtained by
% % hom = homotopy(DAE, 'Iin:::I', 'input', initguess, -1e-3, 5e-5, 0);
% stateUP = [1.7863;3.8817;2.1183;5;-0.0020;2.0395;0.0559;0.1879;0.1441];
% 
% % lambda = 'MR:::Rs0' (from 210 up, turning point at ~213, stop back at 210)
% DAE = feval(DAE.set_uQSS, 'Iin:::I', 0, DAE);
% lstart = 210; lstep = 1e-2; lstop = 220; maxstep = 0.1; maxl = 214; minl=210;
% hom2 = homotopy(DAE, 'MR:::Rs0', 'param', stateUP, lstart, lstep, ...
% lstop, maxstep, maxl, minl);
% feval(hom2.plot, hom2); feval(hom2.plot, hom2, souts);
% 
% % BUG: larger lambda step => doubles back on the track - likely scaling issue
% % (because Rs is ~200, voltages are ~1, probably tangent vector inaccuracy)
% lstart = 200; lstep = 0.5; lstop = 220; maxlstep = 0.5; maxl = 214; minl=200;
% hom2 = homotopy(DAE, 'MR:::Rs0', 'param', stateUP, lstart, lstep, ...
% lstop, maxlstep, maxl, minl);
% feval(hom2.plot, hom2); feval(hom2.plot, hom2, souts);
% 
% 
