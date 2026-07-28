-- Gold: revenue = SUM of captured payment amounts (ADR-0004) — never order
-- totals, never 'paid' (not a payments.status value). Payments are
-- pre-aggregated to order_id BEFORE the join to orders so the join cannot
-- fan out revenue (ADR-0005: payments.order_id is a non-unique FK). Silver
-- conforms only the orders domain so far and the raw capture window is
-- still a partial CDC slice, so this reconciles against the full
-- operational orders/payments tables to match the answer-key oracle.

create schema if not exists gold;

drop table if exists gold.revenue;

create table gold.revenue as
with captured_payments as (

    select
        order_id,
        sum(amount) as captured_amount
    from payments
    where status = 'captured'
    group by order_id

)

select
    o.order_id,
    o.customer_id,
    o.product_id,
    o.ordered_at,
    coalesce(cp.captured_amount, 0)::numeric(12, 2) as revenue
from orders o
left join captured_payments cp on cp.order_id = o.order_id;
