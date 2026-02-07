set autocommit off;
open schema tpc;
select * from history2 h2 where not exists
(
    select * 
    from history h1
    where h1.h_p_key=h2.h_p_key 
        and h1.h_s_key = h2.h_s_key 
        and h1.h_o_key=h2.h_o_key 
        and h1.h_l_key=h2.h_l_key 
        and h1.h_delta=h2.h_delta 
);
commit;
