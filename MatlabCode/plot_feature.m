% f1 = func_load_feature('junhyub1_r2r');
% feature = f1;
% featureFigNum = 1;
% usingGroundTruth = true;
% 
values = struct();
values2 = struct();

for cnt = 1:length(feature)
    value = [];
    value2 = [];
    values(cnt).name = feature(cnt).name;
    values2(cnt).name = feature(cnt).name;
    nTrials = length(feature(cnt).trial);

    for cnt2 = 1:nTrials
        cur = feature(cnt).trial(cnt2).cur;
        for cnt3 = 1:length(cur)
            if usingGroundTruth == true
                value = [value;cur(cnt3).attach];
                value2 = [value2;cur(cnt3).detach];
            else
                value = [value;cur(cnt3).diff(1, :)];
                value2 = [value2;cur(cnt3).diff(2, :)];
            end
        end 
    end
    values(cnt).feature = value;
    values2(cnt).feature = value2;
end



% values= func_load_feature('junhyub1_p2p');


label = [];
for cnt = 1:length(values)
    label = strvcat(label, [values(cnt).name]);
end

figure(52)
clf


for cnt = 1:length(values)
    p = values(cnt).feature;
    
    if cnt > 6
        scatter3(p(:,1), p(:,2), p(:,3), 'filled');
    else
        scatter3(p(:,1), p(:,2), p(:,3));
    end
    hold on
end

legend(label)
xlabel('x')
ylabel('y')
zlabel('z')
% xlim([-150, 10]);
% ylim([-20, 150]);
% zlim([-150, 50]);