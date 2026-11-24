{#
  seq_nextval('D_CUSTOMER_SEQ')
    -> DWH_DEV.APLSDB.D_CUSTOMER_SEQ.nextval
  Baza in shema se vzameta iz modela, zato ista koda deluje na DEV/TEST/PROD.
#}
{% macro seq_nextval(seq_name) -%}
    {{ this.database }}.{{ this.schema }}.{{ seq_name }}.nextval
{%- endmacro %}


{#
  load_ts() -> enoten timestamp za celoten dbt run (UTC).
  Uporabljamo ga za VALID_FROM / VALID_UNTIL / DWH_INSERTED_AT / DWH_UPDATED_AT,
  da imajo vse vrstice istega loada isti čas.
#}
{% macro load_ts() -%}
    '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp_ntz
{%- endmacro %}


{#
  high_date() -> datum "odprte" verzije v SCD2
#}
{% macro high_date() -%}
    '9999-12-31 00:00:00'::timestamp_ntz
{%- endmacro %}
