{#
  scd1_update(source_relation, key, columns)
  ------------------------------------------
  Post-hook za snapshot: SCD1 atribute prepiše na VSEH verzijah
  (tudi zgodovinskih) iz trenutnega stanja v viru.
  Posodobi samo vrstice, kjer se vrednost res razlikuje (IS DISTINCT FROM = null-safe).

  Primer generiranega SQL-a:
      update DWH_DEV.APLSDB.D_STORE_SNAP as tgt
      set store_name = src.store_name, phone = src.phone
      from DWH_DEV.APLLOAD.ST_POS__STORES as src
      where tgt.store_code = src.store_code
        and (tgt.store_name is distinct from src.store_name
          or tgt.phone      is distinct from src.phone)
#}
{% macro scd1_update(source_relation, key, columns) -%}
    update {{ this }} as tgt
    set
        {%- for c in columns %}
        {{ c }} = src.{{ c }}{{ "," if not loop.last }}
        {%- endfor %}
    from {{ source_relation }} as src
    where tgt.{{ key }} = src.{{ key }}
      and (
        {%- for c in columns %}
        tgt.{{ c }} is distinct from src.{{ c }}{{ " or" if not loop.last }}
        {%- endfor %}
      )
{%- endmacro %}
