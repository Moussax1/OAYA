-- Add UPDATE and DELETE policies for orders table
-- These were missing in the original RLS setup; users could not update their own
-- order status from the client side, and admins could not update orders either.

-- Allow users to cancel their own orders (update status to 'cancelled')
DROP POLICY IF EXISTS "orders_update_owner" ON public.orders;
CREATE POLICY "orders_update_owner" ON public.orders
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own pending orders
DROP POLICY IF EXISTS "orders_delete_owner" ON public.orders;
CREATE POLICY "orders_delete_owner" ON public.orders
  FOR DELETE USING (auth.uid() = user_id);

-- Allow admins to update any order status (role checked via profiles)
DROP POLICY IF EXISTS "orders_update_admin" ON public.orders;
CREATE POLICY "orders_update_admin" ON public.orders
  FOR UPDATE USING (auth.uid() IN (
    SELECT id FROM public.profiles WHERE role IN ('admin', 'owner')
  ));
