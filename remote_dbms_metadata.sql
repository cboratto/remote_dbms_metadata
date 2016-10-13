CREATE OR REPLACE PACKAGE MONITOR_ADM.remote_dbms_metadata AS

  /*************************************************************************
 * Program  : remote_dbms_metadata
 * Version  : 1.0
 * Author   : Philip Moore
 * Date     : 20-JUN-2009 Anno Domini
 * Purpopse : This package provides access to DDL for objects in a remote
              Oracle database via Database Links.
 * Warnings : This package has only been tested in Oracle 9iR2 and 10gR2.
 
	* Date     : 31-aug-2015
	* Author   : Caio Boratto
	* Purpopse : Compare Oracle Table/Index Dictionary for replication throught
			   Oracle snapshots/materializedViews
				 If you deploy in your system replications and those table 
						 are high DDL oriented, this automation build DDL commands 
						 and notifies you what commands you must apply on the slaves
	* Warnings : This package has been tested in Oracle 11gR2.
 
  *************************************************************************/

  -- email
  conn        utl_smtp.connection;
  smtp_addr   VARCHAR2(200) := 'smtpserverAddress.host.intranet';
  domain_name VARCHAR2(64) := 'yourdomain.com';
  file_buffer VARCHAR2(4000) := '';
	
  -- Types
  TYPE session_transform_param_rec IS RECORD(
    parameter_name VARCHAR2(50),
    value_datatype PLS_INTEGER,
    varchar2_value VARCHAR2(50),
    boolean_value  BOOLEAN,
    number_value   NUMBER);

  TYPE session_transform_params_type IS TABLE OF session_transform_param_rec INDEX BY VARCHAR2(50);
  TYPE db_link_session_transform_type IS TABLE OF session_transform_params_type INDEX BY all_db_links.db_link%TYPE;

  -- Global Constants
  c_varchar2_type CONSTANT PLS_INTEGER := 1;
  c_boolean_type  CONSTANT PLS_INTEGER := 2;
  c_number_type   CONSTANT PLS_INTEGER := 3;

  -- Global Variables
  g_session_transform_params db_link_session_transform_type;

  -- Custom Exceptions
  handle_not_open EXCEPTION;
  PRAGMA EXCEPTION_INIT(handle_not_open, -31600);

  -- Procedures and Functions
  FUNCTION OPEN(db_link     IN VARCHAR2 DEFAULT NULL,
                object_type IN VARCHAR2,
                version     IN VARCHAR2 DEFAULT 'COMPATIBLE',
                model       IN VARCHAR2 DEFAULT 'ORACLE') RETURN NUMBER;

  PROCEDURE dbms_metadata_close(db_link IN VARCHAR2 DEFAULT NULL,
                                handle  IN NUMBER);

  PROCEDURE set_count(db_link IN VARCHAR2 DEFAULT NULL,
                      handle  IN NUMBER,
                      VALUE   IN NUMBER);

  PROCEDURE set_filter(db_link IN VARCHAR2 DEFAULT NULL,
                       handle  IN NUMBER,
                       NAME    IN VARCHAR2,
                       VALUE   IN VARCHAR2);

  PROCEDURE set_filter(db_link IN VARCHAR2 DEFAULT NULL,
                       handle  IN NUMBER,
                       NAME    IN VARCHAR2,
                       VALUE   IN BOOLEAN);

  FUNCTION add_transform(db_link  IN VARCHAR2 DEFAULT NULL,
                         handle   IN NUMBER,
                         NAME     IN VARCHAR2,
                         encoding IN VARCHAR2 DEFAULT NULL) RETURN NUMBER;

  PROCEDURE set_transform_param(db_link          IN VARCHAR2 DEFAULT NULL,
                                transform_handle IN NUMBER,
                                NAME             IN VARCHAR2,
                                VALUE            IN VARCHAR2);

  PROCEDURE set_transform_param(db_link          IN VARCHAR2 DEFAULT NULL,
                                transform_handle IN NUMBER,
                                NAME             IN VARCHAR2,
                                VALUE            IN BOOLEAN DEFAULT TRUE);

  FUNCTION fetch_ddl_text(db_link IN VARCHAR2 DEFAULT NULL,
                          handle  IN NUMBER,
                          partial OUT NUMBER) RETURN VARCHAR2;

  FUNCTION fetch_clob(db_link IN VARCHAR2 DEFAULT NULL,
                      handle  IN NUMBER) RETURN CLOB;

  FUNCTION fetch_ddl_clob(db_link IN VARCHAR2 DEFAULT NULL,
                          handle  IN NUMBER) RETURN CLOB;

  FUNCTION fetch_ddl(db_link IN VARCHAR2 DEFAULT NULL,
                     handle  IN NUMBER) RETURN ku$_ddls;

  PROCEDURE set_default_table_transforms(db_link                IN VARCHAR2 DEFAULT NULL,
                                         table_transform_handle IN NUMBER);

  PROCEDURE set_default_index_transforms(db_link                IN VARCHAR2 DEFAULT NULL,
                                         index_transform_handle IN NUMBER);

  FUNCTION convert_long_var(index_name      IN VARCHAR2,
                            column_position IN NUMBER,
                            dblink          IN VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2;

  FUNCTION get_ddl(db_link     IN VARCHAR2 DEFAULT NULL,
                   object_type IN VARCHAR2,
                   NAME        IN VARCHAR2,
                   SCHEMA      IN VARCHAR2 DEFAULT NULL,
                   version     IN VARCHAR2 DEFAULT 'COMPATIBLE',
                   model       IN VARCHAR2 DEFAULT 'ORACLE',
                   transform   IN VARCHAR2 DEFAULT 'DDL') RETURN CLOB;

  PROCEDURE p_InsertParameter(pcParameterName IN VARCHAR2,
                              pcValue         IN VARCHAR2,
                              pcDescription   IN VARCHAR2 DEFAULT NULL);
  PROCEDURE addParameter(pcParameterName IN VARCHAR2,
                         pcValue         IN VARCHAR2,
                         pbIsUnique      IN BOOLEAN DEFAULT TRUE,
                         pcDescription   IN VARCHAR2 DEFAULT NULL);

  PROCEDURE add_Table_to_Blacklist(pcOwner IN VARCHAR2,
                                   pcTable IN VARCHAR2);

  FUNCTION isTableInBlackList(pcOwner IN VARCHAR2,
                              pcTable IN VARCHAR2) RETURN NUMBER;
  FUNCTION isTableOkaneExclusive(pcOwner IN VARCHAR2,
                                 pcTable IN VARCHAR2) RETURN NUMBER;

  FUNCTION get_dependent_ddl(db_link            IN VARCHAR2 DEFAULT NULL,
                             object_type        IN VARCHAR2,
                             base_object_name   IN VARCHAR2,
                             base_object_schema IN VARCHAR2 DEFAULT NULL,
                             version            IN VARCHAR2 DEFAULT 'COMPATIBLE',
                             model              IN VARCHAR2 DEFAULT 'ORACLE',
                             transform          IN VARCHAR2 DEFAULT 'DDL',
                             object_count       IN NUMBER DEFAULT 10000)
    RETURN CLOB;

  
  PROCEDURE send_ddl_by_email(dblink IN VARCHAR2);

END remote_dbms_metadata;
/
CREATE OR REPLACE PACKAGE BODY MONITOR_ADM.remote_dbms_metadata AS
  /*************************************************************************
 * Program  : remote_dbms_metadata
 * Version  : 1.0
 * Author   : Philip Moore
 * Date     : 20-JUN-2009 Anno Domini
 * Purpopse : This package provides access to DDL for objects in a remote
              Oracle database via Database Links.
 * Warnings : This package has only been tested in Oracle 9iR2 and 10gR2.
 
  * Date     : 31-aug-2015
  * Author   : Caio Boratto
  * Purpopse : Compare Oracle Table/Index Dictionary for replication throught
             Oracle snapshots/materializedViews
             If you deploy in your system replications and those table 
             are high DDL oriented, this automation build DDL commands 
             and notifies you what commands you must apply on the slaves
 * Warnings : This package has been tested in Oracle 11gR2.
 
  *************************************************************************/
  gcObjectType               CONSTANT VARCHAR2(10) := 'TABLE';
  gcGalapagosSource          CONSTANT VARCHAR2(9) := 'GALAPAGOS';
  gcOkaneSource              CONSTANT VARCHAR2(5) := 'OKANE';
  gcBlackListParameter       CONSTANT VARCHAR2(15) := 'BLACKLIST_TABLE';
  gcColumnBlackListParameter CONSTANT VARCHAR2(20) := 'BLACKLIST_COLUMN';
  gcOkaneExclusiveTable      CONSTANT VARCHAR2(21) := 'OKANE_EXCLUSIVE_TABLE';

  TYPE rec_OwnerTranslation IS RECORD(
    pho_Owner VARCHAR2(30),
    pho_Table VARCHAR2(30),
    gpg_Owner VARCHAR2(30),
    gpg_Table VARCHAR2(30));

  TYPE t_OwnerTranslation IS TABLE OF rec_OwnerTranslation;
  gt_Translation t_OwnerTranslation;

  TYPE rec_Object IS RECORD(
    owner          VARCHAR2(32),
    table_name     VARCHAR2(30),
    ind_alter_type VARCHAR2(1));
  vt_object rec_object;

  -- Array dos objetos remotos
  TYPE gRemoteRec IS TABLE OF vt_object%TYPE;

  TYPE rec_tabColumn IS RECORD(
    column_name    VARCHAR2(30),
    data_type      VARCHAR2(106),
    data_length    NUMBER,
    data_precision NUMBER,
    data_scale     NUMBER);

  TYPE gt_tabColumn IS TABLE OF rec_tabColumn;

  -- SubProcedures
  /* ------------------------------------- */

  FUNCTION build_db_link_string(p_db_link IN VARCHAR2) RETURN VARCHAR2 IS
    -- Variables
    l_return VARCHAR2(100);
  BEGIN
    IF p_db_link IS NOT NULL THEN
      l_return := '@' || LTRIM(p_db_link, '@');
    END IF;
  
    RETURN l_return;
  END build_db_link_string;

  /* ------------------------------------- */
  FUNCTION OPEN(db_link     IN VARCHAR2 DEFAULT NULL,
                object_type IN VARCHAR2,
                version     IN VARCHAR2 DEFAULT 'COMPATIBLE',
                model       IN VARCHAR2 DEFAULT 'ORACLE') RETURN NUMBER IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_return     NUMBER;
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
  BEGIN
    l_plsql_call := 'BEGIN ' || '     :l_return := DBMS_METADATA.OPEN' ||
                    l_db_link || ' (object_type => :object_type ' ||
                    ', version     => :version ' ||
                    ', model       => :model ' || ' ); ' || 'END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING OUT l_return, IN object_type, IN version, IN model;
  
    RETURN l_return;
  END OPEN;

  /* ------------------------------------- */
  PROCEDURE dbms_metadata_close(db_link IN VARCHAR2 DEFAULT NULL,
                                handle  IN NUMBER) IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
  BEGIN
    l_plsql_call := 'BEGIN DBMS_METADATA.CLOSE' || l_db_link ||
                    ' (handle => :handle); END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING IN handle;
  END dbms_metadata_close;

  /* ------------------------------------- */
  PROCEDURE set_count(db_link IN VARCHAR2 DEFAULT NULL,
                      handle  IN NUMBER,
                      VALUE   IN NUMBER) IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
  BEGIN
    l_plsql_call := 'BEGIN DBMS_METADATA.SET_COUNT' || l_db_link ||
                    ' (handle => :handle, value  => :value); END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING IN handle, IN VALUE;
  END set_count;

  /* ------------------------------------- */
  PROCEDURE set_filter(db_link IN VARCHAR2 DEFAULT NULL,
                       handle  IN NUMBER,
                       NAME    IN VARCHAR2,
                       VALUE   IN VARCHAR2) IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
  BEGIN
    l_plsql_call := 'BEGIN ' || '     DBMS_METADATA.SET_FILTER' ||
                    l_db_link || ' (handle => :handle ' ||
                    ', name   => :name ' || ', value  => :value ' || '); ' ||
                    'END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING IN handle, IN NAME, IN VALUE;
  END set_filter;

  /* ------------------------------------- */
  PROCEDURE set_filter(db_link IN VARCHAR2 DEFAULT NULL,
                       handle  IN NUMBER,
                       NAME    IN VARCHAR2,
                       VALUE   IN BOOLEAN) IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
  BEGIN
    l_plsql_call := 'BEGIN ' || '     DBMS_METADATA.SET_FILTER' ||
                    l_db_link || ' (handle => :handle ' ||
                    ', name   => :name ' || ', value  => ' ||
                    boolean_pkg.bool_to_str(boolean_in => VALUE) || '); ' ||
                    'END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING IN handle, IN NAME;
  END set_filter;

  /* ------------------------------------- */
  FUNCTION add_transform(db_link  IN VARCHAR2 DEFAULT NULL,
                         handle   IN NUMBER,
                         NAME     IN VARCHAR2,
                         encoding IN VARCHAR2 DEFAULT NULL) RETURN NUMBER IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_return     NUMBER;
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
  BEGIN
    l_plsql_call := 'BEGIN ' ||
                    '   :l_return := DBMS_METADATA.ADD_TRANSFORM' ||
                    l_db_link || ' (handle => :handle ' ||
                    ', name   => :name ' || ', encoding => :encoding ' ||
                    '); ' || 'END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING OUT l_return, IN handle, IN NAME, IN encoding;
  
    RETURN l_return;
  END add_transform;

  /* ------------------------------------- */
  PROCEDURE set_transform_param(db_link          IN VARCHAR2 DEFAULT NULL,
                                transform_handle IN NUMBER,
                                NAME             IN VARCHAR2,
                                VALUE            IN VARCHAR2) IS
    -- Variables
    l_plsql_call                  VARCHAR2(4000);
    l_db_link                     VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
    l_session_transform_param_rec session_transform_param_rec;
  BEGIN
    IF transform_handle = DBMS_METADATA.session_transform THEN
      /* Since we don't hold a session open for a remote database - we have to
      store the session transformation parameters in a local global structure */
      l_session_transform_param_rec.parameter_name := UPPER(TRIM(NAME));
      l_session_transform_param_rec.value_datatype := c_varchar2_type;
      l_session_transform_param_rec.varchar2_value := VALUE;
      g_session_transform_params(db_link)(l_session_transform_param_rec.parameter_name) := l_session_transform_param_rec;
    ELSE
      l_plsql_call := 'BEGIN ' || '   DBMS_METADATA.SET_TRANSFORM_PARAM' ||
                      l_db_link ||
                      ' (transform_handle => :transform_handle ' ||
                      ', name             => :name ' ||
                      ', value            => :value ' || '); ' || 'END;';
    
      EXECUTE IMMEDIATE l_plsql_call
        USING IN transform_handle, IN NAME, IN VALUE;
    END IF;
  END set_transform_param;

  /* ------------------------------------- */
  PROCEDURE set_transform_param(db_link          IN VARCHAR2 DEFAULT NULL,
                                transform_handle IN NUMBER,
                                NAME             IN VARCHAR2,
                                VALUE            IN BOOLEAN DEFAULT TRUE) IS
    -- Variables
    l_plsql_call                  VARCHAR2(4000);
    l_db_link                     VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
    l_session_transform_param_rec session_transform_param_rec;
  BEGIN
    IF transform_handle = DBMS_METADATA.session_transform THEN
      /* Since we don't hold a session open for a remote database - we have to
      store the session transformation parameters in a local global structure */
      l_session_transform_param_rec.parameter_name := UPPER(TRIM(NAME));
      l_session_transform_param_rec.value_datatype := c_boolean_type;
      l_session_transform_param_rec.boolean_value := VALUE;
      g_session_transform_params(db_link)(l_session_transform_param_rec.parameter_name) := l_session_transform_param_rec;
    ELSE
      l_plsql_call := 'BEGIN ' || '   DBMS_METADATA.SET_TRANSFORM_PARAM' ||
                      l_db_link ||
                      ' (transform_handle => :transform_handle ' ||
                      ', name             => :name ' ||
                      ', value            => ' ||
                      boolean_pkg.bool_to_str(boolean_in => VALUE) || '); ' ||
                      'END;';
    
      EXECUTE IMMEDIATE l_plsql_call
        USING IN transform_handle, IN NAME;
    END IF;
  END set_transform_param;

  /* ------------------------------------- */
  PROCEDURE set_transform_param(db_link          IN VARCHAR2 DEFAULT NULL,
                                transform_handle IN NUMBER,
                                NAME             IN VARCHAR2,
                                VALUE            IN NUMBER) IS
    -- Variables
    l_plsql_call                  VARCHAR2(4000);
    l_db_link                     VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
    l_session_transform_param_rec session_transform_param_rec;
  BEGIN
    IF transform_handle = DBMS_METADATA.session_transform THEN
      /* Since we don't hold a session open for a remote database - we have to
      store the session transformation parameters in a local global structure */
      l_session_transform_param_rec.parameter_name := UPPER(TRIM(NAME));
      l_session_transform_param_rec.value_datatype := c_number_type;
      l_session_transform_param_rec.number_value := VALUE;
      g_session_transform_params(db_link)(l_session_transform_param_rec.parameter_name) := l_session_transform_param_rec;
    ELSE
      l_plsql_call := 'BEGIN ' || '   DBMS_METADATA.SET_TRANSFORM_PARAM' ||
                      l_db_link ||
                      ' (transform_handle => :transform_handle ' ||
                      ', name             => :name ' ||
                      ', value            => :value ' || '); ' || 'END;';
    
      EXECUTE IMMEDIATE l_plsql_call
        USING IN transform_handle, IN NAME, IN VALUE;
    END IF;
  END set_transform_param;

  /* ------------------------------------- */
  FUNCTION fetch_ddl_text(db_link IN VARCHAR2 DEFAULT NULL,
                          handle  IN NUMBER,
                          partial OUT NUMBER) RETURN VARCHAR2 IS
    -- Variables
    l_plsql_call VARCHAR2(4000);
    l_db_link    VARCHAR2(100) := build_db_link_string(p_db_link => db_link);
    l_return     VARCHAR2(32767);
  BEGIN
    l_plsql_call := 'BEGIN :l_return := DBMS_METADATA.fetch_ddl_text' ||
                    l_db_link ||
                    ' (handle => :handle, partial => :partial); END;';
  
    EXECUTE IMMEDIATE l_plsql_call
      USING OUT l_return, IN handle, OUT partial;
  
    RETURN l_return;
  END fetch_ddl_text;

  /* ------------------------------------- */
  FUNCTION fetch_clob(db_link IN VARCHAR2 DEFAULT NULL,
                      handle  IN NUMBER) RETURN CLOB IS
    -- Variables
    l_partial PLS_INTEGER;
    l_return  CLOB;
  BEGIN
    -- Loop until the partial flag is 0
    LOOP
      l_return := l_return ||
                  fetch_ddl_text(db_link => db_link,
                                 handle  => handle,
                                 partial => l_partial);
      EXIT WHEN l_partial = 0;
    END LOOP;
  
    RETURN l_return;
  END fetch_clob;

  /* ------------------------------------- */
  FUNCTION fetch_ddl_clob(db_link IN VARCHAR2 DEFAULT NULL,
                          handle  IN NUMBER) RETURN CLOB IS
    -- Variables
    l_return CLOB;
  BEGIN
  
    -- Keep fetching until we get an error...
    <<fetch_loop>>
    LOOP
      BEGIN
        l_return := l_return ||
                    fetch_clob(db_link => db_link, handle => handle);
      EXCEPTION
        WHEN DBMS_METADATA.invalid_argval THEN
          EXIT fetch_loop;
      END;
    END LOOP fetch_loop;
  
    RETURN l_return;
  END fetch_ddl_clob;

  /* ------------------------------------- */
  FUNCTION fetch_ddl(db_link IN VARCHAR2 DEFAULT NULL,
                     handle  IN NUMBER) RETURN ku$_ddls IS
    -- Variables
    l_temp_clob CLOB;
    l_return    ku$_ddls := ku$_ddls();
  BEGIN
  
    -- Keep fetching until we get an error...
    <<fetch_loop>>
    LOOP
      BEGIN
        l_temp_clob := fetch_clob(db_link => db_link, handle => handle);
        l_return.EXTEND;
        l_return(l_return.COUNT).ddltext := l_temp_clob;
      EXCEPTION
        WHEN DBMS_METADATA.invalid_argval THEN
          EXIT fetch_loop;
      END;
    END LOOP fetch_loop;
  
    RETURN l_return;
  END fetch_ddl;

  /* ------------------------------------- */
  PROCEDURE set_default_table_transforms(db_link                IN VARCHAR2 DEFAULT NULL,
                                         table_transform_handle IN NUMBER) IS
  BEGIN
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'PRETTY',
                        VALUE            => TRUE);
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'SQLTERMINATOR',
                        VALUE            => TRUE);
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'SIZE_BYTE_KEYWORD',
                        VALUE            => FALSE);
    /*    set_transform_param(db_link          => db_link,
    transform_handle => table_transform_handle,
    NAME             => 'SEGMENT_ATTRIBUTES',
    VALUE            => FALSE);*/
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'STORAGE',
                        VALUE            => FALSE);
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'TABLESPACE',
                        VALUE            => TRUE);
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'CONSTRAINTS',
                        VALUE            => FALSE);
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'REF_CONSTRAINTS',
                        VALUE            => FALSE);
    set_transform_param(db_link          => db_link,
                        transform_handle => table_transform_handle,
                        NAME             => 'PCTSPACE',
                        VALUE            => 0);
  
  END set_default_table_transforms;

  /* ------------------------------------- */
  PROCEDURE set_default_index_transforms(db_link                IN VARCHAR2 DEFAULT NULL,
                                         index_transform_handle IN NUMBER) IS
  BEGIN
    set_transform_param(db_link          => db_link,
                        transform_handle => index_transform_handle,
                        NAME             => 'PRETTY',
                        VALUE            => TRUE);
    set_transform_param(db_link          => db_link,
                        transform_handle => index_transform_handle,
                        NAME             => 'SQLTERMINATOR',
                        VALUE            => TRUE);
  END set_default_index_transforms;

  /* ------------------------------------- */
  PROCEDURE apply_session_transform_params(db_link          IN VARCHAR2,
                                           transform_handle IN NUMBER) IS
    -- Variables
    l_array_index VARCHAR2(50);
  BEGIN
    IF db_link IS NOT NULL THEN
      -- Apply any global session trasformation parameters which have been set prior to this call...
      l_array_index := g_session_transform_params(db_link).FIRST;
    
      WHILE l_array_index IS NOT NULL
      LOOP
        CASE
         g_session_transform_params(db_link)(l_array_index).value_datatype
          WHEN c_varchar2_type THEN
            set_transform_param(db_link          => db_link,
                                transform_handle => transform_handle,
                                NAME             => g_session_transform_params(db_link)(l_array_index)
                                                   .parameter_name,
                                VALUE            => g_session_transform_params(db_link)(l_array_index)
                                                   .varchar2_value);
          WHEN c_boolean_type THEN
            set_transform_param(db_link          => db_link,
                                transform_handle => transform_handle,
                                NAME             => g_session_transform_params(db_link)(l_array_index)
                                                   .parameter_name,
                                VALUE            => g_session_transform_params(db_link)(l_array_index)
                                                   .boolean_value);
          WHEN c_number_type THEN
            set_transform_param(db_link          => db_link,
                                transform_handle => transform_handle,
                                NAME             => g_session_transform_params(db_link)(l_array_index)
                                                   .parameter_name,
                                VALUE            => g_session_transform_params(db_link)(l_array_index)
                                                   .number_value);
        END CASE;
      
        l_array_index := g_session_transform_params(db_link)
                         .NEXT(l_array_index);
      END LOOP;
    END IF;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END apply_session_transform_params;

  FUNCTION convert_long_var(index_name      IN VARCHAR2,
                            column_position IN NUMBER,
                            dblink          IN VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2 AS
    l_cursor INTEGER DEFAULT dbms_sql.open_cursor;
  
    l_n        NUMBER;
    l_long_val VARCHAR2(4000);
    l_long_len NUMBER;
    l_buflen   NUMBER := 4000;
    l_curpos   NUMBER := 0;
  
    vcdblink VARCHAR2(32);
  BEGIN
    IF dblink IS NOT NULL THEN
      vcdblink := '@' || dblink;
    ELSE
      vcdblink := NULL;
    END IF;
  
    dbms_sql.parse(l_cursor,
                   'select column_expression from Dba_Ind_Expressions' ||
                   vcdblink || '
                  where index_name = :x
                  and   column_position = :y',
                   dbms_sql.native);
    dbms_sql.bind_variable(l_cursor, ':x', index_name);
    dbms_sql.bind_variable(l_cursor, ':y', column_position);
  
    dbms_sql.define_column_long(l_cursor, 1);
    l_n := dbms_sql.execute(l_cursor);
  
    IF (dbms_sql.fetch_rows(l_cursor) > 0) THEN
      dbms_sql.column_value_long(l_cursor,
                                 1,
                                 l_buflen,
                                 l_curpos,
                                 l_long_val,
                                 l_long_len);
    END IF;
    dbms_sql.close_cursor(l_cursor);
    RETURN l_long_val;
  
  END convert_long_var;
	
  PROCEDURE open_connection
  AS
  BEGIN
    conn := utl_smtp.open_connection(smtp_addr);
    utl_smtp.helo(conn, domain_name);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      '3 Failed to send mail due to the following rror: ' || SQLERRM);
  END;
	
  PROCEDURE mail_from(email_from VARCHAR2)
  AS
  BEGIN
    utl_smtp.mail(conn, email_from);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      'Failed to send mail FROM WWRONG due to the following error: ' || SQLERRM);
  END;

  PROCEDURE rcpt_to(email_to VARCHAR2)
  AS
  BEGIN
    utl_smtp.rcpt(conn, email_to);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      'Failed to send mail TO: WRONG due to the following error: ' || SQLERRM);
  END;
	
  PROCEDURE open_data
  AS
  BEGIN
    utl_smtp.open_data(conn);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      'Failed to send mail du to the following error: ' || SQLERRM);
  END;
	
  PROCEDURE send_header(
    name IN VARCHAR2,
    header IN VARCHAR2)
  AS
  BEGIN
    utl_smtp.write_data(conn, name || ': ' || header || utl_tcp.CRLF);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      'Faled to send mail due to the following error: ' || SQLERRM);
  END;
	
  PROCEDURE write_data(
    msg_text   VARCHAR2)
  AS
  BEGIN
    if (substr(msg_text,1,1) = '.') then
      utl_smtp.write_data(conn, utl_tcp.CRLF || '.' || msg_text);
    else
       utl_smtp.write_data(conn, utl_tcp.CRLF || msg_text);
    end if;
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      'Failed to send mail due to the followng error: ' || SQLERRM);
  END;
	
  PROCEDURE close_mail
  AS
  BEGIN
    utl_smtp.close_data(conn);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      'Failed to send mail due to te following error: ' || SQLERRM);
  END;
	
  PROCEDURE close_connection
  AS
  BEGIN
    utl_smtp.quit(conn);
  EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
      utl_smtp.quit(conn);
      RAISE_APPLICATION_ERROR(-20000,
      '1 Failed to send mail due to the following error: ' || SQLERRM);
  END;
	
  /*--+-------------------------------------------------+--
  |   Objetivo: Retorna duplo whitespace
  |--+-------------------------------------------------+-- */
  FUNCTION get_whitespace RETURN VARCHAR2 IS
  BEGIN
    RETURN CHR(10) || CHR(10);
  END get_whitespace;

  /*--+-------------------------------------------------+--
  |   Objetivo: Procedure de logs
  |--+-------------------------------------------------+-- */
  PROCEDURE log(vcMsg    IN VARCHAR2,
                pcStatus IN VARCHAR2 DEFAULT 'OK') IS
  
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO monitor_adm.remote_ddl_control_log
      (idt_remote_log,
       message,
       status,
       dat_creation)
    VALUES
      (monitor_adm.sq_remoddlcontlog_idt.nextval,
       vcMsg,
       pcStatus,
       SYSDATE);
  
    COMMIT;
  END;
  /*--+-------------------------------------------------+--
  |   Objetivo: Procedure de purge dos logs
  |--+-------------------------------------------------+-- */
  PROCEDURE purge_log IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    DELETE FROM monitor_adm.remote_ddl_control_log l
    WHERE  SYSDATE - l.dat_creation > 30;
  
    COMMIT;
  END purge_log;

  /*--+-------------------------------------------------+--
  |   Objetivo: Obter parametros de configuracão
  |--+-------------------------------------------------+-- */
  FUNCTION get_ControlParameter(pcparameterName IN VARCHAR2) RETURN VARCHAR2 IS
  
    vcParameter monitor_adm.remote_ddl_control.des_statement%TYPE;
  BEGIN
    SELECT c.des_statement
    INTO   vcParameter
    FROM   monitor_adm.remote_ddl_control c
    WHERE  c.cod_remote_ddl_control = pcparameterName;
  
    RETURN vcParameter;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(-20001,
                              'Parametro [' || pcparameterName ||
                              '] não esta configurado na base');
    WHEN TOO_MANY_ROWS THEN
      raise_application_error(-20002,
                              'Parametro [' || pcparameterName ||
                              '] esta duplicado ou deve ser acessado por cursor');
  END get_ControlParameter;

  /*--+-------------------------------------------------+--
  |   Objetivo: Obtem lista parametrizada
  |--+-------------------------------------------------+-- */
  FUNCTION get_ControlParameterList(pcParameterName IN VARCHAR2,
                                    pcSQL           IN CLOB) RETURN CLOB IS
  
    ref_cursor   SYS_REFCURSOR;
    vc_finalClob CLOB;
  BEGIN
    DECLARE
      vc_rec VARCHAR2(3000);
    BEGIN
      OPEN ref_cursor FOR pcSQL;
      LOOP
        FETCH ref_cursor
          INTO vc_rec;
        EXIT WHEN ref_cursor%NOTFOUND;
        vc_finalClob := vc_finalClob || get_whitespace || vc_rec;
      END LOOP;
    END;
    IF vc_finalClob IS NULL THEN
      raise_application_error(-20001,
                              'Parametro [' || pcparameterName ||
                              '] não retornou registros durante consulta. Validar sua configuracÃ£o');
    END IF;
  
    CLOSE ref_cursor;
    RETURN vc_finalClob;
  EXCEPTION
    WHEN OTHERS THEN
      log('Erro generico durante obtencão de parametro [' ||
          pcparameterName || ']',
          'NOK');
      RAISE;
  END get_ControlParameterList;

  /*--+-------------------------------------------------+--
  |   Objetivo: Envia email
  |--+-------------------------------------------------+-- */
  PROCEDURE send_email(pcMsg     IN CLOB,
                       pcSourcer IN VARCHAR2) IS
  
    TYPE temail IS TABLE OF VARCHAR2(60);
    emailArray temail;
  
    vcEmailTagDefault monitor_adm.remote_ddl_control.des_statement%TYPE;
    vcEmailSubject    monitor_adm.remote_ddl_control.des_statement%TYPE;
    vc_hostname       varchar2(128);
  BEGIN
    IF pcSourcer = gcGalapagosSource THEN
      vcEmailTagDefault := get_ControlParameter('EMAIL_TAG');
      vcEmailSubject    := get_ControlParameter('EMAIL_SUBJECT');
    ELSIF pcSourcer = gcOkaneSource THEN
      vcEmailTagDefault := get_ControlParameter('OKANE_EMAIL_TAG');
      vcEmailSubject    := get_ControlParameter('OKANE_EMAIL_SUBJECT');
    ELSE
      raise_application_error(-20005, 'Source não foi definido');
    END IF;
  
    SELECT c.des_statement BULK COLLECT
    INTO   emailArray
    FROM   monitor_adm.remote_ddl_control c
    WHERE  c.cod_remote_ddl_control = 'EMAIL_RECEIPT';
  
    IF emailarray.count = 0 THEN
      raise_application_error(-20003, '[EMAIL_RECEIPT] não configurado.');
    END IF;
  
    open_connection;
    mail_from(ora_database_name);
  
    FOR i IN 1 .. emailarray.count
    LOOP
      rcpt_to(emailarray(i));
    END LOOP;
    open_data;
    send_header('From', ora_database_name);
    send_header('To', emailarray(1));
  
    begin
      SELECT '[' || i.host_name || '] [' || i.instance_name || ']'
      INTO   vc_hostname
      FROM   v$instance i;
    exception
      when NO_DATA_FOUND then
        vc_hostname := '[null]';
    end;
    send_header('Subject',
                          vc_hostname || vcEmailTagDefault ||
                          vcEmailSubject);
  
    -- check if the clob is not bigger then 31998 bytes (max mail API length per call).
    -- in case, break it into more than one call
    DECLARE
      breakMsgInto NUMBER;
      n            INT := 0;
    BEGIN
      IF trunc(length(pcMsg) / 31998) = 0 THEN
        breakMsgInto := 1;
      ELSE
        breakMsgInto := trunc(length(pcMsg) / 31998);
      END IF;
      FOR rec IN 1 .. breakMsgInto
      LOOP
        write_data(substr(pcMsg, n * 31998, 31998));
        n := n + 1;
      END LOOP;
    END;
  
    close_mail;
    close_connection;
  
  END send_email;

  /* ------------------------------------- */
  FUNCTION get_ddl(db_link     IN VARCHAR2 DEFAULT NULL,
                   object_type IN VARCHAR2,
                   NAME        IN VARCHAR2,
                   SCHEMA      IN VARCHAR2 DEFAULT NULL,
                   version     IN VARCHAR2 DEFAULT 'COMPATIBLE',
                   model       IN VARCHAR2 DEFAULT 'ORACLE',
                   transform   IN VARCHAR2 DEFAULT 'DDL') RETURN CLOB IS
    -- Variables
    l_return    CLOB;
    l_handle    NUMBER;
    l_transform NUMBER;
  
    -- Private Sub-Procedure
    PROCEDURE cleanup IS
    BEGIN
      dbms_metadata_close(db_link => db_link, handle => l_handle);
    EXCEPTION
      WHEN handle_not_open THEN
        NULL;
    END cleanup;
  BEGIN
    l_handle := remote_dbms_metadata.open(db_link     => db_link,
                                          object_type => object_type);
    set_count(db_link => db_link, handle => l_handle, VALUE => 1);
    set_filter(db_link => db_link,
               handle  => l_handle,
               NAME    => 'NAME',
               VALUE   => NAME);
    set_filter(db_link => db_link,
               handle  => l_handle,
               NAME    => 'SCHEMA',
               VALUE   => SCHEMA);
    l_transform := add_transform(db_link => db_link,
                                 handle  => l_handle,
                                 NAME    => transform);
    set_default_table_transforms(db_link                => db_link,
                                 table_transform_handle => l_transform);
  
    apply_session_transform_params(db_link          => db_link,
                                   transform_handle => l_transform);
    l_return := fetch_ddl_clob(db_link => db_link, handle => l_handle);
    cleanup;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      cleanup;
      RAISE;
  END get_ddl;

  /*--+-------------------------------------------------+--
  |   Insert parameter
  |--+-------------------------------------------------+-- */
  PROCEDURE p_InsertParameter(pcParameterName IN VARCHAR2,
                              pcValue         IN VARCHAR2,
                              pcDescription   IN VARCHAR2 DEFAULT NULL) IS
  
    vnIdtRemoteDDLControl NUMBER;
    vnOrdem               NUMBER;
    vcDescription         VARCHAR2(300);
  
  BEGIN
    SELECT nvl(MAX(idt_remote_ddl_control), 0) + 1
    INTO   vnIdtRemoteDDLControl
    FROM   monitor_adm.remote_ddl_control;
  
    SELECT nvl(MAX(c.num_ordem), 0) + 1
    INTO   vnOrdem
    FROM   monitor_adm.remote_ddl_control c
    WHERE  c.cod_remote_ddl_control = pcParameterName;
  
    IF vnOrdem > 1 THEN
      --
      IF pcDescription IS NULL THEN
        SELECT c.des_remote_ddl_control
        INTO   vcDescription
        FROM   monitor_adm.remote_ddl_control c
        WHERE  c.cod_remote_ddl_control = pcParameterName
        AND    rownum = 1;
      ELSE
        vcDescription := pcDescription;
      END IF;
    ELSIF pcDescription IS NOT NULL THEN
      vcDescription := pcDescription;
    ELSIF pcDescription IS NULL THEN
      raise_application_error(-20010,
                              '[ERRO] A descricão para um parametro novo nÃ£o pode ser NULL');
    END IF;
  
    INSERT INTO monitor_adm.remote_ddl_control
      (idt_remote_ddl_control,
       cod_remote_ddl_control,
       num_ordem,
       des_remote_ddl_control,
       des_statement,
       dat_creation,
       dat_update)
    VALUES
      (vnIdtRemoteDDLControl,
       pcParameterName,
       vnOrdem,
       vcDescription,
       pcValue,
       SYSDATE,
       SYSDATE);
  END;

  /*--+-------------------------------------------------+--
  |   Interface to add parameter
  |--+-------------------------------------------------+-- */
  PROCEDURE addParameter(pcParameterName IN VARCHAR2,
                         pcValue         IN VARCHAR2,
                         pbIsUnique      IN BOOLEAN DEFAULT TRUE,
                         pcDescription   IN VARCHAR2 DEFAULT NULL) IS
  
    l_num      NUMBER;
    l_rowcount NUMBER;
    l_msg      VARCHAR2(3000);
  BEGIN
  
    SELECT COUNT(*)
    INTO   l_num
    FROM   dual
    WHERE  EXISTS (SELECT 1
            FROM   monitor_adm.remote_ddl_control c
            WHERE  c.cod_remote_ddl_control = pcParameterName);
  
    --insert based on two conditions
    -- 1: parameter must be unique and there is no rows already
    -- 2: parameter doesnt need to be unique
    IF (pbIsUnique AND l_num = 0) OR NOT pbIsUnique THEN
    
      monitor_adm.remote_dbms_metadata.p_InsertParameter(pcParameterName => pcParameterName,
                                                         pcValue         => pcValue,
                                                         pcDescription   => pcDescription);
      l_rowcount := nvl(SQL%ROWCOUNT, 0);
    
      l_msg := 'Registro inserido para o param [' || pcParameterName ||
               ']: ' || to_Char(nvl(l_rowcount, 0));
    
    ELSIF (pbIsUnique AND l_num > 0) THEN
      l_msg := 'Parametro [' || pcParameterName ||
               '] não pode ser duplicado';
    
      raise_application_error(-20021, l_msg);
    
    END IF;
    dbms_output.put_line(l_msg);
  
  END addParameter;

  /*--+-------------------------------------------------+--
  |  Add table to blacklist. Its definition will not be considered for comparasion
  |--+-------------------------------------------------+-- */
  PROCEDURE add_Table_to_Blacklist(pcOwner IN VARCHAR2,
                                   pcTable IN VARCHAR2) IS
  
    vcOwnerTable VARCHAR2(61);
  
  BEGIN
    SELECT pcOwner || '.' || pcTable
    INTO   vcOwnerTable
    FROM   dual
    WHERE  NOT EXISTS
     (SELECT 1
            FROM   monitor_adm.remote_ddl_control c
            WHERE  c.cod_remote_ddl_control = gcBlackListParameter
            AND    c.des_statement = pcOwner || '.' || pcTable);
  
    p_InsertParameter(gcBlackListParameter,
                      vcOwnerTable,
                      '"Blacklist tables" should not send emails for a period <Owner>.<Table>');
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20020,
                              'There is no setup for object [' || pcOwner || '.' || pcTable ||
                              ']');
    WHEN OTHERS THEN
      RAISE;
    
  END add_Table_to_Blacklist;

  /*--+-------------------------------------------------+--
  |   Check if object its in the blacklist
  |--+-------------------------------------------------+-- */
  FUNCTION isTableInBlackList(pcOwner IN VARCHAR2,
                              pcTable IN VARCHAR2) RETURN NUMBER IS
  
    vnExists NUMBER;
  BEGIN
    SELECT COUNT(1)
    INTO   vnExists
    FROM   dual
    WHERE  EXISTS
     (SELECT 1
            FROM   monitor_adm.remote_ddl_control c
            WHERE  c.cod_remote_ddl_control = gcBlackListParameter
            AND    TRIM(c.des_statement) = pcOwner || '.' || pcTable);
  
    RETURN vnExists;
  END isTableInBlackList;

  function isColumnInBlacklist(pcOwner  in varchar2,
                               pcTable  in varchar2,
                               pcColumn in varchar2) return boolean is
    vnExists NUMBER;
  begin
    SELECT COUNT(1)
    INTO   vnExists
    FROM   dual
    WHERE  EXISTS
     (SELECT 1
            FROM   monitor_adm.remote_ddl_control c
            WHERE  c.cod_remote_ddl_control = gcColumnBlackListParameter
            AND    upper(TRIM(c.des_statement)) =
                   pcOwner || '.' || pcTable || '.' || pcColumn);
  
    RETURN vnExists = 1;
  
  end isColumnInBlacklist;

  /*--+-------------------------------------------------+--
  |   Check if the object should not be dropped from 
	| the slave
  |--+-------------------------------------------------+-- */
  FUNCTION isTableOkaneExclusive(pcOwner IN VARCHAR2,
                                 pcTable IN VARCHAR2) RETURN NUMBER IS
  
    vnExists NUMBER;
  BEGIN
    SELECT COUNT(1)
    INTO   vnExists
    FROM   dual
    WHERE  EXISTS
     (SELECT 1
            FROM   monitor_adm.remote_ddl_control c
            WHERE  c.cod_remote_ddl_control = gcOkaneExclusiveTable
            AND    TRIM(c.des_statement) = pcOwner || '.' || pcTable);
  
    RETURN vnExists;
  END isTableOkaneExclusive;
  /*--+-------------------------------------------------+--
  |   Purge objects from blacklist
  |--+-------------------------------------------------+-- */
  PROCEDURE purge_BlackList IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  
    vnPurgeDays NUMBER := to_number(get_ControlParameter('BLACKLIST_TABLE_TIME'));
  BEGIN
    FOR rec IN (SELECT c.idt_remote_ddl_control,
                       c.des_statement
                FROM   monitor_adm.remote_ddl_control c
                WHERE  c.cod_remote_ddl_control = gcBlackListParameter
                AND    SYSDATE - c.dat_creation > vnPurgeDays)
    LOOP
      DELETE FROM monitor_adm.remote_ddl_control c
      WHERE  c.idt_remote_ddl_control = rec.idt_remote_ddl_control;
      COMMIT;
    
      log('[' || rec.des_statement || '] removed from blacklist',
          'OK');
    END LOOP;
    COMMIT;
  END purge_BlackList;

  /*--+-------------------------------------------------+--
  |   Count number of objects in the blacklist
  |--+-------------------------------------------------+-- */
  FUNCTION get_BlackList_Count RETURN NUMBER IS
  
    vn_NumberOfTableInBlacklist INTEGER;
  BEGIN
    SELECT COUNT(*)
    INTO   vn_NumberOfTableInBlacklist
    FROM   monitor_adm.remote_ddl_control c
    WHERE  c.cod_remote_ddl_control = gcBlackListParameter;
  
    RETURN vn_NumberOfTableInBlacklist;
  
  END get_BlackList_Count;
	

  /* ------------------------------------- */
  FUNCTION get_dependent_ddl(db_link            IN VARCHAR2 DEFAULT NULL,
                             object_type        IN VARCHAR2,
                             base_object_name   IN VARCHAR2,
                             base_object_schema IN VARCHAR2 DEFAULT NULL,
                             version            IN VARCHAR2 DEFAULT 'COMPATIBLE',
                             model              IN VARCHAR2 DEFAULT 'ORACLE',
                             transform          IN VARCHAR2 DEFAULT 'DDL',
                             object_count       IN NUMBER DEFAULT 10000)
    RETURN CLOB IS
    -- Variables
    l_return    CLOB;
    l_handle    NUMBER;
    l_transform NUMBER;
  
    -- Private Sub-Procedure
    PROCEDURE cleanup IS
    BEGIN
      dbms_metadata_close(db_link => db_link, handle => l_handle);
    EXCEPTION
      WHEN handle_not_open THEN
        NULL;
    END cleanup;
  BEGIN
    l_handle := remote_dbms_metadata.open(db_link     => db_link,
                                          object_type => object_type);
    set_filter(db_link => db_link,
               handle  => l_handle,
               NAME    => 'BASE_OBJECT_NAME',
               VALUE   => base_object_name);
    set_filter(db_link => db_link,
               handle  => l_handle,
               NAME    => 'BASE_OBJECT_SCHEMA',
               VALUE   => base_object_schema);
    set_count(db_link => db_link,
              handle  => l_handle,
              VALUE   => object_count);
    l_transform := remote_dbms_metadata.add_transform(db_link => db_link,
                                                      handle  => l_handle,
                                                      NAME    => transform);
    apply_session_transform_params(db_link          => db_link,
                                   transform_handle => l_transform);
    l_return := fetch_ddl_clob(db_link => db_link, handle => l_handle);
    cleanup;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      cleanup;
      RAISE;
  END get_dependent_ddl;
	
  /*--+-------------------------------------------------+--
  |  Compare local index against remote index
  |--+-------------------------------------------------+-- */
  FUNCTION get_index_ddl(pcOwner     IN VARCHAR2,
                         pcTableName IN VARCHAR2,
                         pcDblink    IN VARCHAR2) RETURN CLOB IS
  
    vcDropIndex CONSTANT VARCHAR2(2526) := 'DROP INDEX @OWNER.@CONSTRAINT_NAME;';
    vcFinalStmt CLOB;
    vcQuery     VARCHAR2(32767);
  
    cur SYS_REFCURSOR;
  
    TYPE rec_index IS RECORD(
      table_owner     VARCHAR2(30),
      table_name      VARCHAR2(30),
      index_name      VARCHAR2(30),
      tablespace_name VARCHAR2(30),
      constraint_type VARCHAR2(1),
      operation       VARCHAR2(10),
      indexed_columns VARCHAR2(500));
  
    TYPE t_index IS TABLE OF rec_index;
  
    arrayIndex t_index;
  
    vcErrorMsg VARCHAR2(32767);
  
    FUNCTION processCreateIndex(pcTableOwner      IN VARCHAR2,
                                pcTableName       IN VARCHAR2,
                                pcIndexName       IN VARCHAR2,
                                pcTablespaceName  IN VARCHAR2,
                                pcConstraintType  IN VARCHAR2,
                                pcIndexed_columns IN VARCHAR2)
      RETURN VARCHAR2 IS
      vcCreate     VARCHAR2(32767);
      vcConstraint VARCHAR2(256);
      vcPKConstraint        CONSTANT VARCHAR2(256) := get_ControlParameter('IDX_PK');
      vcUniqueConstraint    CONSTANT VARCHAR2(256) := get_ControlParameter('IDX_UNIQUE');
      vcNonUniqueConstraint CONSTANT VARCHAR2(256) := get_ControlParameter('IDX_NONUNIQUE');
    
    BEGIN
      -- Define a constraint
      IF pcConstraintType = 'P' THEN
        vcConstraint := vcPKConstraint;
      ELSIF pcConstraintType = 'U' THEN
        vcConstraint := vcUniqueConstraint;
      ELSE
        vcConstraint := vcNonUniqueConstraint;
      END IF;
    
      vcCreate := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(vcConstraint,
                                                          '@OWNER',
                                                          pcTableOwner),
                                                  '@TABLE',
                                                  pcTableName),
                                          '@CONSTRAINT_NAME',
                                          pcIndexName),
                                  '@COLUMN',
                                  pcIndexed_columns),
                          '@TBS',
                          pcTablespaceName);
    
      RETURN vcCreate;
    END processCreateIndex;
  
  BEGIN
    vcQuery := 'SELECT table_owner,
       table_name,
       index_name,
       tablespace_name,
       constraint_type,
       operation,
       col
FROM   (WITH remote AS (SELECT *
                        FROM   (SELECT *
                                FROM   (SELECT nvl(x.constraint_type,
                                                   decode(x.uniqueness,
                                                          ''UNIQUE'',
                                                          ''U'',
                                                          NULL)) constraint_type,
                                               x.table_owner,
                                               x.table_name,
                                               x.index_name,
                                               x.tablespace_name,
                                               (SELECT listagg(CASE
                                                                 WHEN ic.COLUMN_NAME LIKE
                                                                      ''SYS%'' THEN
                                                                  remote_dbms_metadata.convert_long_var(e.index_name,
                                                                                   e.column_position,''' ||
               pcDblink || ''')' || CHR(32) || ' ||
                                                                  ic.DESCEND
                                                                 ELSE
                                                                  ic.COLUMN_NAME
                                                               END,
                                                               '','') WITHIN GROUP(ORDER BY ic.COLUMN_POSITION ASC)
                                                FROM   Dba_Ind_Columns@' ||
               pcDblink || ' ic
                                                LEFT   JOIN Dba_Ind_Expressions@' ||
               pcDblink || ' e
                                                ON     e.index_owner =
                                                       ic.index_owner
                                                AND    e.index_name =
                                                       ic.index_name
                                                WHERE  ic.INDEX_OWNER = x.owner
                                                AND    ic.INDEX_NAME =
                                                       x.index_name) indexed_columns
                                        FROM   (SELECT i.table_owner,
                                                       i.table_name,
                                                       i.index_name,
                                                       i.tablespace_name,
                                                       c.constraint_type,
                                                       i.uniqueness,
                                                       i.owner
                                                FROM   dba_indexes@' ||
               pcDblink || ' i
                                                LEFT   JOIN dba_constraints@' ||
               pcDblink || ' c
                                                ON     i.table_owner = c.owner
                                                AND    i.table_name =
                                                       c.table_name
                                                AND    i.index_name =
                                                       c.constraint_name
                                                --
                                                WHERE  i.table_owner =:1
                                                AND    i.table_name =:2) x)
                                ORDER  BY CASE
                                            WHEN constraint_type = ''P'' THEN
                                             1
                                            WHEN constraint_type = ''U'' THEN
                                             2
                                            ELSE
                                             3
                                          END)), loc AS (SELECT *
                                                         FROM   (SELECT *
                                                                 FROM   (SELECT nvl(x.constraint_type,
                                                                                    decode(x.uniqueness,
                                                                                           ''UNIQUE'',
                                                                                           ''U'',
                                                                                           NULL)) constraint_type,
                                                                                x.table_owner,
                                                                                x.table_name,
                                                                                x.index_name,
                                                                                x.tablespace_name,
                                                                                (SELECT listagg(CASE
                                                                                                  WHEN ic.COLUMN_NAME LIKE
                                                                                                       ''SYS%'' THEN
                                                                                                   remote_dbms_metadata.convert_long_var(e.index_name,
                                                                                                                    e.column_position) || ' ||
               CHR(32) || '
                                                                                                   ic.DESCEND
                                                                                                  ELSE
                                                                                                   ic.COLUMN_NAME
                                                                                                END,
                                                                                                '','') WITHIN GROUP(ORDER BY ic.COLUMN_POSITION ASC)
                                                                                 FROM   Dba_Ind_Columns ic
                                                                                 LEFT   JOIN Dba_Ind_Expressions e
                                                                                 ON     e.index_owner =
                                                                                        ic.index_owner
                                                                                 AND    e.index_name =
                                                                                        ic.index_name
                                                                                 WHERE  ic.INDEX_OWNER =
                                                                                        x.owner
                                                                                 AND    ic.INDEX_NAME =
                                                                                        x.index_name) indexed_columns
                                                                         FROM   (SELECT i.table_owner,
                                                                                        i.table_name,
                                                                                        i.index_name,
                                                                                        i.tablespace_name,
                                                                                        c.constraint_type,
                                                                                        i.uniqueness,
                                                                                        i.owner
                                                                                 FROM   dba_indexes i
                                                                                 LEFT   JOIN dba_constraints c
                                                                                 ON     i.table_owner =
                                                                                        c.owner
                                                                                 AND    i.table_name =
                                                                                        c.table_name
                                                                                 AND    i.index_name =
                                                                                        c.constraint_name
                                                                                 --
                                                                                 WHERE  i.table_owner =:3
                                                                                 AND    i.table_name =:4) x)
                                                                 ORDER  BY CASE
                                                                             WHEN constraint_type = ''P'' THEN
                                                                              1
                                                                             WHEN constraint_type = ''U'' THEN
                                                                              2
                                                                             ELSE
                                                                              3
                                                                           END))
         SELECT nvl(r.table_owner, l.table_owner) table_owner,
                nvl(r.table_name, l.table_name) table_name,
                nvl(r.index_name, l.index_name) index_name,
                nvl(r.tablespace_name, l.tablespace_name) tablespace_name,
                nvl(r.constraint_type, l.constraint_type) constraint_type,
                CASE
                  WHEN r.index_name IS NOT NULL AND
                       l.index_name IS NULL THEN
                   ''ADD''
                  WHEN r.index_name IS NOT NULL AND
                       l.index_name IS NOT NULL AND
                       r.indexed_columns <> l.indexed_columns THEN
                   ''ALTER''
                  WHEN r.index_name IS NOT NULL AND
                       l.index_name IS NOT NULL THEN
                   ''OK''
                  WHEN r.index_name IS NULL AND
                       l.index_name IS NOT NULL THEN
                   ''DROP''
                  ELSE
                   ''ERRO''
                END AS operation,
                CASE
                  WHEN r.index_name IS NOT NULL AND
                       l.index_name IS NULL THEN
                   r.indexed_columns
                  WHEN r.index_name IS NOT NULL AND
                       l.index_name IS NOT NULL AND
                       r.indexed_columns <> l.indexed_columns THEN
                   r.indexed_columns
                END AS col
         FROM   remote r
         FULL   OUTER JOIN loc l
         ON     r.table_owner = l.table_owner
         AND    r.table_name = l.table_name
         AND    r.index_name = l.index_name)
         WHERE  1 = 1
         AND    operation IN (''ALTER'', ''ADD'', ''DROP'')
         ORDER  BY DECODE(operation,
                          ''DROP'',
                          1,
                          DECODE(operation, ''ALTER'', 2, 3))';
  
    OPEN cur FOR vcQuery
      USING pcOwner, pcTableName, pcOwner, pcTableName;
    FETCH cur BULK COLLECT
      INTO arrayIndex;
    CLOSE cur;
  
    FOR i IN 1 .. arrayIndex.count
    LOOP
      DECLARE
        vcCreated VARCHAR2(32767);
      BEGIN
        IF arrayIndex(i).operation = 'DROP' THEN
          vcCreated := REPLACE(REPLACE(vcDropIndex,
                                       '@OWNER',
                                       arrayIndex(i).table_owner),
                               '@CONSTRAINT_NAME',
                               arrayIndex(i).index_name);
        
        ELSIF arrayIndex(i).operation = 'ALTER' THEN
          vcCreated := REPLACE(REPLACE(vcDropIndex,
                                       '@OWNER',
                                       arrayIndex(i).table_owner),
                               '@CONSTRAINT_NAME',
                               arrayIndex(i).index_name) || get_whitespace;
          vcCreated := vcCreated ||
                       processCreateIndex(arrayIndex(i).table_owner,
                                          arrayIndex(i).table_name,
                                          arrayIndex(i).index_name,
                                          arrayIndex(i).tablespace_name,
                                          arrayIndex(i).constraint_type,
                                          arrayIndex(i).indexed_columns);
        ELSIF arrayIndex(i).operation = 'ADD' THEN
          vcCreated := processCreateIndex(arrayIndex(i).table_owner,
                                          arrayIndex(i).table_name,
                                          arrayIndex(i).index_name,
                                          arrayIndex(i).tablespace_name,
                                          arrayIndex(i).constraint_type,
                                          arrayIndex(i).indexed_columns);
        ELSE
          NULL;
        END IF;
        -- Adiciona ao RETURN
        vcFinalStmt := vcFinalStmt || vcCreated || CASE
                         WHEN vcCreated IS NOT NULL THEN
                          get_whitespace
                         ELSE
                          NULL
                       END;
      END;
    END LOOP;
  
    RETURN vcFinalStmt;
  EXCEPTION
    WHEN OTHERS THEN
      vcErrorMsg := to_char(SQLERRM);
      log('[ERRO] generate_index_ddl - ' || vcErrorMsg, 'NOK');
  END get_index_ddl;
  /*--+-------------------------------------------------+--
  |   Compare local table against remote table builds ALTER TABLE
  |--+-------------------------------------------------+-- */
  FUNCTION get_alter_ddl(pcOwner     IN VARCHAR2,
                         pcTableName IN VARCHAR2,
                         pcDblink    IN VARCHAR2,
                         pcSource    IN VARCHAR2) RETURN CLOB IS
  
    vcQuery VARCHAR2(3000);
    --
    vcAlterDDLRemoto CLOB;
    vcAlterDDLLocal  CLOB;
    vcAlterDDLFinal  CLOB;
    --
    vrGPGTranslation rec_OwnerTranslation;
    --
    vnTranslationExecuted NUMBER(1);
  
    FUNCTION process(pcQuery  IN VARCHAR2,
                     pcType   IN VARCHAR2,
                     pcOwner1 IN VARCHAR2,
                     pcTable1 IN VARCHAR2,
                     pcOwner2 IN VARCHAR2,
                     pcTable2 IN VARCHAR2) RETURN CLOB IS
    
      vcExecStmt  VARCHAR2(3000);
      vcDataType  VARCHAR2(3000);
      vcAddModify VARCHAR2(20);
      vcFinalStmt CLOB;
      --
      cur_Compare SYS_REFCURSOR;
      --
      vtTabColumns gt_tabColumn;
      --
      vnColumnExists NUMBER(1);
      --
      pcGPGOwner VARCHAR2(30);
      pcGPGTable VARCHAR2(30);
      --
    BEGIN
      OPEN cur_Compare FOR vcQuery
        USING pcOwner1, pcTable1, pcOwner2, pcTable2;
      FETCH cur_Compare BULK COLLECT
        INTO vtTabColumns;
      CLOSE cur_Compare;
    
      FOR i IN 1 .. vtTabColumns.count
      LOOP
        -- Must filter by the translated owner
        IF pcType = 'ADD' then
          pcGPGOwner := pcOwner2;
          pcGPGTable := pcTable2;
        ELSIF pcType = 'DROP' THEN
          pcGPGOwner := pcOwner1;
          pcGPGTable := pcTable1;
        END IF;
      
        SELECT COUNT(1)
        INTO   vnColumnExists
        FROM   dba_tab_columns c
        WHERE  c.OWNER = pcGPGOwner
        AND    c.TABLE_NAME = pcGPGTable
        AND    c.COLUMN_NAME = vtTabColumns(i).column_name;
      
				--In case you must compare with remote db
        IF pcType = 'ADD' THEN
          IF vnColumnExists = 0 THEN
            vcAddModify := ' ADD ';
          ELSE
            vcAddModify := ' MODIFY ';
          END IF;
        
					-- In case you must compare with local db
        ELSIF pcType = 'DROP' THEN
          IF vnColumnExists = 1 THEN
            vcAddModify := ' DROP COLUMN ';
          ELSE
            RETURN NULL;
          END IF;
        END IF;
      
        --if it already exists then give an error
        BEGIN
          vcDataType := CASE
                        --number
                          WHEN vtTabColumns(i).data_type = 'NUMBER' THEN
                           ' NUMBER' || CASE
                             WHEN vtTabColumns(i).data_precision IS NOT NULL THEN
                              '(' || vtTabColumns(i).data_precision || CASE
                                WHEN vtTabColumns(i).data_scale > 0 THEN
                                 ', ' || vtTabColumns(i).data_scale
                                ELSE
                                 NULL
                              END || ')'
                           
                             ELSE
                              ' '
                           END
                        --varchar2
                          WHEN vtTabColumns(i).data_type = 'VARCHAR2' THEN
                           ' VARCHAR2(' || vtTabColumns(i).data_length || ') '
                        -- date
                          WHEN vtTabColumns(i).data_type = 'DATE' THEN
                           ' DATE '
                          WHEN vtTabColumns(i).data_type = 'CHAR' THEN
                           ' CHAR(' || vtTabColumns(i).data_length || ') '
                          WHEN vtTabColumns(i).data_type = 'CLOB' THEN
                           ' CLOB '
                          WHEN vtTabColumns(i).data_type LIKE 'TIMESTAMP%' THEN
                           ' TIMESTAMP(6) '
                        END;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Configurar novo tipo de DATATYPE');
        END;
				-- is the column in the blacklist columns?
        if not isColumnInBlacklist(pcGPGOwner,
                                   pcGPGTable,
                                   vtTabColumns(i).column_name) then
																	 
          vcExecStmt := 'ALTER TABLE ' || pcGPGOwner || '.' || pcGPGTable ||
                        vcAddModify || vtTabColumns(i).column_name || ' ' || CASE --não adiciona o datatpye caso seja drop
                          WHEN pcType = 'DROP' THEN
                           NULL
                          ELSE
                           vcDataType
                        END;
        
          vcFinalStmt := vcFinalStmt || vcExecStmt || ';' || get_whitespace;
					
        end if;
      
      END LOOP;
      RETURN vcFinalStmt;
    END process;
  
  BEGIN
  
 
    IF pcSource = gcOkaneSource THEN
      vnTranslationExecuted := 0;
    ELSIF vrGPGTranslation.pho_Owner <> vrGPGTranslation.gpg_Owner THEN
      vnTranslationExecuted := 1;
    ELSE
      vnTranslationExecuted := 0;
    END IF;
  
		--Add/modify column comparating remote against local
    vcQuery          := 'SELECT c.COLUMN_NAME, c.DATA_TYPE, c.DATA_LENGTH, c.DATA_PRECISION, c.DATA_SCALE
          FROM dba_tab_columns@' || pcDblink || ' c
          WHERE c.OWNER = :ow
          AND   c.TABLE_NAME = :tab
          AND   (EXISTS (SELECT 1 FROM DBA_OBJECTS WHERE OBJECT_NAME = c.TABLE_NAME AND OWNER=c.OWNER AND OBJECT_TYPE =''TABLE'') OR ' ||
                        vnTranslationExecuted || '=1)
          MINUS
          SELECT c.COLUMN_NAME, c.DATA_TYPE, c.DATA_LENGTH, c.DATA_PRECISION, c.DATA_SCALE
          FROM dba_tab_columns c
          WHERE c.OWNER = :ow
          AND   c.TABLE_NAME = :tab';
    vcAlterDDLRemoto := process(vcQuery,
                                'ADD',
                                vrGPGTranslation.pho_Owner, 
                                vrGPGTranslation.pho_Table, 
                                vrGPGTranslation.gpg_Owner,
                                vrGPGTranslation.gpg_Table);
  
		-- drop column comparing local against remote
    vcQuery := 'SELECT c.COLUMN_NAME, null, null, null, null
          FROM dba_tab_columns c
          WHERE c.OWNER = :ow
          AND   c.TABLE_NAME = :tab
          MINUS
          SELECT c.COLUMN_NAME, null, null, null, null
          FROM dba_tab_columns@' || pcDblink || ' c
          WHERE c.OWNER = :ow
          AND   c.TABLE_NAME = :tab
          AND   (EXISTS (SELECT 1 FROM DBA_OBJECTS WHERE OBJECT_NAME = c.TABLE_NAME AND OWNER=c.OWNER AND OBJECT_TYPE =''TABLE'')OR ' ||
               vnTranslationExecuted || '=1)';
  
    vcAlterDDLLocal := process(vcQuery,
                               'DROP',
                               vrGPGTranslation.gpg_Owner, 
                               vrGPGTranslation.gpg_Table, 
                               vrGPGTranslation.pho_Owner,
                               vrGPGTranslation.pho_Table);
  
    vcAlterDDLFinal := vcAlterDDLRemoto || CASE
                         WHEN vcAlterDDLLocal IS NOT NULL THEN
                          chr(10)
                         ELSE
                          NULL
                       END || vcAlterDDLLocal;
    RETURN vcAlterDDLFinal;
  
  END get_alter_ddl;

  /*--+-------------------------------------------------+--
  |   Compare local table against remote table to build DROP DDL
  |--+-------------------------------------------------+-- */
  FUNCTION get_drop_ddl(pcOwner     IN VARCHAR2,
                        pcTableName IN VARCHAR2,
                        pcDblink    IN VARCHAR2,
                        pcSource    IN VARCHAR2) RETURN CLOB IS
    vcDropDDL     CLOB;
    vcComandoDROP VARCHAR2(3267);
  
  BEGIN
    vcDropDDL := REPLACE(REPLACE(get_ControlParameter('DROP_STATEMENT'),
                                 '@OWNER',
                                 pcOwner),
                         '@TABLE',
                         pcTableName);
  
    RETURN vcDropDDL;
  END get_drop_ddl;
  /*--+-------------------------------------------------+--
  |   Get privilegies
  |--+-------------------------------------------------+-- */
  FUNCTION get_generic_ddl(pcOwner   IN VARCHAR2,
                           pcTable   IN VARCHAR2,
                           pcDDL     IN CLOB,
                           pcDDLType IN VARCHAR2) RETURN CLOB IS
  
    vc_stmt CLOB;
    vcClob  CLOB;
    vcSyn   VARCHAR2(3000);
  
  BEGIN
    --+-------------------------+--
    -- Privs
    --+-------------------------+--
    IF pcDDLType = 'PRIVS' THEN
      vc_stmt := '                          SELECT REPLACE(REPLACE(c.des_statement, ''@OWNER'',''' ||
                 pcOwner ||
                 '''),
                                               ''@TABLE'',
                                               ''' ||
                 pcTable ||
                 ''') stmt
                                FROM   monitor_adm.remote_ddl_control c
                                WHERE  c.cod_remote_ddl_control =''' ||
                 'OKANE_TABLE_USER_PRIV' || '''';
      --get privs,
      vcClob := get_ControlParameterList('OKANE_TABLE_USER_PRIV', vc_stmt);
    
      --get synonyms
      vcSyn := REPLACE(REPLACE(get_ControlParameter('OKANE_TABLE_SYN'),
                               '@TABLE',
                               pcTable),
                       '@OWNER',
                       pcOwner);
    
      vcClob := CASE
                  WHEN vcClob IS NOT NULL AND vcSyn IS NOT NULL THEN
                   vcSyn || get_whitespace || vcClob
                  WHEN vcClob IS NULL AND vcSyn IS NOT NULL THEN
                   vcSyn
                  WHEN vcClob IS NOT NULL AND vcSyn IS NULL THEN
                   vcClob
                  ELSE
                   NULL
                END;
    
      --+-------------------------+--
      -- Create MLOG
      --+-------------------------+--
    ELSIF pcDDLType = 'MLOG' THEN
      vc_stmt := '
                          SELECT REPLACE(REPLACE(c.des_statement, ''@OWNER'',''' ||
                 pcOwner ||
                 '''),
                                               ''@TABLE'',
                                               ''' ||
                 pcTable ||
                 ''') stmt
                                FROM   monitor_adm.remote_ddl_control c
                                WHERE  c.cod_remote_ddl_control =''' ||
                 'OKANE_TABLE_MLOG' || '''';
    
      vcClob := get_ControlParameterList('OKANE_TABLE_MLOG', vc_stmt);
    END IF;
  
    RETURN pcDDL || get_whitespace || vcClob;
  
  END get_generic_ddl;
  /*--+-------------------------------------------------+--
  |   Check if object has materialized view 
  |--+-------------------------------------------------+-- */
  FUNCTION get_mview_ddl(pcOwner     IN VARCHAR2,
                         pcTableName IN VARCHAR2,
                         pcAlterDDL  IN CLOB,
                         pcDblink    IN VARCHAR2,
                         pcSource    IN VARCHAR2,
                         pcDDLtype   IN VARCHAR2 DEFAULT NULL) RETURN CLOB IS
  
    vcViewName     dba_mviews.MVIEW_NAME%TYPE;
    vcRefreshOwner dba_refresh_children.ROWNER%TYPE;
    vcRefreshName  dba_refresh_children.RNAME%TYPE;
    vnFlgMviewNeed PLS_INTEGER;
  
    MviewExists BOOLEAN;
    vcClob      CLOB;
    vcParameter VARCHAR2(80);
  
    vTableDDLPlusIndexDDL CLOB;
    --
    vcIndexDDLEnabled VARCHAR2(3267) := get_ControlParameter('ENABLE_INDEX_DDL');
  
    PROCEDURE build_steps(pcCodControl  IN VARCHAR2,
                          pcIndAmbiente IN VARCHAR2 DEFAULT NULL,
                          pcClob        IN CLOB DEFAULT NULL) IS
    
      vcStmt monitor_adm.remote_ddl_control.des_statement%TYPE;
    
      CURSOR cur_MviewDDL(p_cod_remote_control IN VARCHAR2) IS
        SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(r.des_statement,
                                                       '@G_OWNER',
                                                       vcRefreshOwner),
                                               '@G_NAME',
                                               vcRefreshName),
                                       '@OWNER',
                                       pcOwner),
                               '@TABLE',
                               pcTableName),
                       '@DBLINK',
                       pcDblink)
        FROM   monitor_adm.remote_ddl_control r
        WHERE  r.cod_remote_ddl_control = p_cod_remote_control
        ORDER  BY r.num_ordem ASC;
    
    BEGIN
      IF pcClob IS NOT NULL THEN
        vcClob := vcClob || pcClob || chr(10);
        RETURN;
      END IF;
    
      IF pcIndAmbiente IS NOT NULL THEN
        vcClob := vcClob || '--' || pcIndAmbiente || get_whitespace;
      END IF;
    
      OPEN cur_MviewDDL(pcCodControl);
      LOOP
        FETCH cur_MviewDDL
          INTO vcStmt;
        EXIT WHEN cur_MviewDDL%NOTFOUND;
        vcClob := vcClob || vcStmt || get_whitespace;
      END LOOP;
      CLOSE cur_MviewDDL;
    
    END build_steps;
  
  BEGIN
    IF pcSource NOT IN (gcGalapagosSource, gcOkaneSource) THEN
      raise_application_error(-20004, 'Configurar novo ambiente');
    END IF;
  
    --validar o snapshot
    BEGIN
      SELECT m.MVIEW_NAME,
             c.ROWNER,
             c.RNAME,
             (SELECT COUNT(1)
              FROM   dual
              WHERE  EXISTS
               (SELECT 1
                      FROM   monitor_adm.remote_ddl_control c
                      WHERE  c.cod_remote_ddl_control = 'FAKE_MVIEW_NEED'
                      AND    c.des_statement = pcTableName)) flg_fake_mview
      INTO   vcViewName,
             vcRefreshOwner,
             vcRefreshName,
             vnFlgMviewNeed
      FROM   dba_mviews m
      LEFT   JOIN dba_refresh_children c
      ON     m.OWNER = c.owner
      AND    m.MVIEW_NAME = c.name
      WHERE  m.OWNER = pcOwner
      AND    m.MVIEW_NAME = pcTableName;
      MviewExists := TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        MviewExists := FALSE;
        --o owner default deve ser configurado aqui
        begin
          select c.des_statement
          into   vcParameter
          from   monitor_adm.remote_ddl_control c
          where  c.cod_remote_ddl_control = 'REFRESH_GROUP_DEFAULT'
          and    instr(c.des_statement, pcOwner) > 0;
        exception
          when NO_DATA_FOUND then
            raise_application_error(-20001,
                                    'Setup a default refresh group [REFRESH_GROUP_DEFAULT] by user ' ||
                                    pcOwner);
        end;
        -- obtem os valores default para o refreshgroup
        vcRefreshOwner := substr(vcParameter,
                                 0,
                                 instr(vcParameter, '.') - 1);
      
        vcRefreshName := substr(vcParameter,
                                instr(vcParameter, '.') + 1,
                                length(vcParameter));
    END;
  
    --+-------------------------+--
    -- Add index just to tables that has Materialized View
    --+-------------------------+--
    DECLARE
      vcIndexDDL CLOB;
    BEGIN
      IF upper(TRIM(vcIndexDDLEnabled)) = 'S' AND pcDDLtype <> 'D' THEN
        vcIndexDDL := get_index_ddl(pcOwner, pcTableName, pcDblink);
      END IF;
      vTableDDLPlusIndexDDL := pcAlterDDL || get_whitespace || vcIndexDDL;
    END;
    --+-------------------------+--
    --gpg
    --+-------------------------+--
    IF pcSource = gcGalapagosSource THEN
      IF NOT MviewExists THEN
				-- No need to create mview
        RETURN pcAlterDDL;
      END IF;
    
      IF MviewExists AND vnFlgMviewNeed > 0 THEN
				--rule 1: table exist and need to be fake
      
        build_steps('FAKE_MVIEW_GROUP_01', 'ORIGEM');
        build_steps('FAKE_MVIEW_GROUP_02', 'DESTINO');
        -----------------------
				-- concatenate ddl command to mviews ddl
        build_steps(NULL, NULL, vTableDDLPlusIndexDDL);
        -----------------------
        build_steps('FAKE_MVIEW_GROUP_03', 'DESTINO');
        build_steps('FAKE_MVIEW_GROUP_04', 'ORIGEM');
        build_steps('FAKE_MVIEW_GROUP_05', 'DESTINO');
        build_steps('FAKE_MVIEW_GROUP_06', 'ORIGEM');
      
      ELSIF MviewExists THEN
				--rule 2: altered table and there is a mview
        build_steps('ALTER_SNAP_INI');
				--concatenate ddl comand to mviews ddl
        build_steps(NULL, NULL, vTableDDLPlusIndexDDL);
        -----------------------
        build_steps('ALTER_SNAP_FIM');
        --
      END IF;
      --+-------------------------+--
      -- OKANE
      --+-------------------------+--
    ELSIF pcSource = gcOkaneSource THEN
      --
      IF pcDDLtype = 'D' THEN
				-- rule 4: table exists in local site e must be dropped
        build_steps('MVIEW_DROP_SNAPSHOT');
			
        build_steps(NULL, NULL, vTableDDLPlusIndexDDL);
        -----------------------
      ELSIF NOT MviewExists THEN
				-- rule 1: table muust be created for the first time
        build_steps(NULL, NULL, vTableDDLPlusIndexDDL);
        build_steps('CREATE_SNAP');
        --
      
      ELSIF MviewExists AND vnFlgMviewNeed > 0 THEN
				-- rule 2: table exists in local and it is a big table
        build_steps('FAKE_MVIEW_GROUP_01', 'ORIGEM');
        build_steps('FAKE_MVIEW_GROUP_02', 'DESTINO');
        -----------------------		
        build_steps(NULL, NULL, vTableDDLPlusIndexDDL);
        -----------------------
        build_steps('FAKE_MVIEW_GROUP_03', 'DESTINO');
        build_steps('FAKE_MVIEW_GROUP_04', 'ORIGEM');
        build_steps('FAKE_MVIEW_GROUP_05', 'DESTINO');
        build_steps('FAKE_MVIEW_GROUP_06', 'ORIGEM');
        --
      ELSIF MviewExists THEN
				-- rule 3: table exists 
        build_steps('ALTER_SNAP_INI');
        build_steps(NULL, NULL, vTableDDLPlusIndexDDL);
        -----------------------
        build_steps('ALTER_SNAP_FIM');
        --
      END IF;
    
    END IF;
  
    RETURN vcClob;
  
  END get_mview_ddl;
  /*--+-------------------------------------------------+--
  |   Get table comments
  |--+-------------------------------------------------+-- */
  FUNCTION get_Table_Comments(pcOwner     IN VARCHAR2,
                              pcTableName IN VARCHAR2,
                              pcDbLink    IN VARCHAR) RETURN CLOB IS
    vcQuery VARCHAR2(3000);
    cur     SYS_REFCURSOR;
  
    clobComments CLOB;
  
    TYPE tclob IS TABLE OF VARCHAR2(32767);
    tclobarray tclob;
  
  BEGIN
    vcQuery := 'SELECT ''comment on column ''|| c.owner || ''.'' || c.table_name || ''.'' || c.column_name || '' is q''|| ''''''!''||c.comments ||''!'''';''
                FROM   dba_col_comments@' || pcDbLink || ' c
                WHERE  c.owner = :1
                AND    c.table_name = :2
                AND    c.comments IS NOT NULL';
  
    OPEN cur FOR vcQuery
      USING pcOwner, pcTableName;
  
    FETCH cur BULK COLLECT
      INTO tclobarray;
  
    FOR i IN 1 .. tclobarray.count
    LOOP
      clobComments := clobComments || tclobarray(i) || get_whitespace;
    END LOOP;
    CLOSE cur;
  
    RETURN clobComments;
  
  END get_Table_Comments;
 
  /*--+-------------------------------------------------+--
  |   Objetivo:
  |--+-------------------------------------------------+-- */
  FUNCTION workflow_OKANE(dblink IN VARCHAR2) RETURN CLOB IS
    TYPE Remote IS REF CURSOR;
    cur_remote   remote;
    vnDays       NUMBER;
    ObjectsArray gRemoteRec;
  
    vcOrderByClause monitor_adm.remote_ddl_control.des_statement%TYPE;
    vcClobFinal     CLOB;
  
    --
    clobComentario CLOB;
    vcComentario   VARCHAR2(3267) := get_ControlParameter('ENABLE_COMMENT_COLUMN');
    --
  
  BEGIN
    --Informar a existencia de objetos cadastrados na blacklist:
    DECLARE
      vn_NumberOfTableInBlacklist INTEGER;
    BEGIN
      vn_NumberOfTableInBlacklist := get_BlackList_Count;
      -- informa apenas se o numero for maior do que zero
      -- Neste ponto do codigo, se existirem valores para blacklist, sera enviado email, mesmo que nao existam alteracoes estruturais para notificar
      IF vn_NumberOfTableInBlacklist > 0 THEN
        vcClobFinal := vcClobFinal ||
                       'Numero de tabelas gravadas na BLACK LIST: ' ||
                       vn_NumberOfTableInBlacklist || get_whitespace;
      END IF;
    
    END;
    -- CLAUSULA DE ORDENACAO
    vcOrderByClause := get_ControlParameter('OKANE_ORDER_BY');
    IF vcOrderByClause = 'C' THEN
      vcOrderByClause := ' ORDER BY ind_alter_type DESC ';
    ELSE
      vcOrderByClause := ' ORDER BY ind_alter_type ASC ';
    END IF;
  
    --obtem parametro de dias
    vnDays := to_number(get_ControlParameter('DAYS'));
  
    OPEN cur_remote FOR 'SELECT owner,
                         object_name,
                         ind_alter_type
                  FROM   (SELECT owner,
                                 object_name,
                                 CASE
                                   WHEN o.last_ddl_time - o.CREATED < 30 THEN
                                    ''C''
                                   ELSE
                                    ''A''
                                 END AS ind_alter_type,
                                 o.object_type
                          FROM   dba_objects@' || dblink || ' o
                          WHERE  o.OBJECT_TYPE = ''TABLE''
                          AND    (o.object_name NOT LIKE ''MLOG$%'' AND
                                o.object_name NOT LIKE ''RUPD$%'')
                          AND    o.owner IN
                                 (SELECT c.des_statement
                                   FROM   monitor_adm.remote_ddl_control c
                                   WHERE  c.cod_remote_ddl_control = ''OWNER_GPG_CHECK'')
                          AND    (SYSDATE - o.LAST_DDL_TIME < :dias OR SYSDATE - o.CREATED < 30)
                          AND   remote_dbms_metadata.isTableInBlackList(o.owner, o.object_name)=0
                          ) x
                  WHERE  NOT EXISTS (SELECT 1
                          FROM   dba_objects l
                          WHERE  l.OWNER = x.owner
                          AND    l.OBJECT_NAME = x.object_name
                          AND    l.OBJECT_TYPE = x.object_type
                          AND    ''C'' = x.ind_alter_type)
                           UNION ALL
                          SELECT owner,
                                 object_name,
                                 ''D''
                          FROM   dba_objects o
                          WHERE  o.OBJECT_TYPE = ''TABLE''
                          AND    (o.object_name NOT LIKE ''MLOG$%'' AND
                                o.object_name NOT LIKE ''RUPD$%'')
                          AND    o.owner IN
                                 (SELECT c.des_statement
                                   FROM   monitor_adm.remote_ddl_control c
                                   WHERE  c.cod_remote_ddl_control = ''OWNER_GPG_CHECK'')
                          AND    monitor_adm.remote_dbms_metadata.isTableOkaneExclusive(o.owner,
                                                                                           o.object_name) = 0
                          AND    NOT EXISTS (SELECT 1
                                  FROM   dba_objects@' || dblink || ' l
                                  WHERE  l.OWNER = o.owner
                                  AND    l.OBJECT_NAME = o.object_name
                                  AND    l.OBJECT_TYPE = o.object_type)' || vcOrderByClause
    
      USING vnDays;
  
    FETCH cur_remote BULK COLLECT
      INTO ObjectsArray;
    FOR i IN 1 .. ObjectsArray.count
    LOOP
      DECLARE
        vcObjectDDL CLOB;
        vcHeader    monitor_adm.remote_ddl_control.des_statement%TYPE := REPLACE(REPLACE(get_ControlParameter('OBJECT_HEADER'),
                                                                                         '@OWNER',
                                                                                         ObjectsArray(i)
                                                                                         
                                                                                         .owner),
                                                                                 '@TABLE',
                                                                                 ObjectsArray(i)
                                                                                 .table_name);
      BEGIN
        --+-----------------------------+--
        -- OBJECTOS CRIADOS
        --+-----------------------------+--
        IF ObjectsArray(i).ind_alter_type = 'C' THEN
          vcObjectDDL := get_ddl(db_link     => dblink,
                                 object_type => gcObjectType,
                                 NAME        => ObjectsArray(i).table_name,
                                 SCHEMA      => ObjectsArray(i).owner);
        
          IF vcObjectDDL IS NOT NULL THEN
            -- comentarios
            IF vcComentario = 'S' THEN
              clobComentario := get_Table_Comments(ObjectsArray(i).owner,
                                                   ObjectsArray(i).table_name,
                                                   dblink);
            
              vcObjectDDL := vcObjectDDL || get_whitespace ||
                             clobComentario;
            
            END IF;
          
            -- CASO EXISTA ALTERACÃ£O DE DDL, VALIDA EXISTENCIA DA MVIEW
            vcObjectDDL := get_mview_ddl(ObjectsArray (i).owner,
                                         ObjectsArray (i).table_name,
                                         vcObjectDDL,
                                         dblink,
                                         gcOkaneSource,
                                         ObjectsArray (i).ind_alter_type);
          
            -- OBTEM OS PRIVILEGIOS DA TABELA PARA O HOST DE DESTINO
            vcObjectDDL := get_generic_ddl(ObjectsArray(i).owner,
                                           ObjectsArray(i).table_name,
                                           vcObjectDDL,
                                           'PRIVS');
          
            -- OBTEM OS MLOG DA TABELA PARA O HOST DE ORIGEM
            vcObjectDDL := get_generic_ddl(ObjectsArray(i).owner,
                                           ObjectsArray(i).table_name,
                                           vcObjectDDL,
                                           'MLOG');
          
          END IF;
          --+-----------------------------+--
          -- OBJECTOS ALTERADOS
          --+-----------------------------+--
        ELSIF ObjectsArray(i).ind_alter_type = 'A' THEN
        
          vcObjectDDL := get_alter_ddl(ObjectsArray (i).owner,
                                       ObjectsArray (i).table_name,
                                       dblink,
                                       gcOkaneSource);
        
          IF vcObjectDDL IS NOT NULL THEN
            -- CASO EXISTA ALTERACÃ£O DE DDL, VALIDA EXISTENCIA DA MVIEW
            vcObjectDDL := get_mview_ddl(ObjectsArray (i).owner,
                                         ObjectsArray (i).table_name,
                                         vcObjectDDL,
                                         dblink,
                                         gcOkaneSource,
                                         ObjectsArray (i).ind_alter_type);
          
          END IF;
          --+-----------------------------+--
          -- OBJECTOS DROPADOS DO PAGASEGURO
          --+-----------------------------+--
        ELSIF ObjectsArray(i).ind_alter_type = 'D' THEN
          vcObjectDDL := get_drop_ddl(ObjectsArray (i).owner,
                                      ObjectsArray (i).table_name,
                                      dblink,
                                      gcOkaneSource);
        
          IF vcObjectDDL IS NOT NULL THEN
            -- CASO EXISTA DROP , RETIRA DA MVIEW
            vcObjectDDL := get_mview_ddl(ObjectsArray (i).owner,
                                         ObjectsArray (i).table_name,
                                         vcObjectDDL,
                                         dblink,
                                         gcOkaneSource,
                                         ObjectsArray (i).ind_alter_type);
          
          END IF;
        END IF;
      
        -- ADICIONA O HEADER CASO HAJA ALTERACÃ£O
        IF vcObjectDDL IS NOT NULL THEN
          vcObjectDDL := vcHeader || vcObjectDDL;
        END IF;
      
        vcClobFinal := vcClobFinal || vcObjectDDL || CASE
                       
                         WHEN vcObjectDDL IS NOT NULL THEN
                          get_whitespace
                         ELSE
                          NULL
                       END;
      
      END;
    END LOOP;
  
    RETURN vcClobFinal;
  
  END workflow_OKANE;

  /*--+-------------------------------------------------+--
  |   Send email. This routine should be called.
  |--+-------------------------------------------------+-- */
  PROCEDURE send_ddl_by_email(dblink IN VARCHAR2) IS
  
    vcClob  CLOB;
    vcerror VARCHAR2(256);
  BEGIN
    vcClob := workflow_OKANE(dblink);
  
    IF vcClob IS NOT NULL THEN
      send_email(vcClob, gcOkaneSource);
    END IF;
  
    log('Email sent length: ' || to_char(nvl(length(vcClob), 0)));
    COMMIT;
    purge_log();
  EXCEPTION
    WHEN OTHERS THEN
      vcerror := to_char(SQLERRM);
      log(substr(vcerror || CHR(10) ||
                 to_char(dbms_utility.format_error_backtrace),
                 1,
                 1024),
          'NOK');
    
  END send_ddl_by_email;
BEGIN
  --remove objetos antigos da blacklist
  purge_BlackList();
END remote_dbms_metadata;
/
