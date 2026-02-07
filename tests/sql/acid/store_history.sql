set autocommit off;
open schema tpc;
select * from history;
rollback;
exit;

