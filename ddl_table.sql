-- Create table
create table MONITOR_ADM.REMOTE_DDL_CONTROL
(
  idt_remote_ddl_control NUMBER(10) not null,
  cod_remote_ddl_control VARCHAR2(32) not null,
  num_ordem              NUMBER(5),
  des_remote_ddl_control VARCHAR2(256) not null,
  des_statement          VARCHAR2(3000) not null,
  dat_creation           DATE default SYSDATE not null,
  dat_update             DATE default SYSDATE not null
)
tablespace TSDMONITOR01
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 1M
    next 1M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
-- Create/Recreate indexes 
create unique index MONITOR_ADM.REMODDLCONTR_UK01 on MONITOR_ADM.REMOTE_DDL_CONTROL (COD_REMOTE_DDL_CONTROL, NUM_ORDEM)
  tablespace TSIMONITOR01
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 1M
    next 1M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table MONITOR_ADM.REMOTE_DDL_CONTROL
  add constraint REMODDLCONTR_PK primary key (IDT_REMOTE_DDL_CONTROL)
  using index 
  tablespace TSIMONITOR01
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 1M
    next 1M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
alter table MONITOR_ADM.REMOTE_DDL_CONTROL
  add constraint REMODDLCONT_UK01 unique (COD_REMOTE_DDL_CONTROL, DES_STATEMENT)
  using index 
  tablespace TSIMONITOR01
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 1M
    next 1M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

  
-- Create table
create table MONITOR_ADM.REMOTE_DDL_CONTROL_LOG
(
  idt_remote_log NUMBER(10),
  message        VARCHAR2(1024),
  status         VARCHAR2(3),
  dat_creation   DATE default SYSDATE
)
tablespace TSDMONITOR01
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 1M
    next 1M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );