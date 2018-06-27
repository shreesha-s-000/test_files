% my_comparator
function MOD = my_comparator()
    % initialize model
    MOD = ee_model();
    MOD = add_to_ee_model(MOD, 'name', 'my_comparator');
    MOD = add_to_ee_model(MOD, 'terminals', {'inp', 'inn', 'out', 'ref'});
    MOD = add_to_ee_model(MOD, 'explicit_outs', ...
        {'voutref', 'iinpref', 'iinnref'});
    
    % parameters
    MOD = add_to_ee_model(MOD, 'parms', {'smooth_k', 50.0});
    MOD = add_to_ee_model(MOD, 'parms', {'out_high', 1.0});

    MOD = add_to_ee_model(MOD, 'fe', @fe);
    MOD = add_to_ee_model(MOD, 'qe', @qe);
    
    %{
    printf('printing ModelName\n');
    MOD.ModelName
    printf('printing name\n');
    MOD.name
    printf('printing done\n');
    %}

    MOD = finish_ee_model(MOD);
end % my_comparator

function out = fe(S)
    % setup workspace
    v2struct(S);
    
    % explicit outputs
    % compare the two inputs and assign a smooth sgn funcion to output
    out(1, 1) = out_high*0.5*(1.0+tanh(smooth_k*(vinpref-vinnref)));
    % input currents are zero
    out(2, 1) = 0;
    out(3, 1) = 0;

end % fe

function out = qe(S)
    % setup workspace
    v2struct(S);

    % explicit outputs
    % all the differential components are zero
    out(1, 1) = 0;
    out(2, 1) = 0;
    out(3, 1) = 0;
end % qe

