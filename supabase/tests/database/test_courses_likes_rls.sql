-- Enable pgcrypto if needed for UUIDs (optional)
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

BEGIN;

-- Plan total number of tests
SELECT plan(7);

-- ========================================
-- Step 1: Validate RLS Policies
-- ========================================
SELECT policies_are(
  'public',
  'courses_likes',
  ARRAY[
    'Users can view only their own liked courses',
    'Users can insert only their own likes',
    'Users can delete only their own likes'
  ]
);


-- ========================================
-- Step 2: Setup consistent test data
-- ========================================

-- Insert into auth.users (supabase)
INSERT INTO auth.users (id) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), -- Auth A
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'); -- Auth B

-- Clean related test data
DELETE FROM public.courses_likes;
DELETE FROM public.users;
DELETE FROM public.courses;

-- Insert users (user_id = auth.uid())
INSERT INTO public.users (
  id, auth_user_id, first_name, last_name, created_at, updated_at
) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'User', 'A', now(), now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'User', 'B', now(), now());

-- Insert courses
INSERT INTO public.courses (
  id, title, active, cost, created_at, updated_at
) VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Course A', true, 49.99, now(), now()),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Course B', true, 99.99, now(), now());

-- Insert initial likes
INSERT INTO public.courses_likes (
  user_id, course_id, created_at, updated_at
) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc', now(), now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'dddddddd-dddd-dddd-dddd-dddddddddddd', now(), now());


-- ========================================
-- Step 3: Verify SELECT access control
-- ========================================

-- User A sees only their own likes
SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
SET ROLE authenticated;

SELECT results_eq(
  'SELECT user_id::text, course_id::text FROM public.courses_likes ORDER BY course_id',
  $$ VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc') $$,
  'User A should see only their own liked courses'
);

-- User B sees only their own likes
SET LOCAL request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
SET ROLE authenticated;

SELECT results_eq(
  'SELECT user_id::text, course_id::text FROM public.courses_likes ORDER BY course_id',
  $$ VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'dddddddd-dddd-dddd-dddd-dddddddddddd') $$,
  'User B should see only their own liked courses'
);


-- ========================================
-- Step 4: Verify INSERT policy
-- ========================================

-- User A inserts a new like for themselves
SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
SET ROLE authenticated;

SELECT lives_ok(
  $$INSERT INTO public.courses_likes (user_id, course_id, created_at) 
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', now())$$,
  'User A can insert like for themselves'
);


-- User A cannot insert like for User B
SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
SET ROLE authenticated;

SELECT throws_ok(
  $$INSERT INTO public.courses_likes (user_id, course_id, created_at) 
    VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'cccccccc-cccc-cccc-cccc-cccccccccccc', now())$$,
  'new row violates row-level security policy for table "courses_likes"',
  'User A cannot insert a like for User B'
);



-- ========================================
-- Step 5: Verify DELETE policy
-- ========================================

-- User B can delete their own like
SET LOCAL request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
SET ROLE authenticated;

SELECT lives_ok(
  $$DELETE FROM public.courses_likes 
    WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' AND course_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'$$,
  'User B can delete their own like'
);


-- Test: User B cannot delete User A’s like
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

SELECT throws_ok(
  $$DELETE FROM public.courses_likes 
    WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' 
      AND course_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  'permission denied for table courses_likes',
  'User B cannot delete User A''s like'
);



-- ========================================
-- Done
-- ========================================
SELECT * FROM finish();
ROLLBACK;
