{#
  backup_table()
  --------------
  Uporablja se kot pre-hook na vseh modelih (dbt_project.yml).
  Pred kreiranjem / spremembo tabele na PROD naredi zero-copy CLONE:

      CREATE TRANSIENT TABLE IF NOT EXISTS DWH_BACKUP.APLSDB.D_CUSTOMER_20261123
          CLONE DWH_PROD.APLSDB.D_CUSTOMER;

  Pogoji:
    - target baza je DWH_PROD
    - var backup_enabled = true   (poda ga samo deploy job)
    - tabela že obstaja (ob prvem deployu ni česa backupirati)

  IF NOT EXISTS -> če isti dan deployaš večkrat, ostane backup stanja
  PRED prvim deployem tistega dne.
  TRANSIENT     -> transient tabele se ne morejo klonirati v permanentne,
                   obratno pa lahko; za backupe tudi ne rabimo fail-safe.
#}
{% macro backup_table() -%}
    {%- if execute
          and target.database | upper == 'DWH_PROD'
          and var('backup_enabled', false) | string | lower in ['true', '1', 'yes'] -%}

        {%- set existing = adapter.get_relation(
                database=this.database,
                schema=this.schema,
                identifier=this.identifier) -%}

        {%- if existing is not none and existing.is_table -%}
            create transient table if not exists
                DWH_BACKUP.{{ this.schema }}.{{ this.identifier }}_{{ run_started_at.strftime('%Y%m%d') }}
                clone {{ this }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
