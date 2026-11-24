{% snapshot d_employee %}

{{ config(
    unique_key   = 'employee_id',
    strategy     = 'check',
    check_cols   = ['full_name', 'department', 'job_title', 'city'],
    snapshot_meta_column_names = {
        'dbt_valid_from': 'valid_from',
        'dbt_valid_to':   'valid_until',
        'dbt_scd_id':     'scd_id',
        'dbt_updated_at': 'dwh_updated_at'
    },
    dbt_valid_to_current = "'9999-12-31 00:00:00'::timestamp_ntz"
) }}

select
    {{ seq_nextval('D_EMPLOYEE_SEQ') }}  as d_employee_sid,
    employee_id,
    full_name,
    department,
    job_title,
    city
from {{ source('aplload', 'st_hr__employees') }}

{% endsnapshot %}
