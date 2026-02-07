set autocommit off;

open schema tpc;

select * 
from ( 
    select o_orderkey, o_totalprice - sum( trunc( trunc ( l_extendedprice * (1-l_discount),2)*(1+l_tax),2)) part_res 
    from orders, lineitem 
    where o_orderkey=l_orderkey 
    group by o_orderkey, o_totalprice 
) where not part_res=0; 


exit;

