%% Simple test for FaultKnowledgeBase syntax
% Test basic functionality without complex operations

try
    fprintf('Testing basic syntax...\n');
    
    % Test class instantiation
    kb = FaultKnowledgeBase();
    fprintf('Class instantiation: OK\n');
    
    % Test simple query
    fault_info = kb.getFaultByCode('302');
    if ~isempty(fault_info)
        fprintf('Fault query: OK\n');
    end
    
    % Test maintenance logging
    kb.logMaintenance('302', 'Test maintenance', 'Success', now);
    fprintf('Maintenance logging: OK\n');
    
    fprintf('All basic tests passed!\n');
    
catch ME
    fprintf('Error: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('Location: %s line %d\n', ME.stack(1).file, ME.stack(1).line);
    end
end