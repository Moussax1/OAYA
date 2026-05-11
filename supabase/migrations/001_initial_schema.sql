-- ============================================================================
-- OAYA E-Commerce — FINAL SQL SCHEMA
-- Run this completely in your Supabase SQL Editor
-- ============================================================================

create extension if not exists "uuid-ossp";

-- 0. FIX INFINITE RECURSION
-- This function allows checking for admin securely without triggering policies again
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'owner')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user',
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT USING (public.is_admin());

-- Auto-create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. PRODUCTS
CREATE TABLE IF NOT EXISTS public.products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  original_price NUMERIC(10,2) DEFAULT 0,
  image_url TEXT,
  category TEXT,
  badge TEXT,
  stock INTEGER DEFAULT 0 CHECK (stock >= 0),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Upgrade existing products table if it lacks these columns
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS original_price NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS badge TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
CREATE POLICY "Anyone can view active products"
  ON public.products FOR SELECT USING (active = true OR active IS NULL);

DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
CREATE POLICY "Admins can manage products"
  ON public.products FOR ALL USING (public.is_admin());

-- Seed initial products (Only inserts if empty)
INSERT INTO public.products (name, description, price, original_price, image_url, category, badge, stock)
SELECT 'Sac Élégance Cuir', 'Sac en cuir véritable avec finitions dorées, design intemporel.', 249.00, 299.00, 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&q=80', 'Accessoires', 'Nouveau', 25
WHERE NOT EXISTS (SELECT 1 FROM public.products LIMIT 1);

INSERT INTO public.products (name, description, price, original_price, image_url, category, badge, stock)
SELECT 'Montre Classique Or', 'Montre automatique avec bracelet en cuir et cadran doré.', 389.00, 450.00, 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=600&q=80', 'Montres', null, 10
WHERE NOT EXISTS (SELECT 1 FROM public.products WHERE name = 'Montre Classique Or');

INSERT INTO public.products (name, description, price, original_price, image_url, category, badge, stock)
SELECT 'Lunettes Soleil Aviateur', 'Lunettes de soleil aviateur avec monture dorée et verres polarisés.', 159.00, 0, 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&q=80', 'Accessoires', 'Best-seller', 50
WHERE NOT EXISTS (SELECT 1 FROM public.products WHERE name = 'Lunettes Soleil Aviateur');


-- 3. CART ITEMS
CREATE TABLE IF NOT EXISTS public.cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products ON DELETE CASCADE NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own cart items" ON public.cart_items;
CREATE POLICY "Users can view their own cart items" ON public.cart_items FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own cart items" ON public.cart_items;
CREATE POLICY "Users can insert their own cart items" ON public.cart_items FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own cart items" ON public.cart_items;
CREATE POLICY "Users can update their own cart items" ON public.cart_items FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own cart items" ON public.cart_items;
CREATE POLICY "Users can delete their own cart items" ON public.cart_items FOR DELETE USING (auth.uid() = user_id);


-- 4. ORDERS
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  total_amount NUMERIC(10,2) NOT NULL,
  shipping NUMERIC(10,2) DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','paid','shipped','delivered','cancelled')),
  payment_method TEXT DEFAULT 'cod',
  stripe_payment_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;
CREATE POLICY "Admins can view all orders" ON public.orders FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;
CREATE POLICY "Admins can update orders" ON public.orders FOR UPDATE USING (public.is_admin());


-- 5. ORDER ITEMS
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES public.orders ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products ON DELETE RESTRICT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items" ON public.order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can insert order items" ON public.order_items;
CREATE POLICY "Users can insert order items" ON public.order_items FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Admins can view all order items" ON public.order_items;
CREATE POLICY "Admins can view all order items" ON public.order_items FOR SELECT USING (public.is_admin());


-- 6. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);


-- 7. AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  actor_id UUID REFERENCES auth.users ON DELETE SET NULL,
  target_user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view audit logs" ON public.audit_logs;
CREATE POLICY "Admins can view audit logs"
  ON public.audit_logs FOR SELECT USING (public.is_admin());

DROP FUNCTION IF EXISTS public.log_profile_role_change();

CREATE OR REPLACE FUNCTION public.log_profile_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    INSERT INTO public.audit_logs (actor_id, target_user_id, action, old_value, new_value)
    VALUES (
      auth.uid(),
      NEW.id,
      'profile.role.changed',
      OLD.role,
      NEW.role
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS profile_role_audit_trigger ON public.profiles;
CREATE TRIGGER profile_role_audit_trigger
  AFTER UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.log_profile_role_change();
