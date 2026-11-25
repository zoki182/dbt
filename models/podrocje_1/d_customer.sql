
{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'customer_id',
    merge_update_columns = ['first_name', 'last_name', 'email', 'city', 'segment',
                             'dwh_updated_at'],
    tmp_relation_type    = 'table',
    on_schema_change     = 'append_new_columns',
    post_hook = "
        insert into {{ this }} (d_customer_sid, customer_id, first_name, last_name, email, city, segment,
                                dwh_inserted_at, dwh_updated_at)
        select -1, -1, 'N/A', 'N/A', 'N/A', 'N/A', 'N/A', {{ load_ts() }}, {{ load_ts() }}
        from (select 1) as dummy
        where not exists (select 1 from {{ this }} where d_customer_sid = -1)"
) }}

with src as (

    select
        customer_id,
        first_name,
        last_name,
        email,
        city,
        segment,
        registration_date
    from {{ source('aplload', 'st_crm__customers') }}

)

select
    {{ seq_nextval('D_CUSTOMER_SEQ') }}  as d_customer_sid,   -- uporabi se samo pri INSERT-u
    src.customer_id,
    src.first_name,
    src.last_name,
    src.email,
    src.city,
    src.segment,
    src.registration_date,
    {{ load_ts() }}                       as dwh_inserted_at,  -- samo pri INSERT-u
    {{ load_ts() }}                       as dwh_updated_at
from src

{% if is_incremental() %}
left join {{ this }} as trg
       on trg.customer_id = src.customer_id
where trg.customer_id is null              -- nov zapis
  or hash(src.first_name, src.last_name, src.email, src.city, src.segment)
  <> hash(trg.first_name, trg.last_name, trg.email, trg.city, trg.segment)  -- spremenjeni
{% endif %}
