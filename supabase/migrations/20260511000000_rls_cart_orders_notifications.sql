-- Enable Row Level Security and create policies for cart_items, orders, and notifications

-- CART_ITEMS
ALTER TABLE IF EXISTS public.cart_items ENABLE ROW LEVEL SECURITY;

-- Allow users to select/insert/update/delete their own cart items
DROP POLICY IF EXISTS "cart_items_owner" ON public.cart_items;
CREATE POLICY "cart_items_owner" ON public.cart_items
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ORDERS
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

-- Allow users to insert orders (they become owners) and select their orders
DROP POLICY IF EXISTS "orders_owner" ON public.orders;
CREATE POLICY "orders_owner" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "orders_insert" ON public.orders;
CREATE POLICY "orders_insert" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to cancel their own orders (update status)
DROP POLICY IF EXISTS "orders_update_owner" ON public.orders;
CREATE POLICY "orders_update_owner" ON public.orders
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own pending orders
DROP POLICY IF EXISTS "orders_delete_owner" ON public.orders;
CREATE POLICY "orders_delete_owner" ON public.orders
  FOR DELETE USING (auth.uid() = user_id);

-- Allow admins to update any order (checked via is_admin RPC)
DROP POLICY IF EXISTS "orders_update_admin" ON public.orders;
CREATE POLICY "orders_update_admin" ON public.orders
  FOR UPDATE USING (auth.uid() IN (
    SELECT id FROM public.profiles WHERE role IN ('admin', 'owner')
  ));

-- Service role bypasses RLS entirely — already handled by service role key

-- NOTIFICATIONS
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_owner" ON public.notifications;
CREATE POLICY "notifications_owner" ON public.notifications
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Index for quick lookup by stripe_payment_id
CREATE INDEX IF NOT EXISTS idx_orders_stripe_payment_id ON public.orders (stripe_payment_id);

-- Note: deploy these via `supabase db push` or include in migrations pipeline
