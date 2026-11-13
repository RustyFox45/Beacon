-- ─── TABLE ───────────────────────────────────────────────────────────────────

CREATE TABLE groups (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  icon_url        TEXT NOT NULL DEFAULT '',
  group_photo_url TEXT NOT NULL DEFAULT '',
  is_private      BOOLEAN NOT NULL DEFAULT FALSE,
  add_code        TEXT UNIQUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their groups"
  ON groups FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = id AND group_members.user_id = auth.uid()
  ));

CREATE POLICY "Authenticated users can create groups"
  ON groups FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can update groups"
  ON groups FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'Admin'
  ));

CREATE POLICY "Admins can delete groups"
  ON groups FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'Admin'
  ));
