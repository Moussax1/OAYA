-- Atomic stock decrement RPC, used after order creation to prevent overselling.
-- Returns false and does NOT decrement if stock would go below zero.

DROP FUNCTION IF EXISTS public.decrement_stock;

CREATE OR REPLACE FUNCTION public.decrement_stock(pid UUID, qty INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_stock INT;
BEGIN
  SELECT stock INTO current_stock
  FROM public.products
  WHERE id = pid
  FOR UPDATE;

  IF current_stock IS NULL THEN
    RAISE EXCEPTION 'Product % not found', pid;
  END IF;

  IF current_stock < qty THEN
    RAISE EXCEPTION 'Insufficient stock for product %: have %, need %', pid, current_stock, qty;
  END IF;

  UPDATE public.products
  SET stock = stock - qty
  WHERE id = pid;

  RETURN TRUE;
END;
$$;
