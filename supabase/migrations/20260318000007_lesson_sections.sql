-- ─── TABLE ───────────────────────────────────────────────────────────────────

CREATE TABLE lesson_sections (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_plan_id UUID NOT NULL REFERENCES lesson_plans(id) ON DELETE CASCADE,
  title          TEXT NOT NULL DEFAULT '',
  content        TEXT NOT NULL DEFAULT '',
  type           section_type NOT NULL DEFAULT 'text',
  link_url       TEXT,
  link_title     TEXT,
  link_image_url TEXT,
  position       INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────

-- Access mirrors the parent lesson_plan
ALTER TABLE lesson_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lesson section read access"
  ON lesson_sections FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM lesson_plans lp
    WHERE lp.id = lesson_plan_id AND (
      lp.creator_id = auth.uid() OR (
        lp.group_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM group_members
          WHERE group_members.group_id = lp.group_id
            AND group_members.user_id = auth.uid()
        )
      )
    )
  ));

CREATE POLICY "Creators can insert sections"
  ON lesson_sections FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM lesson_plans WHERE id = lesson_plan_id AND creator_id = auth.uid()
  ));

CREATE POLICY "Creators can update sections"
  ON lesson_sections FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM lesson_plans WHERE id = lesson_plan_id AND creator_id = auth.uid()
  ));

CREATE POLICY "Creators can delete sections"
  ON lesson_sections FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM lesson_plans WHERE id = lesson_plan_id AND creator_id = auth.uid()
  ));
