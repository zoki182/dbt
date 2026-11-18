select *
from {{ source('src1', 'customers') }}