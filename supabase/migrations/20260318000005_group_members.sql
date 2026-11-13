-- ─── TABLE ───────────────────────────────────────────────────────────────────

CREATE TABLE group_members (
  id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id  UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role      group_role NOT NULL DEFAULT 'Member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (group_id, user_id)
);

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view group membership"
  ON group_members FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_id AND gm.user_id = auth.uid()
  ));

-- Allows self-insert (joining via add_code) or admin adding others
CREATE POLICY "Admins or self can add members"
  ON group_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_id
        AND gm.user_id = auth.uid()
        AND gm.role = 'Admin'
    )
  );

CREATE POLICY "Admins can update roles"
  ON group_members FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_id
      AND gm.user_id = auth.uid()
      AND gm.role = 'Admin'
  ));

-- Members can leave; admins can remove others
CREATE POLICY "Admins or self can remove members"
  ON group_members FOR DELETE
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_id
        AND gm.user_id = auth.uid()
        AND gm.role = 'Admin'
    )
  );
