set autocommit off;
open schema tpc;
delete * from history2;
commit;
exit;

