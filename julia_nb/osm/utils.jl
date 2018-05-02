function weather_impact_factors(weather)
    
    # 0/1/2 -> sunny/rainy/snowy
    
    if weather == 0
        return 0.0, 0.0
    elseif weather == 1
        return 0.1, 0.3
    elseif weather == 2
        return 0.3, 0.5
    else
        return 0.0, 0.0
    end
end

map_rand_to_range(rand_float, a, b) = (b - a) * rand_float + a

map_vehicles_to_slowing_factor(num_vehicles) = 1 - e ^ (-0.01num_vehicles)

function generate_weights_with_factors(edge_info_dict)
    
    # Units
    # edge_len: meters
    # speed_limit: m/s
    # so is number of vehicles on the edge;
    # higher the centrality, lower the weight
    # highway reduces the weight by 10% to 30%
    
    weight = edge_info_dict[:segmentlen] / edge_info_dict[:speed]
    
    weight *= (1 + map_vehicles_to_slowing_factor(edge_info_dict[:num_vehicles]))
    
    weight *= (1 - edge_info_dict[:centrality])
    
    edge_info_dict[:is_highway] && (weight *= (1 - map_rand_to_range(rand(), 0.1, 0.3)))
    
    factors = weather_impact_factors(edge_info_dict[:weather])
    weight *= (1 + map_rand_to_range(rand(), factors[1], factors[2]))
    
    return weight
end