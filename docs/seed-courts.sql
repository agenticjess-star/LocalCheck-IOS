-- LocalCheck Court Seed Data
-- Paste this into Supabase SQL Editor: https://supabase.com/dashboard/project/jzclwnzcektqhgkkdeje/sql/new
-- Run once. Safe to re-run (uses ON CONFLICT DO NOTHING on id).

-- Conroe / The Woodlands area (your home base)
INSERT INTO courts (id, name, address, latitude, longitude, sport_type, is_confirmed)
VALUES
  (gen_random_uuid(), 'Spring Creek Pickleball', '1001 E Dallas St, Conroe, TX 77301', 30.3117, -95.4488, 'Pickleball', true),
  (gen_random_uuid(), 'The Woodlands Rec Center', '5310 Research Forest Dr, The Woodlands, TX 77381', 30.1810, -95.4907, 'Basketball', true),
  (gen_random_uuid(), 'Bear Branch Park Courts', '5200 Research Forest Dr, The Woodlands, TX 77381', 30.1795, -95.4885, 'Pickleball', true),
  (gen_random_uuid(), 'Carl Barton Jr Park', '2500 S Loop 336 W, Conroe, TX 77304', 30.2895, -95.4720, 'Basketball', true),
  (gen_random_uuid(), 'Northshore Park', '2505 Lake Woodlands Dr, The Woodlands, TX 77380', 30.1730, -95.4610, 'Volleyball', true),
  (gen_random_uuid(), 'Rob Fleming Park', '6055 Creekside Forest Dr, The Woodlands, TX 77389', 30.1960, -95.5380, 'Pickleball', true);

-- Houston (nearby metro)
INSERT INTO courts (id, name, address, latitude, longitude, sport_type, is_confirmed)
VALUES
  (gen_random_uuid(), 'Memorial Park Courts', '7575 N Picnic Ln, Houston, TX 77007', 29.7640, -95.4340, 'Basketball', true),
  (gen_random_uuid(), 'Levy Park Pickleball', '3801 Eastside St, Houston, TX 77098', 29.7360, -95.4180, 'Pickleball', true),
  (gen_random_uuid(), 'Hermann Park Courts', '1700 Hermann Dr, Houston, TX 77004', 29.7220, -95.3900, 'Basketball', true),
  (gen_random_uuid(), 'Stude Park', '1031 Stude St, Houston, TX 77007', 29.7740, -95.3980, 'Pickleball', true);

-- Austin (expansion market)
INSERT INTO courts (id, name, address, latitude, longitude, sport_type, is_confirmed)
VALUES
  (gen_random_uuid(), 'Zilker Park Courts', '2100 Barton Springs Rd, Austin, TX 78704', 30.2670, -97.7730, 'Basketball', true),
  (gen_random_uuid(), 'South Austin Rec Pickleball', '1100 Cumberland Rd, Austin, TX 78704', 30.2380, -97.7690, 'Pickleball', true);

-- Dallas (expansion market)
INSERT INTO courts (id, name, address, latitude, longitude, sport_type, is_confirmed)
VALUES
  (gen_random_uuid(), 'Reverchon Park', '3505 Maple Ave, Dallas, TX 75219', 32.8020, -96.8100, 'Basketball', true),
  (gen_random_uuid(), 'Kiest Park Pickleball', '3080 S Hampton Rd, Dallas, TX 75224', 32.7120, -96.8540, 'Pickleball', true);
