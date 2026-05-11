-- Addresses table for user shipping addresses
CREATE TABLE IF NOT EXISTS public.addresses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own addresses" ON public.addresses;
CREATE POLICY "Users can view own addresses"
  ON public.addresses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own addresses" ON public.addresses;
CREATE POLICY "Users can insert own addresses"
  ON public.addresses FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own addresses" ON public.addresses;
CREATE POLICY "Users can update own addresses"
  ON public.addresses FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own addresses" ON public.addresses;
CREATE POLICY "Users can delete own addresses"
  ON public.addresses FOR DELETE USING (auth.uid() = user_id);

-- Only one default address per user
CREATE OR REPLACE FUNCTION public.ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_default THEN
    UPDATE public.addresses
    SET is_default = false
    WHERE user_id = NEW.user_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS ensure_single_default_address_trigger ON public.addresses;
CREATE TRIGGER ensure_single_default_address_trigger
  BEFORE INSERT OR UPDATE OF is_default ON public.addresses
  FOR EACH ROW EXECUTE FUNCTION public.ensure_single_default_address();
