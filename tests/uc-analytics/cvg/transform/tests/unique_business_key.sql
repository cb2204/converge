-- Singular dbt test: fails (returns rows) if the business key is not
-- unique per the silver grain — i.e. dedup by max-_lsn did not hold.
select order_id
from {{ ref('orders') }}
group by order_id
having count(*) > 1
