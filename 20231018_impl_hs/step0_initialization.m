%% Load sensor data
clear;

global params;
params = struct();
params.data.newApp = true;
% params.data.path = '../Data/Inside_dataset/Jaemin7';
% params.data.postfix = char({'310'});

% params.data.path = '../Data/Outside_dataset/Jaemin7';
% params.data.postfix = char({'bus'});

params.data.path = '../Data/Default_dataset/Jaemin11';
params.data.postfix = char({'Normal_objects', 'Holders'});

params.data.sensors = {'gyro', 'mag'};
params.data.rate = 100;
params.data.mType = 'rmag';

if params.data.newApp == false
    params.data.mType = 'mag';
    ori = func_load_data(params.data.path, params.data.postfix);
else
    params.data.sensors = [params.data.sensors, 'rmag'];
    ori = func_load_new_data(params.data.path, params.data.postfix);
    ori = func_timestamp_sync(ori);
    
    charging = func_load_charging_status(params.data.path, params.data.postfix);
end

for cnt = 1:length(ori)
    if strcmp(ori(cnt).name, 'None')
        ori(cnt) = [];
        break;
    end
end

%% Divide data into events
params.data.eventRange = params.data.rate * 5;
params.data.calibRange = params.data.rate * 5;

data = struct();

for cnt = 1:length(ori)   
    data(cnt).name = ori(cnt).name;    
    
    idx = 1;
    for cnt2 = 1:length(ori(cnt).trial)
        cur = ori(cnt).trial(cnt2);
        cmag = cur.rmag.sample(1:params.data.calibRange, :);
        
        for cnt3 = 1:length(cur.detect.sample)/2
            range = max(1, cur.detect.sample(cnt3 * 2 - 1) - params.data.eventRange) ...
                :min(size(cur.acc.sample, 1), cur.detect.sample(cnt3 * 2) + params.data.eventRange);
        
            data(cnt).trial(idx).detect.sample = [params.data.eventRange + 1, length(range) - params.data.eventRange];
            data(cnt).trial(idx).acc.sample = cur.acc.sample(range, :);
            data(cnt).trial(idx).gyro.sample = cur.gyro.sample(range, :);
            data(cnt).trial(idx).mag.sample = cur.mag.sample(range, :);
            data(cnt).trial(idx).rmag.sample = cur.rmag.sample(range, :);

            data(cnt).trial(idx).rmag.calSample = cmag;
            data(cnt).trial(idx).mag.calSample = zeros(1, params.data.calibRange);
            
            idx = idx + 1;                        
        end
    end
end

%% Load reference feature data
params.ref.path = 'features/Jaemin8_p2p.mat';
<<<<<<< HEAD
=======
params.ref.nData = 50;
params.ref.nSub = 1;
params.ref.nSubData = floor(params.ref.nData / (params.ref.nSub));
>>>>>>> 9f35708a9e1fe6396ea286e861bb31fbbcb2d7ad

load(params.ref.path);
ref = feature;
ref(~ismember({ref(:).name}, {data.name})) = [];

for cnt = 1:length(ref)
    ref(cnt).raw = ref(cnt).feature;   
    ref(cnt).isChargeable = func_isChargeable(ref(cnt).name);
end

% step1_preprocessing
% step2_detection
% step3_identification
% step4_evaluation