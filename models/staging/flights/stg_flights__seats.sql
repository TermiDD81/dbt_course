{{
  config(
    materialized = 'table',
    )
}}

select
  aircraft_code,
  seat_no,
  fare_conditions
from 
  {{ source('demo_src', 'seats') }}

{% for rel in dbt_utils.get_relations_by_prefix(target.schema, 'stg_flights') -%}
  -- {{ rel }}
{% endfor %}