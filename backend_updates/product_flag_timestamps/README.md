# Featured and new-arrival activation timestamps

The Flutter app already reads these optional product fields:

```json
{
  "is_featured": true,
  "featured_since": "2026-07-09 17:30:00",
  "is_new_arrival": true,
  "new_arrival_since": "2026-07-08 09:15:00"
}
```

Without these timestamp fields, the admin product list still displays the
Featured and New arrival badges, but it deliberately does not invent a date.
`created_at` is not a reliable substitute because a product can be promoted
long after it was created.

## Deployment

1. Back up the products table.
2. Verify the hosted table is named `products_shoefit`. Adjust the migration if
   your PHP API uses a different name.
3. Run `product_flag_timestamps_migration.sql` once.
4. Add the two fields shown in `product_response_patch.php` to the product
   mapping used by both `products.php` and `product_detail.php`.
5. Toggle a test product off and on, then verify that `products.php` returns the
   server timestamp.

The SQL triggers own the timestamps. This prevents a client from claiming a
false activation date and ensures every admin client uses the database clock.
Existing active flags remain `NULL` because their real historical activation
time cannot be reconstructed safely. Toggle them off and on only if you want to
begin tracking from the current date.

