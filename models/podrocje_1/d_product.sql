
{{ config(
    materialized = 'table',
    transient    = false,
    copy_grants  = true,
    post_hook = "
        insert into {{ this }} (d_product_sid, product_code, product_name, category, list_price, is_active,
                                dwh_inserted_at, dwh_updated_at)
        select -1, '-1', 'N/A', 'N/A', null, true, {{ load_ts() }}, {{ load_ts() }}
        from (select 1) as dummy
        where not exists (select 1 from {{ this }} where d_product_sid = -1)"
) }}

{%- set existing = adapter.get_relation(this.database, this.schema, this.identifier) if execute else none -%}




with src as (

    select
        product_code,
        product_name,
        category,
        list_price,
        is_active
    from {{ source('aplload', 'st_erp__products') }}

)

select
    {% if existing is not none -%}
    coalesce(tgt.d_product_sid, {{ seq_nextval('D_PRODUCT_SEQ') }})  as d_product_sid,
    {%- else -%}
    {{ seq_nextval('D_PRODUCT_SEQ') }}                               as d_product_sid,
    {%- endif %}
    src.product_code,
    src.product_name,
    src.category,
    src.list_price,
    src.is_active,
    {% if existing is not none -%}
    coalesce(tgt.dwh_inserted_at, {{ load_ts() }})                   as dwh_inserted_at,
    {%- else -%}
    {{ load_ts() }}                                                  as dwh_inserted_at,
    {%- endif %}
    {{ load_ts() }}                                                  as dwh_updated_at

from src
{% if existing is not none -%}
left join {{ this }} as tgt
       on tgt.product_code = src.product_code
{%- endif %}
