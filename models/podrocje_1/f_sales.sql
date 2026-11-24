
{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'sale_id',
    merge_update_columns = ['sale_ts', 'sale_date', 'store_code', 'd_product_sid', 'd_customer_sid',
                            'd_employee_sid', 'quantity', 'unit_price', 'amount',
                            'dwh_hash', 'dwh_updated_at'],
    on_schema_change     = 'append_new_columns'
) }}

with src as (

    select
        sale_id,
        sale_ts,
        store_code,
        product_code,
        customer_id,
        employee_id,
        quantity,
        unit_price,
        hash(sale_ts, store_code, product_code, customer_id,
             employee_id, quantity, unit_price)                as dwh_hash
    from {{ source('aplload', 'st_pos__sales') }}

),

delta as (

    select src.*
    from src
    {% if is_incremental() %}
    left join {{ this }} as trg
           on trg.sale_id = src.sale_id
    where trg.sale_id is null              -- nov zapis
       or trg.dwh_hash <> src.dwh_hash     -- spremenjen zapis
    {% endif %}

),

dim_product as (
    select d_product_sid, product_code
    from {{ ref('d_product') }}
),

dim_customer as (
    select d_customer_sid, customer_id
    from {{ ref('d_customer') }}
),

dim_employee as (
    select
        d_employee_sid,
        employee_id,
        case when valid_from = min(valid_from) over (partition by employee_id)
             then '1900-01-01 00:00:00'::timestamp_ntz
             else valid_from
        end                                                    as valid_from,
        valid_until
    from {{ ref('d_employee') }}           -- snapshot
)

select
    d.sale_id,
    d.sale_ts,
    d.sale_ts::date                                            as sale_date,
    d.store_code,
    coalesce(p.d_product_sid,  -1)                             as d_product_sid,
    coalesce(c.d_customer_sid, -1)                             as d_customer_sid,
    coalesce(e.d_employee_sid, -1)                             as d_employee_sid,
    d.quantity,
    d.unit_price,
    cast(d.quantity * d.unit_price as number(14,2))            as amount,
    d.dwh_hash,
    {{ load_ts() }}                                            as dwh_inserted_at,
    {{ load_ts() }}                                            as dwh_updated_at

from delta as d
left join dim_product  as p on p.product_code = d.product_code
left join dim_customer as c on c.customer_id  = d.customer_id
left join dim_employee as e on e.employee_id  = d.employee_id
                           and d.sale_ts >= e.valid_from
                           and d.sale_ts <  e.valid_until
