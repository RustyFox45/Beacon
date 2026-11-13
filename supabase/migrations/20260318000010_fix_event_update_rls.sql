-- Allow members to see events
DROP POLICY IF EXISTS "Members can view events" ON events;
CREATE POLICY "Members can view events"
  ON events FOR SELECT
  USING (is_group_member(group_id));

-- Allow admins to create events
DROP POLICY IF EXISTS "Admins can create events" ON events;
CREATE POLICY "Admins can create events"
  ON events FOR INSERT
  WITH CHECK (is_group_admin(group_id));

-- Allow admins to update events
DROP POLICY IF EXISTS "Admins can update events" ON events;
CREATE POLICY "Admins can update events"
  ON events FOR UPDATE
  USING (is_group_admin(group_id));

-- Allow admins to delete events
DROP POLICY IF EXISTS "Admins can delete events" ON events;
CREATE POLICY "Admins can delete events"
  ON events FOR DELETE
  USING (is_group_admin(group_id));
