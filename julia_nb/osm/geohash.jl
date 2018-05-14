charmap = "0123456789bcdefghjkmnpqrstuvwxyz"
geodec = Dict() # 'q' => "10110"
geoenc = Dict() # "11001" => "t"
for c in 1:length(charmap)
       geodec[charmap[c]] = bits(UInt8(c-1))[4:8]
       geoenc[bits(UInt8(c-1))[4:8]] = string(charmap[c])
end

function geo_decode(charseq::String, precision::Int = 7)
    bitseq = ""
    for c in charseq
        bitseq *= geodec[c]
    end
    isodd(length(charseq)) ? (bitseq *= "0") : nothing
    lonmin, lonmax, latmin, latmax = -180.0, 180.0, -90.0, 90.0
    for i in 1:2:length(bitseq)
        bitseq[i] == '1' ? (lonmin = mean([lonmin, lonmax])) : (lonmax = mean([lonmin, lonmax]))
        bitseq[i+1] == '1' ? (latmin = mean([latmin, latmax])) : (latmax = mean([latmin, latmax]))
    end
    (round(mean([latmin, latmax]), precision), round(mean([lonmin, lonmax]), precision))
end

function geo_encode(lat::Float64, lon::Float64, precision::Int = 6)
    bitlon, bitlat, bitseq, charseq = "", "", "", ""
    lonmin, lonmax, latmin, latmax = -180.0, 180.0, -90.0, 90.0
    for c in 1:Int(precision*5)
        lonmean = mean([lonmin, lonmax]); latmean = mean([latmin, latmax])
        lon > lonmean ? (bitlon *= "1"; lonmin = lonmean) : (bitlon *= "0"; lonmax = lonmean)
        lat > latmean ? (bitlat *= "1"; latmin = latmean) : (bitlat *= "0"; latmax = latmean)
    end
    for i in 1:length(bitlon)
        bitseq *= string(bitlon[i]); bitseq *= string(bitlat[i])
    end
    for i in 1:5:length(bitseq)
        charseq *= geoenc[bitseq[i:i+4]]
    end
    charseq
end
