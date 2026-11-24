
{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'customer_id',
    merge_update_columns = ['first_name', 'last_name', 'email', 'city', 'segment',
                             'dwh_updated_at'],
    tmp_relation_type    = 'table',
    on_schema_change     = 'append_new_columns'
) }}

with src as (

    select
        customer_id,
        first_name,
        last_name,
        email,
        city,
        segment,
        registration_date,
        stolpec1
    from {{ source('aplload', 'st_crm__customers') }}

)

select
    {{ seq_nextval('D_CUSTOMER_SEQ') }}  as d_customer_sid,   -- uporabi se samo pri INSERT-u
    src.customer_id,
    src.first_name,
    src.last_name,
    src.email,
    src.city,
    src.stolpec1,
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
