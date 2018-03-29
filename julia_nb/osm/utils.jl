map_rand_to_range(rand_float, a, b) = (rand_float - a) / (b - a)

map_vehicles_to_slowing_factor(num_vehicles) = 1 - e ^ (-0.01num_vehicles)

function generate_weights_with_factors(edge_len, speed_limit;
                                        bad_weather=false, traffic_light=false,
                                        num_vehicles=0)
    # Units
    # edge_len: meters
    # speed_limit: m/s
    # Assume that bad_weather slows a vehicle by 30% - 50%;
    # Traffic light increases the edge weights by 10% - 30%;
    # so is number of vehicles on the edge;
    
    weight = edge_len / speed_limit
    
    traffic_light && (weight *= (1 + map_rand_to_range(rand(), 0.1, 0.3)))
    
    bad_weather && (weight *= (1 + map_rand_to_range(rand(), 0.3, 0.5)))
    
    weight *= (1 + map_vehicles_to_slowing_factor(num_vehicles))
    
    return weight
end