@[Link("pq")]
lib LibPQ
    alias Oid = UInt32

    # Option flags for copy_result
    COPYRES_ATTRS = 0x01
    COPYRES_TUPLES = 0x02
    COPYRES_EXENTS = 0x04
    COPYRES_NOTICEHOOKS = 0x08

    enum ConnStatusType
        CONNECTION_OK,
        CONNECTION_BAD,
        # Non-blocking mode only below here

        # The existence of these should never be relied upon - they should only
        # be used for user feedback or similar purposes.
        CONNECTION_STARTED,             # Waiting for connection to be made
        CONNECTION_MADE,                # Connection OK; waiting to send
        CONNECTION_AWAITING_RESPONSE,   # Waiting for a response from the postmaster
        CONNECTION_AUTH_OK,             # Received authentication; waiting for backend startup
        CONNECTION_SETENV,              # Negotiating environment
        CONNECTION_SSL_STARTUP,         # Negociating SSL
        CONNECTION_NEEDED               # Internal state: connect() needed
    end

    enum PollingStatusType
        POLLING_FAILED,
        POLLING_READING,          # These two indicate that one may
        POLLING_WRITING,          # use select before polling again
        POLLING_OK
    end

    enum ExecStatusType
        EMPTY_QUERY,        # empty query string was executed
        COMMAND_OK,         # a query command that doesn't return anything was executed properly by the backend
        TUPLES_OK,          # a query command that returns tuples was executed properly by the backend, PGresult contains the result tuples
        COPY_OUT,           # Copy Out data transfer in progress
        COPY_IN,            # Copy In data transfer in progress
        BAD_RESPONSE,       # an unexpected response was recv'd from the backend
        NONFATAL_ERROR,     # notice or warning message
        FATAL_ERROR,        # query failed
        COPY_BOTH,          # Copy In/Out data transfer in progress
        SINGLE_TUPLE        # single tuple from larger resultset
    end

    enum TransactionStatusType
        IDLE,               # connection idle
        ACTIVE,             # command in progress
        INTRANS,            # idle, within transaction block
        INERROR,            # idle, within failed transaction
        UNKNOWN             # cannot determine status
    end

    enum Verbosity
        ERRORS_TERSE,       # single-line error messages
        ERRORS_DEFAULT,     # recommended style
        ERRORS_VERBOSE,     # all the facts, ma'am
    end

    enum ContextVisibility
        SHOW_CONTEXT_NEVER,     # never show CONTEXT field
        SHOW_CONTEXT_ERRORS,    # show CONTEXT for errors only (default)
        SHOW_CONTEXT_ALWAYS     # always show CONTEXT field
    end

    enum Ping
        OK,                 # server is accepting connections
        REJECT,             # server is alive but rejecting connections
        NO_RESPONSE,        # could not establish connection
        NO_ATTEMPT          # connection not attempted (bad params)
    end

    # Conn encapsulates a connection to the backend
    # The contents of this struct are not supposed to be known to applications
    type Conn = Void

    # Result encapsulates the result of a query (or more precisely, of a single
    # SQL command --- a query string given to PGsendQuery can contain multiple
    # commands and thus return multiple PGresult objects).
    # The contents of this struct are not supposed to be known to applications
    type Result = Void

    # Cancel encapsulates the information needed to cancel a running
    # query on an existing connection.
    # The contents of this struct are not supposed to be known to applications
    type Cancel = Void

    struct Notify
        relname : LibC::Char*
        be_pid : Int32
        extra : LibC::Char*
    end

    type NoticeReceiver = Proc(Void*, Result, Void)
    type NoticeProcessor = Proc(Void*, LibC::Char*, Void)

    struct PrintOpt
        header : Bool
        align : Bool
        standard : Bool
        html3 : Bool
        expanded : Bool
        pager : Bool
        fieldSep : LibC::Char*
        tableOpt : LibC::Char*
        caption : LibC::Char*
        fieldName : LibC::Char**
    end

    struct ConnInfoOption
        keyword : LibC::Char*
        envvar : LibC::Char*
        compiled : LibC::Char*
        val : LibC::Char*
        label : LibC::Char*
        dispchar : LibC::Char*
        dispsize : Int32
    end

    union ArgBlockU
        ptr : Void*
        integer : Int32
    end
    struct ArgBlock
        len : Int32
        isint : Int32
        u : ArgBlockU
    end

    struct ResAttDesc
        name : LibC::Char*
        tableid : Oid
        columnid : Int32
        format : Int32
        typid : Oid
        typlen : Int32
        atttypmod : Int32
    end

    # Make a new client connection to the backend
    # - Asynchronous
    fun connect_start = PQconnectStart(conninfo : LibC::Char*) : Conn*
    fun connect_start_params = PQconnectStartParams(keywords : LibC::Char**, values : LibC::Char**, expand_dbname : Int32)
    fun connect_poll = PQconnectPoll(conn : Conn*) : PollingStatusType

    # - Synchronous
    fun connect_db = PQconnectdb(conninfo : LibC::Char*) : Conn*
    fun connect_db_params = PQconnectdbParams(keywords : LibC::Char**, values : LibC::Char**, expand_dbname : Int32) : Conn*
    fun set_db_login = PQsetdbLogin(pghost : LibC::Char*, pgport : LibC::Char*, pgoptions : LibC::Char*, pgtty : LibC::Char*, dbname : LibC::Char*, login : LibC::Char*, pwd : LibC::Char*) : Conn*

    # Close the current connection and free the Conn data structure
    fun finish = PQfinish(conn : Conn*)

    # Get info about connection options known to connect_db
    fun conn_defaults = PQconndefaults() : ConnInfoOption*
    # Parse connection options in same way as connect_db
    fun conn_info_parse = PQconninfoParse(conninfo : LibC::Char*, errmsg : LibC::Char**) : ConnInfoOption*
    # Return the connection options used by a live connection
    fun conn_info = PQconninfo(conn : Conn*) : ConnInfoOption*
    # Free the data structure returned by conn_defaults or conn_info_parse
    fun conn_info_free = PQconninfoFree(ConnInfoOption*)
    
    # Close the current connection and restablish a new one with the same parameters
    # - Asynchronous
    fun reset_start = PQresetStart(conn : Conn*) : Int32
    fun reset_poll = PQresetPoll(conn : Conn*) : PollingStatusType

    # - Synchronous
    fun reset = PQreset(conn : Conn*)

    # Request a cancel structure
    fun get_cancel = PQgetCancel(conn : Conn*) : Cancel*

    # Free a cancel structure
    fun free_cancel = PQfreeCancel(cancel : Cancel*)

    # Issue a cancel request
    fun cancel = PQcancel(cancel : Cancel*, errbuf : LibC::Char*, errbufsize : Int32) : Int32

    # Accessor functions for Conn objects
    fun db = PQdb(conn : Conn*) : LibC::Char*
    fun user = PQuser(conn : Conn*) : LibC::Char*
    fun pass = PQpass(conn : Conn*) : LibC::Char*
    fun host = PQhost(conn : Conn*) : LibC::Char*
    fun port = PQport(conn : Conn*) : LibC::Char*
    fun tty = PQtty(conn : Conn*) : LibC::Char*
    fun options = PQoptions(conn : Conn*) : LibC::Char*
    fun status = PQstatus(conn : Conn*) : ConnStatusType
    fun transaction_status = PQtransactionStatus(conn : Conn*, param : LibC::Char*) : LibC::Char*
    fun parameter_status = PQparameterStatus(conn : Conn*, paramName : LibC::Char*) : LibC::Char*
    fun protocol_version = PQprotocolVersion(conn : Conn*) : Int32
    fun server_version = PQserverVersion(conn : Conn*) : Int32
    fun error_message = PQerrorMessage(conn : Conn*) : LibC::Char*
    fun socket = PQsocket(conn : Conn*) : Int32
    fun backend_pid = PQbackendPID(conn : Conn*) : Int32
    fun connection_needs_password = PQconnectionNeedsPassword(conn : Conn*) : Int32
    fun connection_used_password = PQconnectionUsedPassword(conn : Conn*) : Int32
    fun client_encoding = PQclientEncoding(conn : Conn*) : Int32
    fun set_client_encoding = PQsetClientEncoding(conn : Conn*, encoding : LibC::Char*) : Int32

    # SSL information functions
    fun ssl_in_use = PQsslInUse(conn : Conn*) : Int32
    fun ssl_struct = PQsslStruct(conn : Conn*, struct_name : LibC::Char*) : Void*
    fun ssl_attributes = PQsslAttribute(conn : Conn*, attribute_name : LibC::Char*) : LibC::Char*
    fun ssl_attributes = PQsslAttributeNames(conn : Conn*) : LibC::Char**

    # Get the OpenSSL structure associated with a connection. Returns NULL for unencrypted connections or if any other TLS library is in use.
    fun get_ssl = PQgetssl(conn : Conn*) : Void*

    # Tell libpq whether it needs to initialize OpenSSL
    fun init_ssl = PQinitSSL(do_init : Int32)

    # More detailed way to tell libpq whether it needs to initialize OpenSSL
    fun init_open_ssl = PQinitOpenSSL(do_ssl : Int32, do_crypto : Int32)

    # Set verbosity for error_message and result_error_message
    fun set_error_verbosity = PQsetErrorVerbosity(conn : Conn*, verbosity : Verbosity) : Verbosity

    # Set CONTEXT visibility for error_message and result_error_message
    fun set_error_context_visibility = PQsetErrorContextVisibility(conn : Conn*, show_context : ContextVisibility) : ContextVisibility

    # Enable/disable tracing
    #fun trace = PQtrace(conn : Conn*, debug_port : LibC::File*) # TODO: find a FILE* equivalent
    fun untrace = PQuntrace(conn : Conn*)

    # Override default notice handling routines
    fun set_notice_receiver = PQsetNoticeReceiver(conn : Conn*, proc : NoticeReceiver, arg : Void*) : NoticeReceiver
    fun set_notice_processor = PQsetNoticeProcessor(conn : Conn*, proc : NoticeProcessor, arg : Void*) : NoticeProcessor

    # Used to set callback that prevents concurrent access to non-thread safe functions that libpq needs.
    # The default implementation uses a libpq internal mutex. Only required for multithreaded apps that
    # use kerberos both within their app and for postgresql connections.
    alias ThreadLock = Proc(Int32, Void)
    fun register_thread_lock = PQregisterThreadLock(newhandler : ThreadLock) : ThreadLock

    # Simple synchronous query
    fun exec = PQexec(conn : Conn*, query : LibC::Char*) : Result*
    fun exec_params = PQexecParams(conn : Conn*, command : LibC::Char*, nparams : Int32,
                                   paramTypes : Oid*, paramValues : LibC::Char**,
                                   paramLengths : Int32*, paramFormats : Int32*,
                                   resultFormat : Int32) : Result*
    fun prepare = PQprepare(conn : Conn*, stmtName : LibC::Char*, query : LibC::Char*,
                            nparams : Int32, param_types : Oid*) : Result*
    fun exec_prepared = PQexecPrepared(conn : Conn*, stmtName : LibC::Char*, nparams : Int32,
                                       paramValues : LibC::Char**, paramLengths : Int32*,
                                       paramFormats : Int32*, resultFormat : Int32) : Result*
    
    # Interface for multiple-result or asynchronous queries
    fun send_query = PQsendQuery(conn : Conn*, query : LibC::Char*) : Int32
    fun send_query_params = PQsendQueryParams(conn : Conn*, command : LibC::Char*,
                                              nparams : Int32, paramTypes : Oid*,
                                              paramValues : LibC::Char**,
                                              paramLengths : Int32*,
                                              paramFormats : Int32*,
                                              resultFormat : Int32) : Int32
    fun send_prepare = PQsendPrepare(conn : Conn*, stmtName : LibC::Char*, query : LibC::Char*,
                                     nparams : Int32, param_types : Oid*) : Int32
    fun send_query_prepared = PQsendQueryPrepared(conn : Conn*, stmtName : LibC::Char*,
                                                 nparams : Int32, paramValues : LibC::Char**,
                                                 paramLengths : Int32*, paramFormats : Int32*,
                                                 resultFormat : Int32) : Int32
    fun set_single_row_mode = PQsetSingleRowMode(conn : Conn*) : Int32
    fun get_result = PQgetResult(conn : Conn*) : Result*

    # Routines for managing an asynchronous query
    fun is_busy = PQisBusy(conn : Conn*) : Int32
    fun consume_input = PQconsumeInput(conn : Conn*) : Int32

    # LISTEN/NOTIFY support
    fun notifies = PQnotifies(conn : Conn*) : Notify*

    # Routines for copy in/out
    fun putCopyData = PQputCopyData(conn : Conn*, buffer : LibC::Char*, nbytes : Int32) : Int32
    fun putCopyEnd = PQputCopyEnd(conn : Conn*, error : LibC::Char*) : Int32
    fun getCopyData = PQgetCopyData(conn : Conn*, buffer : LibC::Char**, async : Int32) : Int32

    # Set blocking/nonblocking connection to the backend
    fun set_non_blocking = PQsetnonblocking(conn : Conn*, arg : Int32) : Int32
    fun is_non_blocking = PQisnonblocking(conn : Conn*) : Int32
    fun is_thread_safe = PQisthreadsafe() : Int32
    fun ping = PQping(conninfo : LibC::Char*) : Ping
    fun pingParams = PQpingParams(keywords : LibC::Char**, values : LibC::Char**, expand_dbname : Int32) : Ping

    # Force the write buffer to be written (or at least try)
    fun flush = PQflush(conn : Conn*) : Int32

    # "Fast path" interface --- not really recommended for application use
    fun fn = PQfn(conn : Conn*, fnid : Int32, result_buf : Int32*, result_len : Int32*, result_is_int : Int32,
                  args : ArgBlock*, nargs : Int32)
    
    # Accessor functions for Result objects
    fun result_status = PQresultStatus(res : Result*) : ExecStatusType
    fun res_status = PQresStatus(status : ExecStatusType) : LibC::Char*
    fun result_error_message = PQresultErrorMessage(res : Result*) : LibC::Char*
    fun result_verbose_error_message = PQresultVerboseErrorMessage(res : Result*,
                                            verbosity : Verbosity,
                                            show_context : ContextVisibility) : LibC::Char*
    fun result_error_field = PQresultErrorField(res : Result*, fieldcode : Int32) : LibC::Char*
    fun ntuples = PQntuples(res : Result*) : Int32
    fun nfields = PQnfields(res : Result*) : Int32
    fun nbinaryTuples = PQnbinaryTuples(res : Result*) : Int32
    fun fname = PQfname(res : Result*, field_num : Int32) : LibC::Char*
    fun fnumber = PQfnumber(res : Result*, field_name : LibC::Char*) : Int32
    fun ftable = PQftable(res : Result*, field_num : Int32) : Oid
    fun ftablecol = PQftablecol(res : Result*, field_num : Int32) : Int32
    fun fformat = PQfformat(res : Result*, field_num : Int32) : Int32
    fun ftype = PQftype(res : Result*, field_num : Int32) : Oid
    fun fsize = PQfsize(res : Result*, field_num : Int32) : Int32
    fun fmod = PQfmod(res : Result*, field_num : Int32) : Int32
    fun cmd_status = PQcmdStatus(res : Result*, field_num : Int32) : LibC::Char*
    fun oid_value = PQoidValue(res : Result*) : Oid
    fun cmd_tuples = PQcmdTuples(res : Result*) : LibC::Char*
    fun get_value = PQgetvalue(res : Result*, tup_num : Int32, field_num : Int32) : LibC::Char*
    fun get_length = PQgetlength(res : Result*, tup_num : Int32, field_num : Int32) : Int32
    fun get_is_null = PQgetisnull(res : Result*, tup_num : Int32, field_num : Int32) : Int32
    fun nparams = PQnparams(res : Result*) : Int32
    fun param_type = PQparamtype(res : Result*, param_num : Int32) : Oid

    # Describe prepared statements and portals
    fun describe_prepared = PQdescribePrepared(conn : Conn*, stmt : LibC::Char*) : Result*
    fun describe_portal = PQdescribePortal(conn : Conn*, portal : LibC::Char*) : Result*
    fun send_describe_prepared = PQsendDescribePrepared(conn : Conn*, stmt : LibC::Char*) : Int32
    fun send_describe_portal = PQsendDescribePortal(conn : Conn*, portal : LibC::Char*) : Int32

    # Delete a Result
    fun clear = PQclear(res : Result*)

    # For freeing other alloc'd results, such as Notify structs
    fun free_mem = PQfreemem(res : Void*)

    # Create and manipulate Results
    fun make_empty_result = PQmakeEmptyPGresult(conn : Conn*, status : ExecStatusType) : Result*
    fun copy_result = PQcopyResult(conn : Conn*, flags : Int32) : Result*
    fun set_result_attrs = PQsetResultAttrs(res : Result*, numAttributes : Int32, attDescs : ResAttDesc*) : Int32
    fun result_alloc = PQresultAlloc(res : Result*, nbytes : LibC::SizeT) : Void*
    fun set_value = PQsetvalue(res : Result*, tup_num : Int32, field_num : Int32, value : LibC::Char*, len : Int32) : Int32

    # Quoting strings before inclusion in queries
    fun escape_string_conn = PQescapeStringConn(conn : Conn*, to : LibC::Char*, from : LibC::Char*, length : LibC::SizeT, error : Int32*) : LibC::SizeT
    fun escape_literal = PQescapeLiteral(conn : Conn*, str : LibC::Char*, len : LibC::SizeT) : LibC::Char*
    fun escape_identifier = PQescapeIdentifier(conn : Conn*, str : LibC::Char*, len : LibC::SizeT) : LibC::Char*
    fun escape_bytea_conn(conn : Conn*, from : LibC::Char*, from_length : LibC::SizeT, to_length : LibC::SizeT) : UInt8*
    fun unescape_bytea_conn(strtext : LibC::Char*, retbuflen : LibC::SizeT*) : UInt8*

    #fun print = PQprint(fout : LibC::FILE*, res : Result*, ps : PrintOpt*) # TODO: find a FILE* equivalent

    # Large-object access routines
    fun lo_open(conn : Conn*, lobjid : Oid, mode : Int32) : Int32
    fun lo_close(conn : Conn*, fd : Int32) : Int32
    fun lo_read(conn : Conn*, fd : Int32, buf : LibC::Char*, len : LibC::SizeT) : Int32
    fun lo_write(conn : Conn*, fd : Int32, buf : LibC::Char*, len : LibC::SizeT) : Int32
    fun lo_lseek(conn : Conn*, fd : Int32, offset : Int32, whence : Int32) : Int32
    fun lo_lseek64(conn : Conn*, fd : Int32, offset : Int64, whence : Int32) : Int64
    fun lo_creat(conn : Conn*, mode : Int32) : Oid
    fun lo_create(conn : Conn*, lobjid : Oid) : Oid
    fun lo_tell(conn : Conn*, fd : Int32) : Int32
    fun lo_tell64(conn : Conn*, fd : Int32) : Int64
    fun lo_truncate(conn : Conn*, fd : Int32, len : LibC::SizeT) : Int32
    fun lo_truncate64(conn : Conn*, fd : Int32, len : LibC::SizeT) : Int64
    fun lo_unlink(conn : Conn*, lobjid : Oid) : Int32
    fun lo_import(conn : Conn*, filename : LibC::Char*) : Oid
    fun lo_import_with_oid(conn : Conn*, filename : LibC::Char*, lobjid : Oid) : Oid
    fun lo_export(conn : Conn*, lobjid : Oid, filename : LibC::Char*) : Int32

    # Get the version of the libpq library in use
    fun lib_version = PQlibVersion() : Int32

    # Determine length of multibyte encoded char at *s
    fun mblen = PQmblen(s : LibC::Char*, encoding : Int32) : Int32

    # Determine display length of multibyte encoded char at *s
    fun dsplen = PQdsplen(s : LibC::Char*, encoding : Int32) : Int32

    # Get encoding id from environment variable PGCLIENTENCODING
    fun env2encoding = PQenv2encoding() : Int32

    fun encrypt_password = PQencryptPassword(passwd : LibC::Char*, user : LibC::Char*) : LibC::Char*

    fun char_to_encoding = pg_char_to_encoding(name : LibC::Char*) : Int32
    fun encoding_to_char = pg_encoding_to_char(encoding : Int32) : LibC::Char*
    fun valid_server_encoding_id = pg_valid_server_encoding_id(encoding : Int32) : Int32
end
