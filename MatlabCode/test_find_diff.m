clear exp;

accId = 6;
showTrials = 1:2;

wSize = 100;
rate = 100;
calibrationInterval = -5*wSize:-wSize;
attachInterval = -wSize*2:wSize;
calibrationThreshold = 2;

lowCutoff = 5;
highCutoff = 10;

accName = data(accId).name
feature = objectFeature(accId).feature

[b.low, a.low] = butter(4, lowCutoff/rate * 2, 'low');
[b.high, a.high] = butter(4, highCutoff/rate * 2, 'high');


mdlPath = '../MatlabCode/models/';
mdl = load([mdlPath, 'rotMdl2', '.mat']);
mdl = mdl.mdl;

featureMatrix.data = mdl.X;
featureMatrix.label = mdl.Y;

chargingAcc = {'batterypack1', 'charger1', 'charger2', 'holder2', 'holder3', 'holder4'};

for cnt = 1:length(showTrials)
    cur = data(accId).trial(showTrials(cnt));
    mag = cur.mag;
    gyro = cur.gyro;
    rmag = cur.rmag;
    rawSample = rmag.rawSample;
    click = cur.detect.sample;

    [calm, bias, ~] = magcal(rmag.rawSample(1:500, :));
    mag.sample = (rmag.rawSample-bias)*calm;

    w = 600; 
    h = 400;

    fig = figure(showTrials(cnt) + length(calibrationInterval)-1);
    clf

    iter = 1:2:length(click);

    nRow = 7;
    nCol = length(iter);
    
    for cnt2 = iter
        t = click(cnt2);
        
        status = (mod(cnt2, 2) == 1);
        % Extract range for feature extraction
        range = t + attachInterval;
        if range(1) < 2
            range = 2:range(end);
        end

        if range(end) > length(mag.sample)
            range = range(1):length(mag.sample);
        end
        
        % Extract range for calibration
        calRange = t + calibrationInterval;

        if calRange(1) < 1
            calRange = 1:calRange(end);
        end

        if calRange(end) > length(mag.sample)
            calRange = calRange(1):length(mag.sample);
        end

        % Calibration magnetometer
        % [calm, bias, ~] = magcal(rawSample(calRange, :));

        [~, diff1s]= func_get_diff(mag.sample, gyro, calRange, status);

        diffSum = sqrt(sum(diff1s.^2, 2));

        % Magnetometer Calibration filtering
        calRange = calRange(diffSum < calibrationThreshold);
        % [calm, bias, ~] = magcal(rawSample(calRange, :));
        [diffOriginal, diff1s] = func_get_diff((rawSample-bias)*calm, gyro, range, status);

        diffSum = sqrt(sum(diff1s.^2, 2));
        
        % LPF, HPF
        fh = filtfilt(b.high, a.high, diffSum);
        fl = filtfilt(b.low, a.low, diffSum);

        hpfMaxIdx = find(max(fh(21:end-21)) == fh);
        tmp = fl((hpfMaxIdx-20):(hpfMaxIdx+20));
        lpfMaxIdx = hpfMaxIdx - 20 -1 + find((max(tmp) == tmp));

        % Detect로 간주
        hpfMaxIdxGlobal = range(1) + hpfMaxIdx -1;

        % Calculated diff filtered by hpf, lpf
        hpfMaxIdxLocal = hpfMaxIdxGlobal - range(1)+ 1;

        [diff, diff1s] = func_get_diff((rawSample-bias)*calm, gyro, range, status);

        idx = find(iter==cnt2);

        extractedRange = func_extract_range((rawSample-bias)*calm, gyro, range, hpfMaxIdxGlobal);
        showRange = extractedRange - range(1) + 1;
        
        lst = [showRange(1), hpfMaxIdxLocal, showRange(end)];
        % Plotting
        subplot(nRow, nCol, idx)
        hold on
        plot(diffOriginal)
        stem(lst, diffOriginal(lst), 'filled')
        title([num2str(t), '-', num2str(length(calRange))])

        subplot(nRow, nCol, nCol + idx)
        hold on
        plot(diffSum)
        title('diff sum')
        
        subplot(nRow, nCol, nCol*2 + idx)
        hold on
        plot(fh)
        stem(lst, fh(lst), 'filled')
        title(['HPF ', num2str(highCutoff), 'Hz'])
        
        subplot(nRow, nCol, nCol*3 + idx)
        hold on
        plot(fl)
        stem(lst, fl(lst), 'filled')
        title(['LPF ', num2str(lowCutoff), 'Hz - ', num2str(extractedRange(1)), '-', num2str(extractedRange(end))])
        
        [featureValue, ~] = func_get_diff((rawSample-bias)*calm, gyro, extractedRange, status);

        if status
            f = featureValue(end, :);
        else
            f = featureValue(1, :);
        end

        [preds, scores] = predict(mdl, f);
        probs = exp(scores) ./ sum(exp(scores),2);
        
        pLabel = func_predict({accName}, preds, probs, mdl.ClassNames, chargingAcc);
        
        [midx, distance] = knnsearch(featureMatrix.data, f, 'K', 11, 'Distance', 'euclidean');
        
        subplot(nRow, nCol, nCol*4 + idx)
        hold on
        plot(featureValue)
        title([preds{1}, '-->', char(pLabel), ', ',num2str(mean(distance))])

        subplot(nRow, nCol, nCol*5 + idx)
        hold on
        % plot(rawSample(range, :)-rawSample(range(1), :))\
        plot(rawSample(range, :))
        title('rawSample range')

        subplot(nRow, nCol, nCol*6 + idx)
        hold on
        plot(rawSample(extractedRange, :)-rawSample(extractedRange(1), :))
        title('rawSample extracted range')

        disp([accName, num2str(cnt2), '->', num2str(f(1)), ',',  num2str(f(2)), ',',  num2str(f(3))])
    end
end
%% Function for get Diff graphs
function [diff, diff1s] = func_get_diff(mag, gyro, range, status)
% status == true means original else revserse

diff = zeros(length(range), 3);
diff1s = zeros(length(range), 3);

if ~status
    range = flip(range);
end

refMag = mag(range(1), :);

for cnt = 2:length(range)
    t = range(cnt);

    euler = gyro.sample(t, :) * 1/100;

    if ~status
        euler = -euler;
    end
    
    rotm = eul2rotm(euler, 'XYZ');

    refMag = (rotm\(refMag)')';
    diff(cnt, :) = mag(t, :) - refMag;
    diff1s(cnt, :) = mag(t, :) - (rotm\(mag(t-1, :))')';
end

if ~status
    diff = flip(diff);
    diff1s = flip(diff1s);
end

end