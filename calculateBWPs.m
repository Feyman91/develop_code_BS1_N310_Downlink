function [alloc_RadioResource, all_resource] = calculateBWPs(overAllOfdmParams, BS_id, bwp_offset)
    % Step 0: 检查 BS_id 是否超过在线基站的数量
    if BS_id > overAllOfdmParams.online_BS
        error('Error: BS_id (%d) exceeds the number of online base stations (%d).', BS_id, overAllOfdmParams.online_BS);
    end

    % Step 1: 计算 N_used (总使用的子载波数量)
    N_used = overAllOfdmParams.total_RB * 12;  % RB 与 N_used 的关系
    
    % Step 2: 计算 guard interval
    guard_interval = (overAllOfdmParams.FFTLength - N_used) / 2;  % Guard interval, 单侧的空载波
    
    % Step 3: 计算每个 BWP 之间的保护间隔带宽，以及有效可用子载波
    total_guard_band = (overAllOfdmParams.online_BS - 1) * guard_interval;  % 所有基站之间的总保护带宽
    effective_bandwidth = N_used - total_guard_band;  % 有效可用子载波带宽
    
    % Step 4: 计算每个 BWP 的子载波数量
    BWP_bandwidth = effective_bandwidth / overAllOfdmParams.online_BS;  % 每个 BWP 的带宽，不包括保护间隔
    
    % 初始化结构体用于存储结果
    all_resource.online_BS = overAllOfdmParams.online_BS;           % 在线基站的数量
    all_resource.num_BWPs = overAllOfdmParams.online_BS;            % BWP 数量等于基站数
    all_resource.BWPs = struct();                 % 保存 BWP 的信息
    
    % Step 5: 为每个基站计算 BWP 的关键信息
    for i = 1:overAllOfdmParams.online_BS
        % 计算每个 BWP 的起始和结束索引，考虑保护间隔
        if i == 1
            BWP_start_index = guard_interval + 1;  % 第一个基站从第一个 guard interval 后开始
        else
            BWP_start_index = BWP_end_index + guard_interval + 1;  % 相邻基站要加上保护间隔
        end
        
        % 计算 BWP 的结束索引
        BWP_end_index = BWP_start_index + BWP_bandwidth - 1;
        
        % 计算 BWP 的中心偏移量 (相对于 FFT_length/2)
        BWP_center_offset = (BWP_start_index + BWP_end_index) / 2 - overAllOfdmParams.FFTLength / 2;
        
        % 计算每个 BWP 的长度 (子载波数量)
        BWP_length = BWP_end_index - BWP_start_index + 1;
        
        % 计算每个 BWP 的资源块 (RB) 数量
        BWP_RB_count = BWP_length / 12;  % 每个资源块等于 12 个子载波

        % 保存 BWP 关键信息到结构体
        all_resource.BWPs(i).subcarrier_start_index = BWP_start_index;
        all_resource.BWPs(i).subcarrier_end_index = BWP_end_index;
        all_resource.BWPs(i).subcarrier_center_offset = BWP_center_offset;
        all_resource.BWPs(i).UsedSubcc = BWP_length;
        
        % 如果 i 等于 BS_id，则记录对应的 BWP 信息为 allocate_radio_resource
        if i == BS_id
            alloc_RadioResource.subcarrier_start_index = BWP_start_index + bwp_offset;
            alloc_RadioResource.subcarrier_end_index = BWP_end_index + bwp_offset;
            alloc_RadioResource.subcarrier_center_offset = BWP_center_offset + bwp_offset;
            alloc_RadioResource.UsedSubcc = BWP_length;
            alloc_RadioResource.BWPoffset = bwp_offset;
            
            % 保存 BWP 关键信息到结构体
            all_resource.BWPs(i).subcarrier_start_index = BWP_start_index + bwp_offset;
            all_resource.BWPs(i).subcarrier_end_index = BWP_end_index + bwp_offset;
            all_resource.BWPs(i).subcarrier_center_offset = BWP_center_offset + bwp_offset;
            all_resource.BWPs(i).UsedSubcc = BWP_length;
        end
    end
end