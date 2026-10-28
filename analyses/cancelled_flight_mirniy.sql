select
    scheduled_departure::date as scheduled_departure,
    count(*) as cancelled_flight_cnt
from
    {{ ref('fct_flights') }}
where
    departure_airport = 'MJZ'
    and status = 'Cancelled'
group by 
    scheduled_departure::date