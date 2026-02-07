set autocommit off;
open schema tpc;
delete * from history;
commit;
exit;

