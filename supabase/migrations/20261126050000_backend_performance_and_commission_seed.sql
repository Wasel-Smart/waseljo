-- =============================================================================
-- Migration: Backend performance indexes and commission seed
-- Date:      2026-11-26
-- Purpose:
--   1. Add covering indexes used by the most frequent edge-function queries
--      (passenger booking list, trip search, package lists) so each lands on
--      an index scan rather than a sequential scan.
--   2. Seed the commission_config default row so the fallback in
--      app_create_ride_booking (20261126040000) always has a row to fall back to
--      when a trip has no per-trip rate set.
--   3. Add an index on packages(sender_id) for the /packages/sender/:id list.
--
-- All DDL is wrapped in DO blocks so the migration is safe to run against a DB
-- where the tables do not yet exist (skipped, not errored).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. bookings(passenger_id, created_at DESC) -- passenger booking list
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'bookings'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
       WHERE schemaname = 'public'
         AND tablename  = 'bookings'
         AND indexname  = 'idx_bookings_passenger_created'
    ) THEN
      CREATE INDEX idx_bookings_passenger_created
        ON public.bookings (passenger_id, created_at DESC);
    END IF;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. trips(trip_status, departure_time) -- trip search / open trips list
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'trips'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
       WHERE schemaname = 'public'
         AND tablename  = 'trips'
         AND indexname  = 'idx_trips_status_departure'
    ) THEN
      CREATE INDEX idx_trips_status_departure
        ON public.trips (trip_status, departure_time)
        WHERE deleted_at IS NULL;
    END IF;

    -- packages: allow_packages + trip_status + package_slots_remaining
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
       WHERE schemaname = 'public'
         AND tablename  = 'trips'
         AND indexname  = 'idx_trips_package_slots'
    ) THEN
      CREATE INDEX idx_trips_package_slots
        ON public.trips (allow_packages, trip_status, package_slots_remaining)
        WHERE allow_packages = true AND deleted_at IS NULL;
    END IF;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. packages(sender_id, created_at DESC) -- sender package list
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'packages'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
       WHERE schemaname = 'public'
         AND tablename  = 'packages'
         AND indexname  = 'idx_packages_sender_created'
    ) THEN
      CREATE INDEX idx_packages_sender_created
        ON public.packages (sender_id, created_at DESC);
    END IF;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. commission_config default row
--    app_create_ride_booking falls back to this when a trip has no per-trip rate.
--    INSERT ... ON CONFLICT DO NOTHING is idempotent.
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'commission_config'
  ) THEN
    INSERT INTO public.commission_config (route_key, rate_pct, effective_from)
    VALUES ('default', 12.00, '2026-01-01 00:00:00+00')
    ON CONFLICT (route_key) DO NOTHING;
  END IF;
END $$;
