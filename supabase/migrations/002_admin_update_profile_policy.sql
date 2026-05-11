-- Allow admins to update any profile so role promotion/demotion works under RLS.

DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());
