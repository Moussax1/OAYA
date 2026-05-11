-- Reviews table for product ratings and comments
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products ON DELETE CASCADE NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;
CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own reviews" ON public.reviews;
CREATE POLICY "Users can insert own reviews"
  ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own reviews" ON public.reviews;
CREATE POLICY "Users can update own reviews"
  ON public.reviews FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own reviews" ON public.reviews;
CREATE POLICY "Users can delete own reviews"
  ON public.reviews FOR DELETE USING (auth.uid() = user_id);
