-- ─── events ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS events (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id       UUID        NOT NULL REFERENCES groups(id)       ON DELETE CASCADE,
  lesson_plan_id UUID                 REFERENCES lesson_plans(id) ON DELETE SET NULL,
  title          TEXT        NOT NULL,
  date           TIMESTAMPTZ NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view events"    ON events;
CREATE POLICY "Members can view events"
  ON events FOR SELECT
  USING (is_group_member(group_id));

DROP POLICY IF EXISTS "Admins can create events"   ON events;
CREATE POLICY "Admins can create events"
  ON events FOR INSERT
  WITH CHECK (is_group_admin(group_id));

DROP POLICY IF EXISTS "Admins can update events"   ON events;
CREATE POLICY "Admins can update events"
  ON events FOR UPDATE
  USING (is_group_admin(group_id));

DROP POLICY IF EXISTS "Admins can delete events"   ON events;
CREATE POLICY "Admins can delete events"
  ON events FOR DELETE
  USING (is_group_admin(group_id));

CREATE INDEX IF NOT EXISTS idx_events_group_id       ON events(group_id);
CREATE INDEX IF NOT EXISTS idx_events_lesson_plan_id ON events(lesson_plan_id);

-- ─── event_personnel ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS event_personnel (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id   UUID        NOT NULL REFERENCES events(id)   ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role_name  TEXT        NOT NULL,
  agreed     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE event_personnel ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view event personnel"    ON event_personnel;
CREATE POLICY "Members can view event personnel"
  ON event_personnel FOR SELECT
  USING (
    is_group_member((SELECT group_id FROM events WHERE id = event_id LIMIT 1))
  );

DROP POLICY IF EXISTS "Admins can add event personnel"      ON event_personnel;
CREATE POLICY "Admins can add event personnel"
  ON event_personnel FOR INSERT
  WITH CHECK (
    is_group_admin((SELECT group_id FROM events WHERE id = event_id LIMIT 1))
  );

-- Personnel update their own agreed status; admins can update any record.
DROP POLICY IF EXISTS "Personnel or admins can update event personnel" ON event_personnel;
CREATE POLICY "Personnel or admins can update event personnel"
  ON event_personnel FOR UPDATE
  USING (
    user_id = auth.uid()
    OR is_group_admin((SELECT group_id FROM events WHERE id = event_id LIMIT 1))
  );

DROP POLICY IF EXISTS "Admins can delete event personnel"   ON event_personnel;
CREATE POLICY "Admins can delete event personnel"
  ON event_personnel FOR DELETE
  USING (
    is_group_admin((SELECT group_id FROM events WHERE id = event_id LIMIT 1))
  );

CREATE INDEX IF NOT EXISTS idx_event_personnel_event_id ON event_personnel(event_id);
CREATE INDEX IF NOT EXISTS idx_event_personnel_user_id  ON event_personnel(user_id);

-- ─── event_comments ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS event_comments (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id   UUID        NOT NULL REFERENCES events(id)   ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content    TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE event_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view event comments"   ON event_comments;
CREATE POLICY "Members can view event comments"
  ON event_comments FOR SELECT
  USING (
    is_group_member((SELECT group_id FROM events WHERE id = event_id LIMIT 1))
  );

DROP POLICY IF EXISTS "Members can post event comments"   ON event_comments;
CREATE POLICY "Members can post event comments"
  ON event_comments FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND is_group_member((SELECT group_id FROM events WHERE id = event_id LIMIT 1))
  );

DROP POLICY IF EXISTS "Authors can delete their comments" ON event_comments;
CREATE POLICY "Authors can delete their comments"
  ON event_comments FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_event_comments_event_id ON event_comments(event_id);

-- ─── user_lesson_activity ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_lesson_activity (
  user_id        UUID        NOT NULL REFERENCES profiles(id)     ON DELETE CASCADE,
  lesson_plan_id UUID        NOT NULL REFERENCES lesson_plans(id) ON DELETE CASCADE,
  last_opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, lesson_plan_id)
);

ALTER TABLE user_lesson_activity ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own lesson activity"   ON user_lesson_activity;
CREATE POLICY "Users can view their own lesson activity"
  ON user_lesson_activity FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own lesson activity" ON user_lesson_activity;
CREATE POLICY "Users can insert their own lesson activity"
  ON user_lesson_activity FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own lesson activity" ON user_lesson_activity;
CREATE POLICY "Users can update their own lesson activity"
  ON user_lesson_activity FOR UPDATE
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_user_lesson_activity_lesson_plan_id
  ON user_lesson_activity(lesson_plan_id);

-- ─── upsert_lesson_activity RPC ───────────────────────────────────────────────
-- Single call to record (or refresh) the caller's last-opened timestamp for a
-- lesson plan, avoiding the need for separate INSERT and UPDATE client logic.

CREATE OR REPLACE FUNCTION upsert_lesson_activity(p_lesson_plan_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO user_lesson_activity (user_id, lesson_plan_id, last_opened_at)
    VALUES (auth.uid(), p_lesson_plan_id, NOW())
  ON CONFLICT (user_id, lesson_plan_id)
    DO UPDATE SET last_opened_at = NOW();
END;
$$;
