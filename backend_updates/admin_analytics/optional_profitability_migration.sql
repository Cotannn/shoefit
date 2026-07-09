-- Review table names against the hosted database before running this file.
-- The defaults below match the ShoeFit schema included in this repository.

ALTER TABLE products_shoefit
  ADD COLUMN cost_price DECIMAL(10, 2) NULL AFTER price;

ALTER TABLE order_items_shoefit
  ADD COLUMN unit_cost DECIMAL(10, 2) NULL AFTER price;

CREATE INDEX idx_orders_shoefit_analytics
  ON orders_shoefit (order_date, payment_status, order_status);

CREATE INDEX idx_order_items_shoefit_product
  ON order_items_shoefit (shoe_id, order_id);

-- Existing orders intentionally remain NULL because their historical cost is
-- unknown. Do not substitute today's product cost for past transactions.

