import Foundation

struct TripPoint: Codable, Hashable {
    let lat: Double
    let lng: Double
    let speed: Double
    let t: Double
    let cumKm: Double

    enum CodingKeys: String, CodingKey { case lat, lng, speed, t, cum_km }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lat = (try? c.decodeIfPresent(Double.self, forKey: .lat)) ?? 0
        lng = (try? c.decodeIfPresent(Double.self, forKey: .lng)) ?? 0
        speed = (try? c.decodeIfPresent(Double.self, forKey: .speed)) ?? 0
        t = (try? c.decodeIfPresent(Double.self, forKey: .t)) ?? 0
        cumKm = (try? c.decodeIfPresent(Double.self, forKey: .cum_km)) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(lat, forKey: .lat); try c.encode(lng, forKey: .lng)
        try c.encode(speed, forKey: .speed); try c.encode(t, forKey: .t)
        try c.encode(cumKm, forKey: .cum_km)
    }
}

struct Trip: Codable, Identifiable, Hashable {
    let id: String
    let start: Double
    let end: Double
    let durS: Double
    let mileageKm: Double
    let distGpsKm: Double
    let speedMax: Double
    let speedMean: Double
    let movingMean: Double
    let overPct: Double
    let points: Int
    let pts: [TripPoint]

    enum CodingKeys: String, CodingKey {
        case id, start, end, dur_s, mileage_km, dist_gps_km, speed_max,
             speed_mean, moving_mean, over_pct, points, pts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        start = (try? c.decodeIfPresent(Double.self, forKey: .start)) ?? 0
        end = (try? c.decodeIfPresent(Double.self, forKey: .end)) ?? start
        durS = (try? c.decodeIfPresent(Double.self, forKey: .dur_s)) ?? max(0, end - start)
        mileageKm = (try? c.decodeIfPresent(Double.self, forKey: .mileage_km)) ?? 0
        distGpsKm = (try? c.decodeIfPresent(Double.self, forKey: .dist_gps_km)) ?? mileageKm
        speedMax = (try? c.decodeIfPresent(Double.self, forKey: .speed_max)) ?? 0
        speedMean = (try? c.decodeIfPresent(Double.self, forKey: .speed_mean)) ?? 0
        movingMean = (try? c.decodeIfPresent(Double.self, forKey: .moving_mean)) ?? speedMean
        overPct = (try? c.decodeIfPresent(Double.self, forKey: .over_pct)) ?? 0
        points = (try? c.decodeIfPresent(Int.self, forKey: .points)) ?? 0
        pts = (try? c.decodeIfPresent([TripPoint].self, forKey: .pts)) ?? []
    }

    var startDate: Date { Date(timeIntervalSince1970: start) }
    var km: Double { mileageKm > 0 ? mileageKm : distGpsKm }
}

struct TripData: Codable {
    let sn: String?
    let vehicle: String?
    let fetchedAt: String?
    let speedLimitKmh: Double?
    let trips: [Trip]

    enum CodingKeys: String, CodingKey {
        case sn, vehicle, fetched_at, speed_limit_kmh, trips
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sn = try? c.decodeIfPresent(String.self, forKey: .sn)
        vehicle = try? c.decodeIfPresent(String.self, forKey: .vehicle)
        fetchedAt = try? c.decodeIfPresent(String.self, forKey: .fetched_at)
        speedLimitKmh = try? c.decodeIfPresent(Double.self, forKey: .speed_limit_kmh)
        trips = (try? c.decodeIfPresent([Trip].self, forKey: .trips)) ?? []
    }

    var latest: Trip? {
        trips.max(by: { $0.start < $1.start })
    }
}

struct RefreshStatus: Codable {
    let running: Bool
    let ok: Bool?
    let error: String?
    let elapsed: Int?
    let fetchedAt: String?
    let trips: Int?
    enum CodingKeys: String, CodingKey { case running, ok, error, elapsed, fetched_at, trips }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        running = (try? c.decode(Bool.self, forKey: .running)) ?? false
        ok = try? c.decodeIfPresent(Bool.self, forKey: .ok)
        error = try? c.decodeIfPresent(String.self, forKey: .error)
        elapsed = try? c.decodeIfPresent(Int.self, forKey: .elapsed)
        fetchedAt = try? c.decodeIfPresent(String.self, forKey: .fetched_at)
        trips = try? c.decodeIfPresent(Int.self, forKey: .trips)
    }
}
