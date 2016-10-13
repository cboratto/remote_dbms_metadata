# remote_dbms_metadata

## What is it?
Routine to compare DDL structure differences between two databases. The DDL differences could be sent by email.

## Use case
I used this to automate DDL generation of two distinct databases. These two, or more, databases communicate between Oracle Matarialized View architecture. Those DDLs needed to be analyzed prior applying it due to peculiar needs.

## Features 
DDL generation
DDL materialized view
DDL customized for cases when more then one remote site is consuming the same source (FAKE_MVIEW_NEED)
Compare only objects altered in the past X days (DAYS).
List of emails to be notified (EMAIL_RECEIPT).
Capture table comments (ENABLE_COMMENT_COLUMN)
Index DDL generation (ENABLE_INDEX_DDL)
Check schemas that should be compared (OWNER_GPG_CHECK).
Blacklist for tables (API - add_Table_to_Blacklist)
Blacklist for table columns (BLACKLIST_COLUMN)
Control blacklist time (BLACKLIST_TABLE_TIME)

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
