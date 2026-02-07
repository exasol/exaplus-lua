set autocommit off;
open schema tpc;
select * from history2;
rollback;
exit;

