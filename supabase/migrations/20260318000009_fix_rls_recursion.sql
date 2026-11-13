-- ─── Atomic group creation ────────────────────────────────────────────────────
-- Inserts the group and adds the caller as Admin in one SECURITY DEFINER
-- function. This avoids the race where .insert(...).select() on groups applies
-- the SELECT policy before the creator has been added to group_members.

CREATE OR REPLACE FUNCTION create_group(p_name TEXT)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_group_id UUID;
BEGIN
  INSERT INTO groups (name) VALUES (p_name) RETURNING id INTO v_group_id;
  INSERT INTO group_members (group_id, user_id, role)
    VALUES (v_group_id, auth.uid(), 'Admin');
  RETURN v_group_id;
END;
$$;

-- ─── Helper functions ─────────────────────────────────────────────────────────
-- Query group_members as the DB owner, bypassing RLS.
-- This breaks the self-referential recursion that occurs when RLS policies on
-- group_members reference group_members themselves.

CREATE OR REPLACE FUNCTION is_group_member(
  gid UUID,
  uid UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = gid AND user_id = uid
  );
$$;

CREATE OR REPLACE FUNCTION is_group_admin(
  gid UUID,
  uid UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = gid AND user_id = uid AND role = 'Admin'
  );
$$;

-- ─── Fix groups table policies ────────────────────────────────────────────────
-- The original policies referenced group_members in their USING/WITH CHECK
-- clauses, which triggered the group_members SELECT policy → recursion.

DROP POLICY IF EXISTS "Members can view their groups" ON groups;
CREATE POLICY "Members can view their groups"
  ON groups FOR SELECT
  USING (is_group_member(id));

DROP POLICY IF EXISTS "Admins can update groups" ON groups;
CREATE POLICY "Admins can update groups"
  ON groups FOR UPDATE
  USING (is_group_admin(id));

DROP POLICY IF EXISTS "Admins can delete groups" ON groups;
CREATE POLICY "Admins can delete groups"
  ON groups FOR DELETE
  USING (is_group_admin(id));

-- ─── Fix group_members table policies ─────────────────────────────────────────
-- The original SELECT policy was entirely self-referential. UPDATE/DELETE also
-- referenced group_members recursively via the admin-check subquery.

DROP POLICY IF EXISTS "Members can view group membership" ON group_members;
CREATE POLICY "Members can view group membership"
  ON group_members FOR SELECT
  USING (is_group_member(group_id));

DROP POLICY IF EXISTS "Admins or self can add members" ON group_members;
CREATE POLICY "Admins or self can add members"
  ON group_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    is_group_admin(group_id)
  );

DROP POLICY IF EXISTS "Admins can update roles" ON group_members;
CREATE POLICY "Admins can update roles"
  ON group_members FOR UPDATE
  USING (is_group_admin(group_id));

DROP POLICY IF EXISTS "Admins or self can remove members" ON group_members;
CREATE POLICY "Admins or self can remove members"
  ON group_members FOR DELETE
  USING (
    user_id = auth.uid() OR
    is_group_admin(group_id)
  );
