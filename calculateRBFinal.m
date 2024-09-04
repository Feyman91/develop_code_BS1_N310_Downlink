% 计算满足能够整除导频间隔条件的最大RB值
% 最终该RB最为系统输入RB最终能取到的资源数量，且该值确定的数据子载波总数能够被导频间隔整除
% 且该值应该小于等于maxRB
function [RB_final, maxRB] = calculateRBFinal(OFDMParams, RB)
    % 计算当前的总子载波数
    PilotSubcarrierSpacing = OFDMParams.PilotSubcarrierSpacing;
    NumSubcarriers = RB * 12;

    % 找到 12 和 PilotSubcarrierSpacing 的最小公倍数
    LCM = lcm(12, PilotSubcarrierSpacing);

    % 计算最小的 RB_final，使得 RB_final * 12 能被 PilotSubcarrierSpacing 整除
    % NumSubcarriers_final 必须大于等于当前的 NumSubcarriers
    NumSubcarriers_final = ceil(NumSubcarriers / LCM) * LCM;

    % 计算最终的 RB_final和maxRB
    RB_final = NumSubcarriers_final / 12;
    maxRB = calculateMaxRB(OFDMParams);
end

% 计算系统可能取到的最大RB
function maxRB = calculateMaxRB(OFDMParams)
    % 根据保护带宽（滤波器过度带宽与通带比例不低于0.1的约定），计算出可能RB可能取到的最大值（系统带宽(used subcarrier)最大值）
    MaxRBNum_satisfyBand = round(round(0.45*OFDMParams.FFTLength/0.55)/12);
    PilotSubcarrierSpacing = OFDMParams.PilotSubcarrierSpacing;
    NumSubcarriers = MaxRBNum_satisfyBand * 12;

    % 找到 12 和 PilotSubcarrierSpacing 的最小公倍数
    LCM = lcm(12, PilotSubcarrierSpacing);

    % 计算最小的 RB_final，使得 RB_final * 12 能被 PilotSubcarrierSpacing 整除
    % NumSubcarriers_final 必须大于等于当前的 NumSubcarriers
    NumSubcarriers_final = ceil(NumSubcarriers / LCM) * LCM;

    % 计算最终的 maxRB
    maxRB = NumSubcarriers_final / 12;
end