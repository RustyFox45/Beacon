-- ─── TABLE ───────────────────────────────────────────────────────────────────

CREATE TABLE lesson_plans (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title           TEXT NOT NULL DEFAULT '',
  description     TEXT NOT NULL DEFAULT '',
  target_audience TEXT NOT NULL DEFAULT '',
  date            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified_date   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  group_id        UUID REFERENCES groups(id) ON DELETE SET NULL,
  creator_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────

ALTER TABLE lesson_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators and group members can view lesson plans"
  ON lesson_plans FOR SELECT
  USING (
    creator_id = auth.uid() OR (
      group_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM group_members
        WHERE group_members.group_id = lesson_plans.group_id
          AND group_members.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Authenticated users can create lesson plans"
  ON lesson_plans FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update lesson plans"
  ON lesson_plans FOR UPDATE USING (creator_id = auth.uid());

CREATE POLICY "Creators can delete lesson plans"
  ON lesson_plans FOR DELETE USING (creator_id = auth.uid());
