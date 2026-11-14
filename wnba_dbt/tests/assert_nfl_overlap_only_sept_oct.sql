-- NFL overlap can only happen in September and October (no NFL preseason in the data; WNBA season ends in October).
-- Fails if any game outside those months is flagged.
select *
from {{ ref('int_nfl_overlap') }}
where has_nfl_overlap
  and month(game_date) not in (9, 10)