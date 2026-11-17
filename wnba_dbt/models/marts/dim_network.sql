-- One row per TV network in the telecasts table.
-- is_broadcast: free over-the-air network (ABC, CBS, ION) vs cable (ESPN, ESPN2, CBSSN, NBA TV).
select distinct
    network,
    network in ('ABC', 'CBS', 'ION') as is_broadcast
from {{ ref('stg_telecasts') }}