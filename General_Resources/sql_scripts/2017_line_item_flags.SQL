select flaggable_id, count(label) as num_open_flags, array_agg(label) as open_flag_labels
from public.flags where funding_year=2017 and flaggable_type='LineItem' and status='open' group by flaggable_id
