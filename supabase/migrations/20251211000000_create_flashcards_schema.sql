-- Migration: Create flashcards schema
-- Purpose: Initialize the core tables for the 10x-cards flashcard application
-- Tables affected: flashcards_gen_sessions, flashcards
-- Author: Database Migration System
-- Date: 2025-12-11
-- Special Notes:
--   - All tables include Row Level Security (RLS) for data isolation per user
--   - Cascading deletes ensure data consistency when users are deleted
--   - JSONB proposals column allows flexible storage of AI-generated suggestions

-- ============================================================================
-- TABLE: flashcards_gen_sessions
-- ============================================================================
-- Purpose: Store AI generation session metadata and generated flashcard proposals
-- 
-- The proposals JSONB column stores an array of candidate flashcards with their
-- status (pending, accepted, or rejected). This allows the frontend to show
-- suggestions and track user decisions without duplicating data in main flashcards table.
--

create table public.flashcards_gen_sessions (
  -- Primary key: unique session identifier
  id uuid not null default gen_random_uuid() primary key,
  
  -- Foreign key to auth.users with cascading delete
  -- Ensures all sessions are deleted when user is deleted
  user_id uuid not null,
  
  -- Source text for AI generation (size constraints for API cost control)
  -- Min 1000 chars to ensure meaningful content
  -- Max 10000 chars to prevent excessive API usage
  source_text text not null,
  
  -- JSONB array storing proposed flashcards:
  -- [
  --   {
  --     "id": "uuid-string",
  --     "front": "Question text",
  --     "back": "Answer text",
  --     "status": "pending|accepted|rejected"
  --   },
  --   ...
  -- ]
  -- Default empty array for new sessions
  proposals jsonb not null default '[]'::jsonb,
  
  -- Counter: total proposals generated in this session
  -- Used for analytics and tracking
  generated_count integer not null default 0,
  
  -- Counter: total proposals that user accepted and converted to flashcards
  -- Used to measure AI quality and user satisfaction
  accepted_count integer not null default 0,
  
  -- Audit timestamps
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  
  -- Constraints: ensure source_text meets length requirements for meaningful content
  constraint source_text_length check (
    length(source_text) >= 1000 and length(source_text) <= 10000
  ),
  
  -- Foreign key constraint with cascading delete
  -- If user is deleted, all their generation sessions are deleted
  constraint fk_gen_sessions_user
    foreign key (user_id)
    references auth.users(id)
    on delete cascade
);

-- Enable row level security for data isolation
alter table public.flashcards_gen_sessions enable row level security;

-- RLS Policy: SELECT - Allow authenticated users to see only their own sessions
create policy "Users can select own flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for select
  to authenticated
  using (user_id = auth.uid());

-- RLS Policy: SELECT - Deny anonymous users
create policy "Anon users cannot select flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for select
  to anon
  using (false);

-- RLS Policy: INSERT - Allow authenticated users to create their own sessions
create policy "Users can insert own flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- RLS Policy: INSERT - Deny anonymous users
create policy "Anon users cannot insert flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for insert
  to anon
  with check (false);

-- RLS Policy: UPDATE - Allow authenticated users to update only their own sessions
create policy "Users can update own flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- RLS Policy: UPDATE - Deny anonymous users
create policy "Anon users cannot update flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for update
  to anon
  using (false)
  with check (false);

-- RLS Policy: DELETE - Allow authenticated users to delete only their own sessions
create policy "Users can delete own flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for delete
  to authenticated
  using (user_id = auth.uid());

-- RLS Policy: DELETE - Deny anonymous users
create policy "Anon users cannot delete flashcards_gen_sessions"
  on public.flashcards_gen_sessions
  for delete
  to anon
  using (false);

-- Index: Optimize queries filtering by user_id
-- This table is primarily queried by: "get all sessions for a user"
create index idx_flashcards_gen_sessions_user_id
  on public.flashcards_gen_sessions(user_id);

-- ============================================================================
-- TABLE: flashcards
-- ============================================================================
-- Purpose: Store the main flashcard data created by users (either manually or via AI)
--
-- Each flashcard has a front (question) and back (answer), along with metadata
-- about its source and optionally which AI generation session created it.
--

create table public.flashcards (
  -- Primary key: unique flashcard identifier
  id uuid not null default gen_random_uuid() primary key,
  
  -- Foreign key to auth.users with cascading delete
  -- Ensures all flashcards are deleted when user is deleted
  user_id uuid not null,
  
  -- Front side of flashcard (question)
  -- Limit to 500 chars to keep questions concise and testable
  front varchar(500) not null,
  
  -- Back side of flashcard (answer)
  -- Limit to 2000 chars to allow detailed explanations
  back varchar(2000) not null,
  
  -- Source tracking: how was this flashcard created?
  -- 'manual': user created directly
  -- 'ai_generated': created from AI generation session
  -- This helps with analytics and UI hints to user
  source varchar(20) not null,
  
  -- Optional: Reference to the AI generation session that created this flashcard
  -- NULL if created manually (source = 'manual')
  -- Set to NULL on cascade when generation session is deleted
  generation_id uuid,
  
  -- Audit timestamps
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  
  -- Constraint: enforce valid source values
  -- Using CHECK constraint to maintain data integrity at database level
  constraint source_enum check (
    source in ('manual', 'ai_generated')
  ),
  
  -- Foreign key constraint with cascading delete
  -- If user is deleted, all their flashcards are deleted
  constraint fk_flashcards_user
    foreign key (user_id)
    references auth.users(id)
    on delete cascade,
  
  -- Foreign key constraint with cascading delete
  -- If generation session is deleted, generation_id is set to NULL
  -- This allows deletion of generation sessions without deleting flashcards
  constraint fk_flashcards_generation
    foreign key (generation_id)
    references public.flashcards_gen_sessions(id)
    on delete set null
);

-- Enable row level security for data isolation
alter table public.flashcards enable row level security;

-- RLS Policy: SELECT - Allow authenticated users to see only their own flashcards
create policy "Users can select own flashcards"
  on public.flashcards
  for select
  to authenticated
  using (user_id = auth.uid());

-- RLS Policy: SELECT - Deny anonymous users
create policy "Anon users cannot select flashcards"
  on public.flashcards
  for select
  to anon
  using (false);

-- RLS Policy: INSERT - Allow authenticated users to create their own flashcards
create policy "Users can insert own flashcards"
  on public.flashcards
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- RLS Policy: INSERT - Deny anonymous users
create policy "Anon users cannot insert flashcards"
  on public.flashcards
  for insert
  to anon
  with check (false);

-- RLS Policy: UPDATE - Allow authenticated users to update only their own flashcards
create policy "Users can update own flashcards"
  on public.flashcards
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- RLS Policy: UPDATE - Deny anonymous users
create policy "Anon users cannot update flashcards"
  on public.flashcards
  for update
  to anon
  using (false)
  with check (false);

-- RLS Policy: DELETE - Allow authenticated users to delete only their own flashcards
create policy "Users can delete own flashcards"
  on public.flashcards
  for delete
  to authenticated
  using (user_id = auth.uid());

-- RLS Policy: DELETE - Deny anonymous users
create policy "Anon users cannot delete flashcards"
  on public.flashcards
  for delete
  to anon
  using (false);

-- Index: Optimize queries filtering by user_id
-- This table is primarily queried by: "get all flashcards for a user"
create index idx_flashcards_user_id
  on public.flashcards(user_id);

-- Index: Optimize joins and filtering by generation_id
-- Used for: "delete all proposals in a session" queries
create index idx_flashcards_generation_id
  on public.flashcards(generation_id);

-- ============================================================================
-- SUMMARY OF SECURITY
-- ============================================================================
-- Both tables implement Row Level Security (RLS) with the following policies:
-- 
-- - Authenticated users (auth.uid() = user_id): Full CRUD access to own data
-- - Anonymous users: No access (all policies return false)
-- 
-- This ensures:
--   1. Data isolation: Users can only see/modify their own data
--   2. Cascading deletes: When a user is deleted, all related data is removed
--   3. Referential integrity: Foreign keys maintain data consistency
-- ============================================================================
