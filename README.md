# remote_dbms_metadata

## What is it?
Routine to compare DDL structure differences between two databases. The DDL differences could be sent by email.

## Use case
I used this to automate DDL generation of two distinct databases. These two, or more, databases communicate between Oracle Matarialized View architecture. Those DDLs needed to be analyzed prior applying it due to peculiar needs.

## Features 
1. DDL generation
2. DDL materialized view
3. DDL customized for cases when more then one remote site is consuming the same source (FAKE_MVIEW_NEED)
4. Compare only objects altered in the past X days (DAYS).
5. List of emails to be notified (EMAIL_RECEIPT).
6. Capture table comments (ENABLE_COMMENT_COLUMN)
7. Index DDL generation (ENABLE_INDEX_DDL)
8. Check schemas that should be compared (OWNER_GPG_CHECK).
9. Blacklist for tables (API - add_Table_to_Blacklist)
10. Blacklist for table columns (BLACKLIST_COLUMN)
11. Control blacklist time (BLACKLIST_TABLE_TIME)

## API Call

### SendEmail
```
BEGIN
 MONITOR_ADM.REMOTE_DBMS_METADATA.SEND_DDL_BY_EMAIL('yourdblinkname.com');
END;
/
```

### Add table to blacklist
```
BEGIN
  MONITOR_ADM.REMOTE_DBMS_METADATA.ADD_TABLE_TO_BLACKLIST(PCOWNER => 'OWNER_1',
                                                          PCTABLE => 'TABLE_1');
END;
/
```

### Add column table to blacklist
```
begin
  monitor_adm.remote_dbms_metadata.addparameter(pcparametername => 'BLACKLIST_COLUMN',
                                                pcvalue         => 'OWNER_1.TABLE_2.COLUMN_1',
                                                pbisunique      => false,
                                                pcdescription   => 'Add column to blacklist <Owner>.<Table>.<Column>');
end;
/
```

## Credit
The original code to remote_dbms_metadata can be found on the URL below:
http://phil-sqltips.blogspot.com.br/2009/06/dbmsmetadata-across-database-links.html

On this page, you can get a little help on what kind of privilegies you must have on both database to get acess to DBMS_METADATA and dblink.

So a big thanks to this guy who helped a lot. 
