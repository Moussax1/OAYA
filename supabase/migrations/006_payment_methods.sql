-- Payment methods table for saved payment methods
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('stripe', 'cod')),
  stripe_payment_method_id TEXT,
  last_four TEXT,
  brand TEXT,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own payment methods" ON public.payment_methods;
CREATE POLICY "Users can view own payment methods"
  ON public.payment_methods FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own payment methods" ON public.payment_methods;
CREATE POLICY "Users can insert own payment methods"
  ON public.payment_methods FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own payment methods" ON public.payment_methods;
CREATE POLICY "Users can delete own payment methods"
  ON public.payment_methods FOR DELETE USING (auth.uid() = user_id);

-- Only one default payment method per user
CREATE OR REPLACE FUNCTION public.ensure_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_default THEN
    UPDATE public.payment_methods
    SET is_default = false
    WHERE user_id = NEW.user_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS ensure_single_default_payment_method_trigger ON public.payment_methods;
CREATE TRIGGER ensure_single_default_payment_method_trigger
  BEFORE INSERT OR UPDATE OF is_default ON public.payment_methods
  FOR EACH ROW EXECUTE FUNCTION public.ensure_single_default_payment_method();
