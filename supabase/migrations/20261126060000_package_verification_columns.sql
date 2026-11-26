-- =============================================================================
-- Migration: Package verification columns and carrier index
-- Date:      2026-11-26
-- Purpose:
--   1. Add pickup_verified, pickup_verified_at, delivery_verified,
--      delivery_verified_at columns to packages if they do not already exist.
--      These are written by the edge-function verify-pickup / verify-delivery
--      endpoints.
--   2. Add index on packages(carrier_id) for the carrier's package list query.
-- =============================================================================

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'packages'
  ) THEN

    -- pickup_verified
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'packages'
         AND column_name = 'pickup_verified'
    ) THEN
      ALTER TABLE public.packages
        ADD COLUMN pickup_verified BOOLEAN NOT NULL DEFAULT false;
    END IF;

    -- pickup_verified_at
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'packages'
         AND column_name = 'pickup_verified_at'
    ) THEN
      ALTER TABLE public.packages
        ADD COLUMN pickup_verified_at TIMESTAMPTZ;
    END IF;

    -- delivery_verified
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'packages'
         AND column_name = 'delivery_verified'
    ) THEN
      ALTER TABLE public.packages
        ADD COLUMN delivery_verified BOOLEAN NOT NULL DEFAULT false;
    END IF;

    -- delivery_verified_at
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'packages'
         AND column_name = 'delivery_verified_at'
    ) THEN
      ALTER TABLE public.packages
        ADD COLUMN delivery_verified_at TIMESTAMPTZ;
    END IF;

    -- index on carrier_id for carrier package list
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
       WHERE schemaname = 'public'
         AND tablename  = 'packages'
         AND indexname  = 'idx_packages_carrier_created'
    ) THEN
      CREATE INDEX idx_packages_carrier_created
        ON public.packages (carrier_id, created_at DESC)
        WHERE carrier_id IS NOT NULL;
    END IF;

  END IF;
END $$;
