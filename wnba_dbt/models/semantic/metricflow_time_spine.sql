-- One row per day, 2024-01-01 to 2025-12-31. MetricFlow requires this calendar table.
{{ config(materialized='table') }}

with days as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-01-01' as date)",
        end_date="cast('2026-01-01' as date)"
    ) }}
)

select cast(date_day as date) as date_day
from days