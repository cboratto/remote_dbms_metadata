

set feedback off
set define off

prompt Loading MONITOR_ADM.REMOTE_DDL_CONTROL...
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (1, 'ALTER_SNAP_INI', 1, 'Alteração do SNAPSHOT 1º Fase', 'EXEC DBMS_REFRESH.SUBTRACT(''@G_OWNER.@G_NAME'',''@OWNER.@TABLE'');', to_date('16-10-2014 10:46:09', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:09', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (2, 'ALTER_SNAP_FIM', 1, 'Alteração do SNAPSHOT 2º Fase', 'DROP SNAPSHOT @OWNER.@TABLE PRESERVE TABLE;', to_date('16-10-2014 10:46:09', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:09', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (3, 'ALTER_SNAP_FIM', 2, 'Alteração do SNAPSHOT 2º Fase', 'CREATE SNAPSHOT @OWNER.@TABLE ON PREBUILT TABLE REFRESH FAST AS SELECT * FROM @OWNER.@TABLE@@DBLINK;', to_date('16-10-2014 10:46:11', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:11', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (4, 'ALTER_SNAP_FIM', 3, 'Alteração do SNAPSHOT 2º Fase', 'EXEC DBMS_SNAPSHOT.REFRESH(''@OWNER.@TABLE'', ''C'', atomic_refresh=>false);', to_date('16-10-2014 10:46:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:16', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (5, 'ALTER_SNAP_FIM', 4, 'Alteração do SNAPSHOT 2º Fase', 'EXEC DBMS_REFRESH.ADD(NAME=>''@G_OWNER.@G_NAME'', LIST=>''@OWNER.@TABLE'', LAX=>TRUE); ', to_date('16-10-2014 10:46:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:16', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (6, 'ALTER_SNAP_FIM', 5, 'Alteração do SNAPSHOT 2º Fase', 'EXEC DBMS_SNAPSHOT.REFRESH(''@OWNER.@TABLE'', ''F'', atomic_refresh=>false);', to_date('16-10-2014 10:46:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:16', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (7, 'ALTER_SNAP_FIM', 6, 'Alteração do SNAPSHOT 2º Fase', 'COMMIT;', to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (8, 'CREATE_SNAP', 1, 'Criação do SNAPSHOT', 'CREATE SNAPSHOT @OWNER.@TABLE ON PREBUILT TABLE REFRESH FAST AS SELECT * FROM @OWNER.@TABLE@@DBLINK;', to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (9, 'CREATE_SNAP', 2, 'Criação do SNAPSHOT', 'EXEC DBMS_SNAPSHOT.REFRESH(''@OWNER.@TABLE'', ''C'', atomic_refresh=>false);', to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (10, 'CREATE_SNAP', 3, 'Criação do SNAPSHOT', 'EXEC DBMS_REFRESH.ADD(NAME=>''@G_OWNER.@G_NAME'', LIST=>''@OWNER.@TABLE'', LAX=>TRUE);', to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (11, 'CREATE_SNAP', 4, 'Criação do SNAPSHOT', 'EXEC DBMS_SNAPSHOT.REFRESH(''@OWNER.@TABLE'', ''F'', atomic_refresh=>false); ', to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:23', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (12, 'CREATE_SNAP', 5, 'Criação do SNAPSHOT', 'COMMIT;', to_date('16-10-2014 10:46:29', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:29', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (14, 'OWNER_GPG_CHECK', 1, 'Name the owner you would like to compare', 'OWNER_1', to_date('16-10-2014 10:46:29', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2015 14:06:23', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (22, 'EMAIL_TAG', 1, 'EMailTag', '[Monitor]', to_date('16-10-2014 10:46:42', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:42', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (23, 'EMAIL_SUBJECT', 1, 'Email Subject', 'DDL diff', to_date('16-10-2014 10:46:42', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:42', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (24, 'REFRESH_GROUP_DEFAULT', 1, 'Default refresh group for user OWNER_1 <Owner group>.<refresh group name>', 'OWNER_1.RFGRP_OWNER_1', to_date('16-10-2014 10:46:48', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2015 12:34:38', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (25, 'DAYS', 1, 'Number of days since last object last DDL', '30', to_date('16-10-2014 10:46:48', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:46:48', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (41, 'FAKE_MVIEW_GROUP_01', 1, '[EXEC ON THE SOURCE] First process group FAKE MVIEW', 'CREATE TABLE @OWNER.@TABLE_FAKE AS SELECT * FROM @OWNER.@TABLE WHERE 1 = 2;', to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (42, 'FAKE_MVIEW_GROUP_01', 2, '[EXEC ON THE SOURCE] Second process group FAKE MVIEW', 'CREATE MATERIALIZED VIEW @OWNER.@TABLE_FAKE ON PREBUILT TABLE REFRESH FAST AS SELECT * FROM @OWNER.@TABLE;', to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (43, 'FAKE_MVIEW_GROUP_02', 1, '[EXEC ON REMOTE] Second process group FAKE MVIEW', 'EXEC DBMS_SNAPSHOT.REFRESH(''@OWNER.@TABLE'',''F'');', to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (44, 'FAKE_MVIEW_GROUP_02', 2, '[EXEC ON REMOTE] Second process group FAKE MVIEW', 'EXEC DBMS_REFRESH.SUBTRACT(''@G_OWNER.@G_NAME'',''@OWNER.@TABLE'');', to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (45, 'FAKE_MVIEW_GROUP_03', 1, '[EXEC ON REMOTE] Third process group FAKE MVIEW', 'DROP SNAPSHOT @OWNER.@TABLE PRESERVE TABLE;', to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (46, 'FAKE_MVIEW_GROUP_03', 2, '[EXEC ON REMOTE] Third process group FAKE MVIEW', 'CREATE SNAPSHOT @OWNER.@TABLE ON PREBUILT TABLE REFRESH FAST AS SELECT * FROM @OWNER.@TABLE@@DBLINK;', to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:08', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (47, 'FAKE_MVIEW_GROUP_04', 1, '[EXEC ON THE SOURCE] Fourth process group FAKE MVIEW', 'UPDATE @OWNER.MLOG$_@TABLE SET SNAPTIME$$=TO_DATE(''01/01/4000'',''DD/MM/YYYY'') ;', to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (48, 'FAKE_MVIEW_GROUP_04', 2, '[EXEC ON THE SOURCE] Fourth process group FAKE MVIEW', 'COMMIT;', to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (49, 'FAKE_MVIEW_GROUP_05', 1, '[EXEC ON REMOTE] Fifth process group FAKE MVIEW', 'EXEC DBMS_REFRESH.ADD(NAME=>''@G_OWNER.@G_NAME'', LIST=>''@OWNER.@TABLE'', LAX=>TRUE);', to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (50, 'FAKE_MVIEW_GROUP_05', 2, '[EXEC ON REMOTE] Fifth process group FAKE MVIEW', 'EXEC DBMS_SNAPSHOT.REFRESH(''@OWNER.@TABLE'', ''F'', atomic_refresh=>false);', to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (51, 'FAKE_MVIEW_GROUP_06', 1, '[EXEC ON THE SOURCE] Sixth process group FAKE MVIEW', 'DROP SNAPSHOT @OWNER.@TABLE_FAKE ;', to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:14', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (52, 'FAKE_MVIEW_GROUP_06', 2, '[EXEC ON THE SOURCE] Sixth process group FAKE MVIEW', 'DROP TABLE @OWNER.@TABLE_FAKE purge;', to_date('16-10-2014 10:47:29', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:29', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (53, 'OBJECT_HEADER', 1, 'Header description. TAGS @OWNER, @TABLE se quiser', '/*******************************************************************************' || chr(10) || '            @OWNER.@TABLE' || chr(10) || '' || chr(10) || '*******************************************************************************/' || chr(10) || '', to_date('16-10-2014 10:47:29', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:29', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (74, 'OWNER_GPG_CHECK', 10, 'Compara o owner com o schema OKANE com PHO', 'SAFEPAY_CARD_ADM', to_date('18-02-2015 13:05:39', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2015 14:06:23', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (104, 'FAKE_MVIEW_NEED', 1, 'Table is consumed by more than one replication site', 'TABLE_1', to_date('19-06-2015 15:06:31', 'dd-mm-yyyy hh24:mi:ss'), to_date('19-06-2015 15:06:31', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (105, 'FAKE_MVIEW_NEED', 2, 'Table is consumed by more than one replication site', 'TABLE_2', to_date('19-06-2015 15:06:31', 'dd-mm-yyyy hh24:mi:ss'), to_date('19-06-2015 15:06:31', 'dd-mm-yyyy hh24:mi:ss'));


insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (55, 'OKANE_EMAIL_SUBJECT', 1, 'Email subject', 'remote_dbms_metadata DB (local) x DB (Source)', to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (56, 'OKANE_EMAIL_TAG', 1, 'Email Tag', '[OKANE TAG]', to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (57, 'OKANE_ORDER_BY', 1, 'Wich DDL should be first Create or Alter (C|A)', 'C', to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (58, 'ENABLE_COMMENT_COLUMN', 1, '(S) - Return comments; (N) - Disable Feature', 'S', to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'), to_date('16-10-2014 10:47:36', 'dd-mm-yyyy hh24:mi:ss'));


insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (79, 'OKANE_EXCLUSIVE_TABLE', 1, 'Tables should not be considered to be dropped', 'OWNER_1.TABLE_1', to_date('18-03-2015 17:42:58', 'dd-mm-yyyy hh24:mi:ss'), to_date('18-03-2015 17:42:58', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (80, 'OKANE_EXCLUSIVE_TABLE', 2, 'Tables should not be considered to be dropped', 'OWNER_1.TABLE_2', to_date('18-03-2015 17:42:58', 'dd-mm-yyyy hh24:mi:ss'), to_date('18-03-2015 17:42:58', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (92, 'MVIEW_DROP_SNAPSHOT', 2, 'Snapshot should bem dropped', 'EXEC DBMS_REFRESH.SUBTRACT(''@G_OWNER.@G_NAME'',''@OWNER.@TABLE'');', to_date('18-03-2015 18:38:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('18-03-2015 18:38:16', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (93, 'MVIEW_DROP_SNAPSHOT', 3, 'Snapshot should bem dropped ', 'DROP SNAPSHOT @OWNER.@TABLE PRESERVE TABLE;', to_date('18-03-2015 18:38:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('18-03-2015 18:38:16', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (94, 'DROP_STATEMENT', 1, 'Drop table', 'DROP TABLE @OWNER.@TABLE PURGE;', to_date('19-03-2015 17:54:40', 'dd-mm-yyyy hh24:mi:ss'), to_date('23-10-2015 11:01:52', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (95, 'MVIEW_DROP_SNAPSHOT', 1, 'Snapshot should bem dropped', '-- WARNING: Before execute, check if it should be done', to_date('18-03-2015 18:38:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('18-03-2015 18:38:16', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (96, 'OKANE_TABLE_MLOG', 1, 'MLOG na origemCreate MLOG on source', '--[EXEC ON SOURCE]', to_date('20-03-2015 14:36:20', 'dd-mm-yyyy hh24:mi:ss'), to_date('20-03-2015 14:36:20', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (97, 'OKANE_TABLE_MLOG', 2, 'MLOG na origemCreate MLOG on source', 'CREATE MATERIALIZED VIEW LOG ON @OWNER.@TABLE WITH PRIMARY KEY INCLUDING NEW VALUES;', to_date('20-03-2015 14:36:20', 'dd-mm-yyyy hh24:mi:ss'), to_date('20-03-2015 14:36:20', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (59, 'ENABLE_INDEX_DDL', 1, '(S) - Return CREATE/DROP Index; (N) - Disable feature', 'S', to_date('23-10-2014 10:08:58', 'dd-mm-yyyy hh24:mi:ss'), to_date('23-10-2014 10:08:58', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (65, 'IDX_PK', 1, 'Statement Create Index PK', 'ALTER TABLE @OWNER.@TABLE ADD CONSTRAINT @CONSTRAINT_NAME PRIMARY KEY (@COLUMN) using index tablespace @TBS;', to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'), to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (66, 'IDX_NONUNIQUE', 1, 'Statement Create Index NONUNIQUE', 'CREATE INDEX @OWNER.@CONSTRAINT_NAME ON @OWNER.@TABLE (@COLUMN) tablespace @TBS ONLINE;', to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'), to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (68, 'BLACKLIST_TABLE_TIME', 1, 'Object should be kept in the blacklist for (days)', '100', to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'), to_date('18-08-2016 11:37:13', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (69, 'OKANE_TABLE_USER_PRIV', 1, 'Privilege to object', 'GRANT SELECT ON @OWNER.@TABLE TO USER_1;', to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'), to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (70, 'OKANE_TABLE_USER_PRIV', 2, 'Privilege to object', 'GRANT SELECT ON @OWNER.@TABLE TO USER_2;', to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'), to_date('10-11-2014 16:04:21', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (72, 'IDX_UNIQUE', 1, 'Statement Create Index UNIQUE', 'CREATE INDEX @OWNER.@CONSTRAINT_NAME ON @OWNER.@TABLE (@COLUMN) tablespace @TBS ONLINE;', to_date('10-11-2014 16:04:40', 'dd-mm-yyyy hh24:mi:ss'), to_date('27-07-2016 15:04:51', 'dd-mm-yyyy hh24:mi:ss'));

insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (77, 'OKANE_TABLE_SYN', 2, 'Create Synonym for objeto.', 'CREATE PUBLIC SYNONYM @TABLE FOR @OWNER.@TABLE;', to_date('19-02-2015 11:24:16', 'dd-mm-yyyy hh24:mi:ss'), to_date('19-02-2015 11:24:16', 'dd-mm-yyyy hh24:mi:ss'));


insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (102, 'EMAIL_RECEIPT', 8, 'Email to where notification should be sent', 'youremail@provider.com', to_date('31-03-2015 14:02:55', 'dd-mm-yyyy hh24:mi:ss'), to_date('31-03-2015 14:02:55', 'dd-mm-yyyy hh24:mi:ss'));


insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (338, 'BLACKLIST_TABLE', 1, 'This table should not be considered for comparision <Owner>.<Table>', 'OWNER_1.TABLE_SHOULD_NOT_BE_COMPARED', to_date('06-10-2016 19:05:29', 'dd-mm-yyyy hh24:mi:ss'), to_date('06-10-2016 19:05:29', 'dd-mm-yyyy hh24:mi:ss'));
insert into MONITOR_ADM.REMOTE_DDL_CONTROL (idt_remote_ddl_control, cod_remote_ddl_control, num_ordem, des_remote_ddl_control, des_statement, dat_creation, dat_update)
values (338, 'BLACKLIST_TABLE', 2, 'This table should not be considered for comparision <Owner>.<Table>', 'OWNER_1.TABLE_SHOULD_NOT_BE_COMPARED_2', to_date('06-10-2016 19:05:29', 'dd-mm-yyyy hh24:mi:ss'), to_date('06-10-2016 19:05:29', 'dd-mm-yyyy hh24:mi:ss'));

commit;
