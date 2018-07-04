function MOD = my_differentiator(uniqID)
%-----------------------------
%
% 1. variables:
% - IO name(s):                      vpinref, vpoutref, ipinref, ipoutref
% - explicit output name(s):         ipinref, vpoutref
% - other IO name(s) (vecX):         vpinref, ipoutref
% - implicit unknown name(s) (vecY): {}
% - input name(s) (vecU):            {}
%
% 2. equations:
% - input current equation:
%   ipinref = vpinref / Rin;
%       fe: vpinref / Rin
%       qe: 0
% - output voltage equation:
%   vpoutref = d/dt ( k * vpinref );
%       fe: 0
%       qe: k*vpinref
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Type "help MAPPlicense" at the MATLAB/Octave prompt to see the license      %
%% for this software.                                                          %
%% Copyright (C) 2008-2013 Jaijeet Roychowdhury <jr@berkeley.edu>. All rights  %
%% reserved.                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

% use the common ModSpec skeleton, sets up fields and defaults
    MOD = ModSpec_common_skeleton();

% set up data members defined in ModSpec_common_skeleton. These are
% used by the API functions defined there.

% uniqID
    if nargin < 1
        MOD.uniqID = '';
    else
        MOD.uniqID = uniqID;
    end

    MOD.model_name = 'differentiator';
    MOD.model_description = "a voltage source with a voltage equal to the \
        differential of the input";

    MOD.parm_names = {'k', 'Rin'};
    MOD.parm_defaultvals = {1.0, 1e3};
    MOD.parm_types = {'double'};
    MOD.parm_vals = MOD.parm_defaultvals; % current values of parms

    MOD.explicit_output_names = {'ipinref', 'vpoutref'};
    MOD.internal_unk_names = {};
    MOD.implicit_equation_names = {};
    MOD.u_names = {};

    MOD.NIL.node_names = {'pin', 'pout', 'ref'};
    MOD.NIL.refnode_name = 'ref';

    % MOD.IO_names, MOD.OtherIO_names, MOD.NIL.io_types and
    % MOD.NIL.io_nodenames are set up by this helper function
    MOD = setup_IOnames_OtherIOnames_IOtypes_IOnodenames(MOD);

% Core functions: qi, fi, qe, fe: 
    MOD.fqei = @fqei;
    MOD.fqeiJ = @fqeiJ; % hardcoded derivatives, should be faster

% Newton-Raphson initialization support

% Newton-Raphson limiting support

% Newton-Raphson convergence criterion support

% Equation and unknown scaling support

% Noise support

end % cap MOD constructor

%%%%%%%%%%%%%%%%%%%%%%%%%%%% CORE DEVICE EVAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%
function [fe, qe, fi, qi] = fqei(vecX, vecY, vecU, flag, MOD)

    %{
    if ~isfield(flag,'fe')
        flag.fe =0;
    end
    if ~isfield(flag,'qe')
        flag.qe =0;
    end
    if ~isfield(flag,'fi')
        flag.fi =0;
    end
    if ~isfield(flag,'qi')
        flag.qi =0;
    end
    %}

    %{
    pnames = feval(MOD.parmnames,MOD);
    for i = 1:length(pnames)
        evalstr = sprintf('%s = MOD.parm_vals{i};', pnames{i});
        eval(evalstr);
    end
    %}
    k = MOD.parm_vals{1};
    Rin = MOD.parm_vals{2};

    % % similarly, get values from vecX, named exactly the same as otherIOnames
    % % get otherIOs from vecX
    % oios = feval(MOD.OtherIONames,MOD);
    % for i = 1:length(oios)
    %     evalstr = sprintf('%s = vecX(i);', oios{i});
    %     eval(evalstr); % should be OK for vecvalder
    % end


    % DEBUG

    % printf('printing value of vecX\n');
    % vecX
    % printf('printing datatype of vecX\n');
    % typeinfo(vecX)

    % printf('printing values of vpinref and ipoutref\n');
    % vpinref = vecX(1)
    % ipoutref = vecX(2)

    % printf('printing datatype of vpinref and ipoutref\n');
    % typeinfo(vecX(1))
    % typeinfo(vecX(2))

    % DEBUG

    vpinref = vecX(1);
    ipoutref = vecX(2);

    % do the same for vecY from internalUnknowns
    % get internalUnknowns from vecY
    %{
    iunks = feval(MOD.InternalUnkNames,MOD);
    for i = 1:length(iunks)
        evalstr = sprintf('%s = vecY(i);', iunks{i});
        eval(evalstr); % should be OK for vecvalder
    end
    %}

    % equation for ipinref
    fe(1) = vpinref/Rin;
    qe(1, 1) = 0;

    % equation for vpoutref
    fe(2, 1) = 0;
    qe(2) = k*vpinref;

    % implicit equations
    fi = [];
    qi = [];
end % fqei

function [fqei, J] = fqeiJ(varargin)
%function [fqei, J] = fqeiJ(vecX, vecY, vecLim, vecU, flag, MOD)
% input vecLim is optional
%OUTPUTS:
%
%   fqei.fe 
%   fqei.qe
%   fqei.fi
%   fqei.qi
%
%   J.Jfe           - struct that contains:
%                       .dfe_dvecX
%                       .dfe_dvecY
%                       .dfe_dvecLim
%                       .dfe_dvecU
%   J.Jqe           - struct that contains:
%                       .dqe_dvecX
%                       .dqe_dvecY
%                       .dqe_dvecLim
%   J.Jfi           - struct that contains:
%                       .dfi_dvecX
%                       .dfi_dvecY
%                       .dfi_dvecLim
%                       .dfi_dvecU
%   J.Jqi           - struct that contains:
%                       .dqi_dvecX
%                       .dqi_dvecY
%                       .dqi_dvecLim
%
    MOD = varargin{end};
    vecX = varargin{1};

    k = MOD.parm_vals{1};
    Rin = MOD.parm_vals{2};
    
    vpinref = vecX(1);
    ipoutref = vecX(2);

    % oios = feval(MOD.OtherIONames,MOD);
    % for i = 1:length(oios)
    %     evalstr = sprintf('%s = vecX(i);', oios{i});
    %     eval(evalstr); % should be OK for vecvalder
    % end

    % fqei definitions
    % equation for ipinref
    fqei.fe(1) = vpinref/Rin;
    fqei.qe(1, 1) = 0;

    % equation for vpoutref
    fqei.fe(2, 1) = 0;
    fqei.qe(2) = k*vpinref;

    % implicit equations
    fqei.fi = [];
    fqei.qi = [];

    % J definitions
    J.Jfe.dfe_dvecX = sparse([1.0/Rin 0.0; 0.0 0.0]);
    J.Jfe.dfe_dvecY = sparse(2,0);
    J.Jfe.dfe_dvecLim = sparse(2,0);
    J.Jfe.dfe_dvecU = sparse(2,0);

    J.Jqe.dqe_dvecX = sparse([0.0 0.0; k 0.0]);
    J.Jqe.dqe_dvecY = sparse(2,0);
    J.Jqe.dqe_dvecLim = sparse(2,0);
    J.Jqe.dqe_dvecU = sparse(2,0);

    J.Jfi.dfi_dvecX = sparse(0,2);
    J.Jfi.dfi_dvecY = sparse(0,0);
    J.Jfi.dfi_dvecLim = sparse(0,0);
    J.Jfi.dfi_dvecU = sparse(0,0);

    J.Jqi.dqi_dvecX = sparse(0,2);
    J.Jqi.dqi_dvecY = sparse(0,0);
    J.Jqi.dqi_dvecLim = sparse(0,0);
    J.Jqi.dqi_dvecU = sparse(0,0);
end

%%%%%%%%%%%%%%%%%%%%% NOISE SUPPORT FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% ANALYSIS-SPECIFIC INPUT FUNCTIONS %%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% NR INITIAL GUESS SUPPORT %%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% NR LIMITING SUPPORT %%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% EQN and UNK SCALING SUPPORT %%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% STUFF BELOW IS NOT PART OF MOD API %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% other local functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


