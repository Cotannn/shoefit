# Admin analytics backend notes

## Required for the current Flutter release

No new endpoint is required. The dashboard calculates period comparisons,
revenue contribution, unit velocity, cancellations, repeat-customer rate, and
status health from the existing `admin_orders.php` response.

`admin_orders.php` must continue returning:

- the complete order history needed for the selected reporting period;
- `user_id`, `order_date`, `order_status`, `payment_status`, and
  `total_price` for every order;
- an `items` array containing `name`, `price`, and `quantity`.

Revenue is deliberately defined as paid, non-cancelled sales. It is not profit.

## Optional profitability upgrade

The current database does not expose product cost, so gross profit and margin
cannot be calculated honestly. Apply
`optional_profitability_migration.sql` only when you are ready to capture cost
prices in the product editor and API.

A future `admin_analytics.php` endpoint can follow
`admin_analytics_response.example.json`. The Flutter app does not call that
endpoint yet, so deploying these optional files cannot break the current app.

Recommended server-side formulas:

```text
gross_revenue = sum(order_item.price * order_item.quantity)
cost_of_goods = sum(order_item.unit_cost * order_item.quantity)
gross_profit = gross_revenue - cost_of_goods
gross_margin_percent = gross_profit / gross_revenue * 100
```

Store `unit_cost` on each order item at checkout. Reading the product's current
cost later would rewrite historical margin whenever a product cost changes.

