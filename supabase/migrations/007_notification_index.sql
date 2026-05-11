-- Add index for efficient unread count queries on notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_read
  ON public.notifications (user_id, read)
  WHERE read = false;

-- Add index for sorted notification listing
CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC);
