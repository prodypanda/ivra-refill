-- Add bottle_type and refill_type to products table
ALTER TABLE products
ADD COLUMN bottle_type TEXT NOT NULL DEFAULT 'with_pump',
ADD COLUMN refill_type TEXT NOT NULL DEFAULT 'refillable';
