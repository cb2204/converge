-- Singular test: fails (returns rows) if gold.revenue does not reconcile
-- against the independently-computed captured-payments oracle (ADR-0004:
-- revenue = SUM of captured payment amounts, never order totals or 'paid'),
-- or if any gold.revenue row is null/negative.

with oracle as (

    select round(coalesce(sum(amount), 0)::numeric, 2) as captured_amount
    from payments
    where status = 'captured'

),

gold as (

    select round(coalesce(sum(revenue), 0)::numeric, 2) as gold_amount
    from gold.revenue

)

select *
from oracle
cross join gold
where oracle.captured_amount <> gold.gold_amount
   or exists (
       select 1 from gold.revenue where revenue is null or revenue < 0
   )
