{{ config(materialized='table') }}

-- Silver conform: dedup raw.orders to one row per business key (order_id),
-- keeping the max-_lsn event per the sharpened seam contract. A max-_lsn
-- _op=delete tombstone removes the key from silver entirely.

with ranked as (

    select
        order_id,
        customer_id,
        product_id,
        quantity,
        unit_price,
        total_amount,
        status,
        ordered_at,
        _lsn,
        _op,
        _captured_at,
        _source_committed_at,
        row_number() over (
            partition by order_id
            order by _lsn desc
        ) as _rn

    from {{ source('raw', 'orders') }}

)

select
    order_id,
    customer_id,
    product_id,
    quantity,
    unit_price,
    total_amount,
    status,
    ordered_at,
    _lsn,
    _op,
    _captured_at,
    _source_committed_at
from ranked
where _rn = 1
  and _op <> 'delete'
