-- Gold: revenue-by-product, routed through the transitive join
-- payments -> orders -> products (ADR-0006 — payments carries no
-- product_id). Payments are pre-aggregated to order_id BEFORE the join to
-- orders (ADR-0005: non-unique order_id FK), and that order-grain revenue
-- is aggregated to product_id BEFORE the join to products, so neither hop
-- can fan out revenue. Every product gets a row (left join), zero revenue
-- where no captured payment ever reached it.

create schema if not exists gold;

drop table if exists gold.revenue_by_product;

create table gold.revenue_by_product as
with captured_payments as (

    select
        order_id,
        sum(amount) as captured_amount
    from payments
    where status = 'captured'
    group by order_id

),

order_revenue as (

    select
        o.product_id,
        cp.captured_amount
    from orders o
    join captured_payments cp on cp.order_id = o.order_id

),

product_revenue as (

    select
        product_id,
        sum(captured_amount) as revenue
    from order_revenue
    group by product_id

)

select
    p.product_id,
    p.name,
    coalesce(pr.revenue, 0)::numeric(12, 2) as revenue
from products p
left join product_revenue pr on pr.product_id = p.product_id;
