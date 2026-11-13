-- ─── Fix RLS Policies for Events & Personnel ─────────────────────────────────
-- Earlier policies used explicit subqueries on `group_members` or `events`.
-- This triggered Postgres RLS query recursion or authorization silent drops
-- when fetching complex relations like `events(*, event_personnel(*))`.
--
-- We will use the existing `is_group_member()` SECURITY DEFINER function 
-- to instantly and safely authenticate these policies!

DROP POLICY IF EXISTS "Enable read access for all group members" ON public.events;
CREATE POLICY "Enable read access for all group members" ON public.events
    FOR SELECT USING (is_group_member(group_id));

DROP POLICY IF EXISTS "Enable insert for all group members" ON public.events;
CREATE POLICY "Enable insert for all group members" ON public.events
    FOR INSERT WITH CHECK (is_group_member(group_id));

DROP POLICY IF EXISTS "Enable update for all group members" ON public.events;
CREATE POLICY "Enable update for all group members" ON public.events
    FOR UPDATE USING (is_group_member(group_id));

DROP POLICY IF EXISTS "Enable delete for all group members" ON public.events;
CREATE POLICY "Enable delete for all group members" ON public.events
    FOR DELETE USING (is_group_member(group_id));


-- Apply the exact same safe check to event_personnel by looking up the event's group_id!
DROP POLICY IF EXISTS "Enable read access for all event personnel" ON public.event_personnel;
CREATE POLICY "Enable read access for all event personnel" ON public.event_personnel
    FOR SELECT USING (
      is_group_member((SELECT group_id FROM public.events WHERE id = event_id LIMIT 1))
    );

DROP POLICY IF EXISTS "Enable insert for all event personnel" ON public.event_personnel;
CREATE POLICY "Enable insert for all event personnel" ON public.event_personnel
    FOR INSERT WITH CHECK (
      is_group_member((SELECT group_id FROM public.events WHERE id = event_id LIMIT 1))
    );

DROP POLICY IF EXISTS "Enable update for all event personnel" ON public.event_personnel;
CREATE POLICY "Enable update for all event personnel" ON public.event_personnel
    FOR UPDATE USING (
      is_group_member((SELECT group_id FROM public.events WHERE id = event_id LIMIT 1))
    );

DROP POLICY IF EXISTS "Enable delete for all event personnel" ON public.event_personnel;
CREATE POLICY "Enable delete for all event personnel" ON public.event_personnel
    FOR DELETE USING (
      is_group_member((SELECT group_id FROM public.events WHERE id = event_id LIMIT 1))
    );
