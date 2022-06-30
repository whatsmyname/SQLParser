/*
MySQL (Positive Technologies) grammar
The MIT License (MIT).
Copyright (c) 2015-2017, Ivan Kochurkin (kvanttt@gmail.com), Positive Technologies.
Copyright (c) 2017, Ivan Khudyashev (IHudyashov@ptsecurity.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

grammar SQL;

options { caseInsensitive = true; }



// Top Level Description

root
    : sqlStatements? (MINUS MINUS)? EOF
    ;

sqlStatements
    : (sqlStatement (MINUS MINUS)? SEMI? | emptyStatement_)*
    (sqlStatement ((MINUS MINUS)? SEMI)? | emptyStatement_)
    ;

sqlStatement
    : ddlStatement | dmlStatement | transactionStatement
    | replicationStatement | preparedStatement
    | administrationStatement | utilityStatement
    ;

emptyStatement_
    : SEMI
    ;

ddlStatement
    : createDatabase | createEvent | createIndex
    | createLogfileGroup | createProcedure | createFunction
    | createServer | createTable | createTablespaceInnodb
    | createTablespaceNdb | createTrigger | createView
    | alterDatabase | alterEvent | alterFunction
    | alterInstance | alterLogfileGroup | alterProcedure
    | alterServer | alterTable | alterTablespace | alterView
    | dropDatabase | dropEvent | dropIndex
    | dropLogfileGroup | dropProcedure | dropFunction
    | dropServer | dropTable | dropTablespace
    | dropTrigger | dropView
    | renameTable | truncateTable
    ;

dmlStatement  // refined
    : withClause?
    (
        selectStatement
        | insertStatement | updateStatement
        | deleteStatement
    )
    | (
        replaceStatement | callStatement
        | loadDataStatement | loadXmlStatement | doStatement
        | handlerStatement | valuesStatement //| fromStatement
    )
    ;

transactionStatement
    : startTransaction
    | beginWork | commitWork | rollbackWork
    | savepointStatement | rollbackStatement
    | releaseStatement | lockTables | unlockTables
    ;

replicationStatement
    : changeMaster | changeReplicationFilter | purgeBinaryLogs
    | resetMaster | resetSlave | startSlave | stopSlave
    | startGroupReplication | stopGroupReplication
    | xaStartTransaction | xaEndTransaction | xaPrepareStatement
    | xaCommitWork | xaRollbackWork | xaRecoverWork
    ;

preparedStatement
    : prepareStatement | executeStatement | deallocatePrepare
    ;

// remark: NOT INCLUDED IN sqlStatement, but include in body
//  of routine's statements
compoundStatement
    : blockStatement
    | caseStatement | ifStatement | leaveStatement
    | loopStatement | repeatStatement | whileStatement
    | iterateStatement | returnStatement | cursorStatement
    ;

administrationStatement
    : alterUser | createUser | dropUser | grantStatement
    | grantProxy | renameUser | revokeStatement
    | revokeProxy | analyzeTable | checkTable
    | checksumTable | optimizeTable | repairTable
    | createUdfunction | installPlugin | uninstallPlugin
    | setStatement | showStatement | binlogStatement
    | cacheIndexStatement | flushStatement | killStatement
    | loadIndexIntoCache | resetStatement
    | shutdownStatement
    ;

utilityStatement
    : simpleDescribeStatement | fullDescribeStatement
    | helpStatement | useStatement | signalStatement
    | resignalStatement | diagnosticsStatement
    ;


// Data Definition Language

//    Create statements

createDatabase
    : CREATE dbFormat=(DATABASE | SCHEMA)
      ifNotExists? uid createDatabaseOption*
    ;

createEvent
    : CREATE ownerStatement? EVENT ifNotExists? fullId
      ON SCHEDULE scheduleExpression
      (ON COMPLETION NOT? PRESERVE)? enableType?
      (COMMENT STRING_LITERAL)?
      DO routineBody
    ;

createIndex
    : CREATE (OR REPLACE)?                                        // OR is MariaDB-specific only
      intimeAction=(ONLINE | OFFLINE)?
      indexCategory=(UNIQUE | FULLTEXT | SPATIAL)? INDEX
      (IF NOT EXISTS)?                                            // MariaDB-specific only
      uid indexType?
      ON tableName indexColumnNames
      (WAIT decimalLiteral | NOWAIT)?                             // MariaDB-specific only
      indexOption*
      (
        ALGORITHM EQUAL_SYMBOL? algType=(DEFAULT | INPLACE | COPY | NOCOPY | INSTANT)  // NOCOPY, INSTANT are MariaDB-specific only
        | LOCK EQUAL_SYMBOL? lockType=(DEFAULT | NONE | SHARED | EXCLUSIVE)
      )*
    ;

createLogfileGroup
    : CREATE LOGFILE GROUP uid
      ADD UNDOFILE undoFile=STRING_LITERAL
      (INITIAL_SIZE '='? initSize=fileSizeLiteral)?
      (UNDO_BUFFER_SIZE '='? undoSize=fileSizeLiteral)?
      (REDO_BUFFER_SIZE '='? redoSize=fileSizeLiteral)?
      (NODEGROUP '='? uid)?
      WAIT?
      (COMMENT '='? comment=STRING_LITERAL)?
      ENGINE '='? engineName
    ;

createProcedure
    : CREATE ownerStatement?
    PROCEDURE fullId
      '(' procedureParameter? (',' procedureParameter)* ')'
      routineOption*
    routineBody
    ;

createFunction
    : CREATE ownerStatement?
    FUNCTION fullId
      '(' functionParameter? (',' functionParameter)* ')'
      RETURNS dataType
      routineOption*
    (routineBody | returnStatement)
    ;

createServer
    : CREATE SERVER uid
    FOREIGN DATA WRAPPER wrapperName=(MYSQL | STRING_LITERAL)
    OPTIONS '(' serverOption (',' serverOption)* ')'
    ;

createTable
    : CREATE (OR REPLACE)? TEMPORARY? TABLE ifNotExists?
       tableName
       (
         LIKE tableName
         | '(' LIKE parenthesisTable=tableName ')'
       )                                                            #copyCreateTable
    | CREATE (OR REPLACE)? TEMPORARY? TABLE ifNotExists?
       tableName createDefinitions?
       ( tableOption (','? tableOption)* )?
       partitionDefinitions? keyViolate=(IGNORE | REPLACE)?
       AS? selectStatement                                          #queryCreateTable
    | CREATE (OR REPLACE)? TEMPORARY? TABLE ifNotExists?
       tableName createDefinitions
       ( tableOption (','? tableOption)* )?
       partitionDefinitions?                                        #columnCreateTable
    ;

createTablespaceInnodb
    : CREATE TABLESPACE uid
      ADD DATAFILE datafile=STRING_LITERAL
      (FILE_BLOCK_SIZE '=' fileBlockSize=fileSizeLiteral)?
      (ENGINE '='? engineName)?
    ;

createTablespaceNdb
    : CREATE TABLESPACE uid
      ADD DATAFILE datafile=STRING_LITERAL
      USE LOGFILE GROUP uid
      (EXTENT_SIZE '='? extentSize=fileSizeLiteral)?
      (INITIAL_SIZE '='? initialSize=fileSizeLiteral)?
      (AUTOEXTEND_SIZE '='? autoextendSize=fileSizeLiteral)?
      (MAX_SIZE '='? maxSize=fileSizeLiteral)?
      (NODEGROUP '='? uid)?
      WAIT?
      (COMMENT '='? comment=STRING_LITERAL)?
      ENGINE '='? engineName
    ;

createTrigger
    : CREATE (OR REPLACE)? ownerStatement?  // OR is MariaDB-specific only
      TRIGGER thisTrigger=fullId
      triggerTime=(BEFORE | AFTER)
      triggerEvent=(INSERT | UPDATE | DELETE)
      ON tableName FOR EACH ROW
      (triggerPlace=(FOLLOWS | PRECEDES) otherTrigger=fullId)?
      routineBody
    ;

withClause
    : WITH RECURSIVE? commonTableExpressions
    ;

commonTableExpressions
    : cteName ('(' cteColumnName (',' cteColumnName)* ')')?
      AS '(' (
                dmlStatement
                | '(' dmlStatement ')' orderByClause? limitClause?
             )
         ')'
      (',' commonTableExpressions)?
    ;

cteName
    : uid
    ;

cteColumnName
    : uid
    ;

createView
    : CREATE (OR REPLACE)?
      (
        ALGORITHM '=' algType=(UNDEFINED | MERGE | TEMPTABLE)
      )?
      ownerStatement?
      (SQL SECURITY secContext=(DEFINER | INVOKER))?
      VIEW fullId ('(' uidList ')')? AS withClause? selectStatement
      (WITH checkOption=(CASCADED | LOCAL)? CHECK OPTION)?
    ;

// details

createDatabaseOption
    : DEFAULT? charSet '='? (charsetName | DEFAULT)
    | DEFAULT? COLLATE '='? collationName
    ;

charSet
    : CHARACTER SET
    | CHARSET
    | CHAR SET
    ;

ownerStatement
    : DEFINER '=' (userName | CURRENT_USER ( '(' ')')?)
    ;

scheduleExpression
    : AT timestampValue intervalExpr*                               #preciseSchedule
    | EVERY (decimalLiteral | expression) intervalType
        (
          STARTS startTimestamp=timestampValue
          (startIntervals+=intervalExpr)*
        )?
        (
          ENDS endTimestamp=timestampValue
          (endIntervals+=intervalExpr)*
        )?                                                          #intervalSchedule
    ;

timestampValue
    : CURRENT_TIMESTAMP
    | stringLiteral
    | decimalLiteral
    | expression
    ;

intervalExpr
    : '+' INTERVAL (decimalLiteral | expression) intervalType
    ;

intervalType
    : intervalTypeBase
    | YEAR | YEAR_MONTH | DAY_HOUR | DAY_MINUTE
    | DAY_SECOND | HOUR_MINUTE | HOUR_SECOND | MINUTE_SECOND
    | SECOND_MICROSECOND | MINUTE_MICROSECOND
    | HOUR_MICROSECOND | DAY_MICROSECOND
    | EPOCH // refined
    ;

enableType
    : ENABLE | DISABLE | DISABLE ON SLAVE
    ;

indexType
    : USING (BTREE | HASH | RTREE)  // RTREE is MariaDB-specific only
    ;

indexOption
    : KEY_BLOCK_SIZE EQUAL_SYMBOL? fileSizeLiteral
    | indexType
    | WITH PARSER uid
    | COMMENT STRING_LITERAL
    | (VISIBLE | INVISIBLE)
    | ENGINE_ATTRIBUTE EQUAL_SYMBOL? STRING_LITERAL
    | SECONDARY_ENGINE_ATTRIBUTE EQUAL_SYMBOL? STRING_LITERAL
    | CLUSTERING EQUAL_SYMBOL (YES | NO)                       // MariaDB-specific only
    | (IGNORED | NOT IGNORED)                                  // MariaDB-specific only
    ;

procedureParameter
    : direction=(IN | OUT | INOUT)? uid dataType
    ;

functionParameter
    : uid dataType
    ;

routineOption
    : COMMENT STRING_LITERAL                                        #routineComment
    | LANGUAGE SQL                                                  #routineLanguage
    | NOT? DETERMINISTIC                                            #routineBehavior
    | (
        CONTAINS SQL | NO SQL | READS SQL DATA
        | MODIFIES SQL DATA
      )                                                             #routineData
    | SQL SECURITY context=(DEFINER | INVOKER)                      #routineSecurity
    ;

serverOption
    : HOST STRING_LITERAL
    | DATABASE STRING_LITERAL
    | USER STRING_LITERAL
    | PASSWORD STRING_LITERAL
    | SOCKET STRING_LITERAL
    | OWNER STRING_LITERAL
    | PORT decimalLiteral
    ;

createDefinitions
    : '(' createDefinition (',' createDefinition)* ')'
    ;

createDefinition
    : uid columnDefinition                                          #columnDeclaration
    | tableConstraint                                               #constraintDeclaration
    | indexColumnDefinition                                         #indexDeclaration
    ;

columnDefinition
    : dataType columnConstraint*
    ;

columnConstraint
    : nullNotnull                                                   #nullColumnConstraint
    | DEFAULT defaultValue                                          #defaultColumnConstraint
    | VISIBLE                                                       #visibilityColumnConstraint
    | INVISIBLE                                                     #visibilityColumnConstraint
    | (AUTO_INCREMENT | ON UPDATE currentTimestamp)                 #autoIncrementColumnConstraint
    | PRIMARY? KEY                                                  #primaryKeyColumnConstraint
    | UNIQUE KEY?                                                   #uniqueKeyColumnConstraint
    | COMMENT STRING_LITERAL                                        #commentColumnConstraint
    | COLUMN_FORMAT colformat=(FIXED | DYNAMIC | DEFAULT)           #formatColumnConstraint
    | STORAGE storageval=(DISK | MEMORY | DEFAULT)                  #storageColumnConstraint
    | referenceDefinition                                           #referenceColumnConstraint
    | COLLATE collationName                                         #collateColumnConstraint
    | (GENERATED ALWAYS)? AS '(' expression ')' (VIRTUAL | STORED)? #generatedColumnConstraint
    | SERIAL DEFAULT VALUE                                          #serialDefaultColumnConstraint
    | (CONSTRAINT name=uid?)?
      CHECK '(' expression ')'                                      #checkColumnConstraint
    ;

tableConstraint
    : (CONSTRAINT name=uid?)?
      PRIMARY KEY index=uid? indexType?
      indexColumnNames indexOption*                                 #primaryKeyTableConstraint
    | (CONSTRAINT name=uid?)?
      UNIQUE indexFormat=(INDEX | KEY)? index=uid?
      indexType? indexColumnNames indexOption*                      #uniqueKeyTableConstraint
    | (CONSTRAINT name=uid?)?
      FOREIGN KEY index=uid? indexColumnNames
      referenceDefinition                                           #foreignKeyTableConstraint
    | (CONSTRAINT name=uid?)?
      CHECK '(' expression ')'                                      #checkTableConstraint
    ;

referenceDefinition
    : REFERENCES tableName indexColumnNames?
      (MATCH matchType=(FULL | PARTIAL | SIMPLE))?
      referenceAction?
    ;

referenceAction
    : ON DELETE onDelete=referenceControlType
      (
        ON UPDATE onUpdate=referenceControlType
      )?
    | ON UPDATE onUpdate=referenceControlType
      (
        ON DELETE onDelete=referenceControlType
      )?
    ;

referenceControlType
    : RESTRICT | CASCADE | SET NULL_LITERAL | NO ACTION
    ;

indexColumnDefinition
    : indexFormat=(INDEX | KEY) uid? indexType?
      indexColumnNames indexOption*                                 #simpleIndexDeclaration
    | (FULLTEXT | SPATIAL)
      indexFormat=(INDEX | KEY)? uid?
      indexColumnNames indexOption*                                 #specialIndexDeclaration
    ;

tableOption
    : ENGINE '='? engineName?                                                       #tableOptionEngine
    | AUTO_INCREMENT '='? decimalLiteral                                            #tableOptionAutoIncrement
    | AVG_ROW_LENGTH '='? decimalLiteral                                            #tableOptionAverage
    | DEFAULT? charSet '='? (charsetName|DEFAULT)                                   #tableOptionCharset
    | (CHECKSUM | PAGE_CHECKSUM) '='? boolValue=('0' | '1')                         #tableOptionChecksum
    | DEFAULT? COLLATE '='? collationName                                           #tableOptionCollate
    | COMMENT '='? STRING_LITERAL                                                   #tableOptionComment
    | COMPRESSION '='? (STRING_LITERAL | ID)                                        #tableOptionCompression
    | CONNECTION '='? STRING_LITERAL                                                #tableOptionConnection
    | DATA DIRECTORY '='? STRING_LITERAL                                            #tableOptionDataDirectory
    | DELAY_KEY_WRITE '='? boolValue=('0' | '1')                                    #tableOptionDelay
    | ENCRYPTION '='? STRING_LITERAL                                                #tableOptionEncryption
    | INDEX DIRECTORY '='? STRING_LITERAL                                           #tableOptionIndexDirectory
    | INSERT_METHOD '='? insertMethod=(NO | FIRST | LAST)                           #tableOptionInsertMethod
    | KEY_BLOCK_SIZE '='? fileSizeLiteral                                           #tableOptionKeyBlockSize
    | MAX_ROWS '='? decimalLiteral                                                  #tableOptionMaxRows
    | MIN_ROWS '='? decimalLiteral                                                  #tableOptionMinRows
    | PACK_KEYS '='? extBoolValue=('0' | '1' | DEFAULT)                             #tableOptionPackKeys
    | PASSWORD '='? STRING_LITERAL                                                  #tableOptionPassword
    | ROW_FORMAT '='?
        rowFormat=(
          DEFAULT | DYNAMIC | FIXED | COMPRESSED
          | REDUNDANT | COMPACT | ID
        )                                                                           #tableOptionRowFormat
    | STATS_AUTO_RECALC '='? extBoolValue=(DEFAULT | '0' | '1')                     #tableOptionRecalculation
    | STATS_PERSISTENT '='? extBoolValue=(DEFAULT | '0' | '1')                      #tableOptionPersistent
    | STATS_SAMPLE_PAGES '='? decimalLiteral                                        #tableOptionSamplePage
    | TABLESPACE uid tablespaceStorage?                                             #tableOptionTablespace
    | TABLE_TYPE '=' tableType                                                      #tableOptionTableType
    | tablespaceStorage                                                             #tableOptionTablespace
    | UNION '='? '(' tables ')'                                                     #tableOptionUnion
    ;

tableType
    : MYSQL | ODBC
    ;

tablespaceStorage
    : STORAGE (DISK | MEMORY | DEFAULT)
    ;

partitionDefinitions
    : PARTITION BY partitionFunctionDefinition
      (PARTITIONS count=decimalLiteral)?
      (
        SUBPARTITION BY subpartitionFunctionDefinition
        (SUBPARTITIONS subCount=decimalLiteral)?
      )?
    ('(' partitionDefinition (',' partitionDefinition)* ')')?
    ;

partitionFunctionDefinition
    : LINEAR? HASH '(' expression ')'                               #partitionFunctionHash
    | LINEAR? KEY (ALGORITHM '=' algType=('1' | '2'))?
      '(' uidList ')'                                               #partitionFunctionKey
    | RANGE ( '(' expression ')' | COLUMNS '(' uidList ')' )        #partitionFunctionRange
    | LIST ( '(' expression ')' | COLUMNS '(' uidList ')' )         #partitionFunctionList
    ;

subpartitionFunctionDefinition
    : LINEAR? HASH '(' expression ')'                               #subPartitionFunctionHash
    | LINEAR? KEY (ALGORITHM '=' algType=('1' | '2'))?
      '(' uidList ')'                                               #subPartitionFunctionKey
    ;

partitionDefinition
    : PARTITION uid VALUES LESS THAN
      '('
          partitionDefinerAtom (',' partitionDefinerAtom)*
      ')'
      partitionOption*
      ( '(' subpartitionDefinition (',' subpartitionDefinition)* ')' )?       #partitionComparison
    | PARTITION uid VALUES LESS THAN
      partitionDefinerAtom partitionOption*
      ( '(' subpartitionDefinition (',' subpartitionDefinition)* ')' )?       #partitionComparison
    | PARTITION uid VALUES IN
      '('
          partitionDefinerAtom (',' partitionDefinerAtom)*
      ')'
      partitionOption*
      ( '(' subpartitionDefinition (',' subpartitionDefinition)* ')' )?       #partitionListAtom
    | PARTITION uid VALUES IN
      '('
          partitionDefinerVector (',' partitionDefinerVector)*
      ')'
      partitionOption*
      ( '(' subpartitionDefinition (',' subpartitionDefinition)* ')' )?       #partitionListVector
    | PARTITION uid partitionOption*
      ( '(' subpartitionDefinition (',' subpartitionDefinition)* ')' )?       #partitionSimple
    ;

partitionDefinerAtom
    : constant | expression | MAXVALUE
    ;

partitionDefinerVector
    : '(' partitionDefinerAtom (',' partitionDefinerAtom)+ ')'
    ;

subpartitionDefinition
    : SUBPARTITION uid partitionOption*
    ;

partitionOption
    : DEFAULT? STORAGE? ENGINE '='? engineName                      #partitionOptionEngine
    | COMMENT '='? comment=STRING_LITERAL                           #partitionOptionComment
    | DATA DIRECTORY '='? dataDirectory=STRING_LITERAL              #partitionOptionDataDirectory
    | INDEX DIRECTORY '='? indexDirectory=STRING_LITERAL            #partitionOptionIndexDirectory
    | MAX_ROWS '='? maxRows=decimalLiteral                          #partitionOptionMaxRows
    | MIN_ROWS '='? minRows=decimalLiteral                          #partitionOptionMinRows
    | TABLESPACE '='? tablespace=uid                                #partitionOptionTablespace
    | NODEGROUP '='? nodegroup=uid                                  #partitionOptionNodeGroup
    ;

//    Alter statements

alterDatabase
    : ALTER dbFormat=(DATABASE | SCHEMA) uid?
      createDatabaseOption+                                         #alterSimpleDatabase
    | ALTER dbFormat=(DATABASE | SCHEMA) uid
      UPGRADE DATA DIRECTORY NAME                                   #alterUpgradeName
    ;

alterEvent
    : ALTER ownerStatement?
      EVENT fullId
      (ON SCHEDULE scheduleExpression)?
      (ON COMPLETION NOT? PRESERVE)?
      (RENAME TO fullId)? enableType?
      (COMMENT STRING_LITERAL)?
      (DO routineBody)?
    ;

alterFunction
    : ALTER FUNCTION fullId routineOption*
    ;

alterInstance
    : ALTER INSTANCE ROTATE INNODB MASTER KEY
    ;

alterLogfileGroup
    : ALTER LOGFILE GROUP uid
      ADD UNDOFILE STRING_LITERAL
      (INITIAL_SIZE '='? fileSizeLiteral)?
      WAIT? ENGINE '='? engineName
    ;

alterProcedure
    : ALTER PROCEDURE fullId routineOption*
    ;

alterServer
    : ALTER SERVER uid OPTIONS
      '(' serverOption (',' serverOption)* ')'
    ;

alterTable
    : ALTER intimeAction=(ONLINE | OFFLINE)?
      IGNORE? TABLE tableName
      (alterSpecification (',' alterSpecification)*)?
      partitionDefinitions?
    ;

alterTablespace
    : ALTER TABLESPACE uid
      objectAction=(ADD | DROP) DATAFILE STRING_LITERAL
      (INITIAL_SIZE '=' fileSizeLiteral)?
      WAIT?
      ENGINE '='? engineName
    ;

alterView
    : ALTER
      (
        ALGORITHM '=' algType=(UNDEFINED | MERGE | TEMPTABLE)
      )?
      ownerStatement?
      (SQL SECURITY secContext=(DEFINER | INVOKER))?
      VIEW fullId ('(' uidList ')')? AS selectStatement
      (WITH checkOpt=(CASCADED | LOCAL)? CHECK OPTION)?
    ;

// details

alterSpecification
    : tableOption (','? tableOption)*                               #alterByTableOption
    | ADD COLUMN? ifNotExists? uid columnDefinition (FIRST | AFTER uid)?  #alterByAddColumn
    | ADD COLUMN? ifNotExists?
        '('
          uid columnDefinition ( ',' uid columnDefinition)*
        ')'                                                         #alterByAddColumns
    | ADD indexFormat=(INDEX | KEY) ifNotExists? uid? indexType?
      indexColumnNames indexOption*                                 #alterByAddIndex
    | ADD (CONSTRAINT name=uid?)? PRIMARY KEY index=uid?
      indexType? indexColumnNames indexOption*                      #alterByAddPrimaryKey
    | ADD (CONSTRAINT name=uid?)? UNIQUE
      indexFormat=(INDEX | KEY)? indexName=uid?
      indexType? indexColumnNames indexOption*                      #alterByAddUniqueKey
    | ADD keyType=(FULLTEXT | SPATIAL)
      indexFormat=(INDEX | KEY)? uid?
      indexColumnNames indexOption*                                 #alterByAddSpecialIndex
    | ADD (CONSTRAINT name=uid?)? FOREIGN KEY ifNotExists?
      indexName=uid? indexColumnNames referenceDefinition           #alterByAddForeignKey
    | ADD (CONSTRAINT name=uid?)? CHECK '(' expression ')'          #alterByAddCheckTableConstraint
    | ALGORITHM '='? algType=(DEFAULT | INSTANT | INPLACE | COPY)   #alterBySetAlgorithm
    | ALTER COLUMN? uid
      (SET DEFAULT defaultValue | DROP DEFAULT)                     #alterByChangeDefault
    | CHANGE COLUMN? ifExists? oldColumn=uid
      newColumn=uid columnDefinition
      (FIRST | AFTER afterColumn=uid)?                              #alterByChangeColumn
    | RENAME COLUMN oldColumn=uid TO newColumn=uid                  #alterByRenameColumn
    | LOCK '='? lockType=(DEFAULT | NONE | SHARED | EXCLUSIVE)      #alterByLock
    | MODIFY COLUMN? ifExists?
      uid columnDefinition (FIRST | AFTER uid)?                     #alterByModifyColumn
    | DROP COLUMN? ifExists? uid RESTRICT?                          #alterByDropColumn
    | DROP (CONSTRAINT | CHECK) ifExists? uid                       #alterByDropConstraintCheck
    | DROP PRIMARY KEY                                              #alterByDropPrimaryKey
    | RENAME indexFormat=(INDEX | KEY) uid TO uid                   #alterByRenameIndex
    | ALTER INDEX uid (VISIBLE | INVISIBLE)                         #alterByAlterIndexVisibility
    | DROP indexFormat=(INDEX | KEY) ifExists? uid                  #alterByDropIndex
    | DROP FOREIGN KEY ifExists? uid                                #alterByDropForeignKey
    | DISABLE KEYS                                                  #alterByDisableKeys
    | ENABLE KEYS                                                   #alterByEnableKeys
    | RENAME renameFormat=(TO | AS)? (uid | fullId)                 #alterByRename
    | ORDER BY uidList                                              #alterByOrder
    | CONVERT TO CHARACTER SET charsetName
      (COLLATE collationName)?                                      #alterByConvertCharset
    | DEFAULT? CHARACTER SET '=' charsetName
      (COLLATE '=' collationName)?                                  #alterByDefaultCharset
    | DISCARD TABLESPACE                                            #alterByDiscardTablespace
    | IMPORT TABLESPACE                                             #alterByImportTablespace
    | FORCE                                                         #alterByForce
    | validationFormat=(WITHOUT | WITH) VALIDATION                  #alterByValidate
    | ADD PARTITION ifNotExists?
        '('
          partitionDefinition (',' partitionDefinition)*
        ')'                                                         #alterByAddPartition
    | DROP PARTITION ifExists? uidList                              #alterByDropPartition
    | DISCARD PARTITION (uidList | ALL) TABLESPACE                  #alterByDiscardPartition
    | IMPORT PARTITION (uidList | ALL) TABLESPACE                   #alterByImportPartition
    | TRUNCATE PARTITION (uidList | ALL)                            #alterByTruncatePartition
    | COALESCE PARTITION decimalLiteral                             #alterByCoalescePartition
    | REORGANIZE PARTITION uidList
        INTO '('
          partitionDefinition (',' partitionDefinition)*
        ')'                                                         #alterByReorganizePartition
    | EXCHANGE PARTITION uid WITH TABLE tableName
      (validationFormat=(WITH | WITHOUT) VALIDATION)?               #alterByExchangePartition
    | ANALYZE PARTITION (uidList | ALL)                             #alterByAnalyzePartition
    | CHECK PARTITION (uidList | ALL)                               #alterByCheckPartition
    | OPTIMIZE PARTITION (uidList | ALL)                            #alterByOptimizePartition
    | REBUILD PARTITION (uidList | ALL)                             #alterByRebuildPartition
    | REPAIR PARTITION (uidList | ALL)                              #alterByRepairPartition
    | REMOVE PARTITIONING                                           #alterByRemovePartitioning
    | UPGRADE PARTITIONING                                          #alterByUpgradePartitioning
    ;


//    Drop statements

dropDatabase
    : DROP dbFormat=(DATABASE | SCHEMA) ifExists? uid
    ;

dropEvent
    : DROP EVENT ifExists? fullId
    ;

dropIndex
    : DROP INDEX intimeAction=(ONLINE | OFFLINE)?
      uid ON tableName
      (
        ALGORITHM '='? algType=(DEFAULT | INPLACE | COPY)
        | LOCK '='?
          lockType=(DEFAULT | NONE | SHARED | EXCLUSIVE)
      )*
    ;

dropLogfileGroup
    : DROP LOGFILE GROUP uid ENGINE '=' engineName
    ;

dropProcedure
    : DROP PROCEDURE ifExists? fullId
    ;

dropFunction
    : DROP FUNCTION ifExists? fullId
    ;

dropServer
    : DROP SERVER ifExists? uid
    ;

dropTable
    : DROP TEMPORARY? TABLE ifExists?
      tables dropType=(RESTRICT | CASCADE)?
    ;

dropTablespace
    : DROP TABLESPACE uid (ENGINE '='? engineName)?
    ;

dropTrigger
    : DROP TRIGGER ifExists? fullId
    ;

dropView
    : DROP VIEW ifExists?
      fullId (',' fullId)* dropType=(RESTRICT | CASCADE)?
    ;


//    Other DDL statements

renameTable
    : RENAME TABLE
    renameTableClause (',' renameTableClause)*
    ;

renameTableClause
    : tableName TO tableName
    ;

truncateTable
    : TRUNCATE TABLE? tableName
    ;


// Data Manipulation Language

//    Primary DML Statements


callStatement
    : CALL fullId
      (
        '(' (constants | expressions)? ')'
      )?
    ;

deleteStatement
    : singleDeleteStatement | multipleDeleteStatement
    ;

doStatement
    : DO expressions
    ;

handlerStatement
    : handlerOpenStatement
    | handlerReadIndexStatement
    | handlerReadStatement
    | handlerCloseStatement
    ;

insertStatement
    : INSERT
      priority=(LOW_PRIORITY | DELAYED | HIGH_PRIORITY)?
      IGNORE? INTO? tableName
      (PARTITION '(' partitions=uidList? ')' )?
      (
        ('(' columns=uidList ')')? insertStatementValue
        | SET
            setFirst=updatedElement
            (',' setElements+=updatedElement)*
      )
      (
        ON DUPLICATE KEY UPDATE
        duplicatedFirst=updatedElement
        (',' duplicatedElements+=updatedElement)*
      )?
    ;

loadDataStatement
    : LOAD DATA
      priority=(LOW_PRIORITY | CONCURRENT)?
      LOCAL? INFILE filename=STRING_LITERAL
      violation=(REPLACE | IGNORE)?
      INTO TABLE tableName
      (PARTITION '(' uidList ')' )?
      (CHARACTER SET charset=charsetName)?
      (
        fieldsFormat=(FIELDS | COLUMNS)
        selectFieldsInto+
      )?
      (
        LINES
          selectLinesInto+
      )?
      (
        IGNORE decimalLiteral linesFormat=(LINES | ROWS)
      )?
      ( '(' assignmentField (',' assignmentField)* ')' )?
      (SET updatedElement (',' updatedElement)*)?
    ;

loadXmlStatement
    : LOAD XML
      priority=(LOW_PRIORITY | CONCURRENT)?
      LOCAL? INFILE filename=STRING_LITERAL
      violation=(REPLACE | IGNORE)?
      INTO TABLE tableName
      (CHARACTER SET charset=charsetName)?
      (ROWS IDENTIFIED BY '<' tag=STRING_LITERAL '>')?
      ( IGNORE decimalLiteral linesFormat=(LINES | ROWS) )?
      ( '(' assignmentField (',' assignmentField)* ')' )?
      (SET updatedElement (',' updatedElement)*)?
    ;

replaceStatement
    : REPLACE priority=(LOW_PRIORITY | DELAYED)?
      INTO? tableName
      (PARTITION '(' partitions=uidList ')' )?
      (
        ('(' columns=uidList ')')? insertStatementValue
        | SET
          setFirst=updatedElement
          (',' setElements+=updatedElement)*
      )
    ;

selectStatement
    : querySpecifications orderByClause? limitClause? lockClause?   #simpleSelect
    | queryExpression orderByClause? limitClause? lockClause?       #parenthesisSelect
    | querySpecificationNointo unionStatement+
        (
          UNION unionType=(ALL | DISTINCT)?
          (querySpecifications | queryExpression)
        )?
        orderByClause? limitClause? lockClause?                     #unionSelect
    | queryExpressionNointo unionParenthesis+
        (
          UNION unionType=(ALL | DISTINCT)?
          queryExpression
        )?
        orderByClause? limitClause? lockClause?                     #unionParenthesisSelect
    ;

updateStatement
    : singleUpdateStatement | multipleUpdateStatement
    ;

// details

insertStatementValue
    : selectStatement
    | insertFormat=(VALUES | VALUE)
      '(' expressionsWithDefaults? ')'
        (',' '(' expressionsWithDefaults? ')')*
    ;

updatedElement
    : fullColumnName '=' (expression | DEFAULT)
    ;

assignmentField
    : uid | LOCAL_ID
    ;

lockClause
    : FOR UPDATE | LOCK IN SHARE MODE
    ;

//    Detailed DML Statements

singleDeleteStatement
    : DELETE priority=LOW_PRIORITY? QUICK? IGNORE?
    FROM tableName (AS? alias=uid)? //refined
      (PARTITION '(' uidList ')' )?
      (WHERE expression)?
      orderByClause? (LIMIT limitClauseAtom)?
    ;

multipleDeleteStatement
    : DELETE priority=LOW_PRIORITY? QUICK? IGNORE?
      (
        tableName (AS? alias=uid)? ('.' '*')? ( ',' tableName (AS? alias=uid)? ('.' '*')? )* //refined
            FROM tableSources
        | FROM
            tableName (AS? alias=uid)? ('.' '*')? ( ',' tableName (AS? alias=uid)? ('.' '*')? )*//refined
            USING tableSources
      )
      (WHERE expression)?
    ;

handlerOpenStatement
    : HANDLER tableName OPEN (AS? uid)?
    ;

handlerReadIndexStatement
    : HANDLER tableName READ index=uid
      (
        comparisonOperator '(' constants ')'
        | moveOrder=(FIRST | NEXT | PREV | LAST)
      )
      (WHERE expression)? (LIMIT limitClauseAtom)?
    ;

handlerReadStatement
    : HANDLER tableName READ moveOrder=(FIRST | NEXT)
      (WHERE expression)? (LIMIT limitClauseAtom)?
    ;

handlerCloseStatement
    : HANDLER tableName CLOSE
    ;

singleUpdateStatement
    : UPDATE priority=LOW_PRIORITY? IGNORE? tableName (AS? uid)?
      SET updatedElement (',' updatedElement)*
      (WHERE expression)? orderByClause? limitClause?
    ;

multipleUpdateStatement
    : UPDATE priority=LOW_PRIORITY? IGNORE? tableSources
      SET updatedElement (',' updatedElement)*
      (WHERE expression)?
    ;

//mysql 8.0
//refined
valuesStatement
    : VALUES rowConstructors orderByClause? limitClause?
    | valuesStatement (UNION valuesStatement)+
    ;

rowConstructors
    : ROW '(' functionArgs ')' (',' ROW '(' functionArgs ')')*
    ;

//fromStatement
//    : FROM tableSources (AS? alias=uid)? // refined psql
//     (WHERE whereExpr=expression)?
//    ;

// details

orderByClause
    : ORDER BY orderByExpression (',' orderByExpression)*
    ;

orderByExpression
    : expression order=(ASC | DESC)?
    ;

tableSources
    : tableSource (',' tableSource)*
    ;

tableSource
    : tableSourceItem joinPart*                                     #tableSourceBase
    | '(' tableSourceItem joinPart* ')'                             #tableSourceNested
    ;

tableSourceItem
    : tableName
      (PARTITION '(' uidList ')' )? (AS? alias=uid)?
      (indexHint (',' indexHint)* )?                                #atomTableItem
    | (
      selectStatement
      | '(' parenthesisSubquery=selectStatement ')'
      )
      (AS? alias=uid)?                                              #subqueryTableItem // refined
    | '(' tableSources ')'
        (
            UNION unionType=(ALL | DISTINCT)?
            (querySpecifications | queryExpression)
        )?
        orderByClause? limitClause? lockClause?
        (AS? alias=uid)?                                            #tableSourcesItem // refined
    | valuesStatement                                               #valuesTableItem // refined
    ;

indexHint
    : indexHintAction=(USE | IGNORE | FORCE)
      keyFormat=(INDEX|KEY) ( FOR indexHintType)?
      '(' uidList ')'
    ;

indexHintType
    : JOIN | ORDER BY | GROUP BY
    ;

joinPart
    : NATURAL? (INNER | CROSS)? JOIN tableSourceItem // refined NATURAL
      (
        ON expression
        | USING '(' uidList ')'
      )?                                                            #innerJoin
    | STRAIGHT_JOIN tableSourceItem (ON expression)?                #straightJoin
    | (LEFT | RIGHT) OUTER? JOIN tableSourceItem
        (
          ON expression
          | USING '(' uidList ')'
        )                                                           #outerJoin
    | NATURAL ((LEFT | RIGHT) OUTER?)? JOIN tableSourceItem         #naturalJoin
//    | operator=(UNION | INTERSECTS | EXCEPT) tableSourceItem        #unionJoin // refined
    ;

//unionPart
//    : operator=(UNION | INTERSECTS | EXCEPT) unionType=(ALL | DISTINCT)? tableSourceItem
//    ;

//    Select Statement's Details

queryExpression
    : '(' querySpecifications ')'
    | '(' queryExpression ')'
    ;

queryExpressionNointo
    : (
        ('(' querySpecificationNointo ')')
        | querySpecificationNointo // refined psql
      )
    | '(' queryExpressionNointo ')'
    ;



querySpecification // refined
    : withClause? SELECT selectSpec* selectElements selectIntoExpression?
      fromClause? groupByClause? havingClause? windowClause? orderByClause? limitClause?
    | withClause? SELECT selectSpec* selectElements
    fromClause? groupByClause? havingClause? windowClause? orderByClause? limitClause? selectIntoExpression?
    ;

querySpecifications
    : querySpecification (UNION unionType=(ALL | DISTINCT)? (querySpecification | queryExpression))*
    ;

querySpecificationNointo // refined
    : withClause? SELECT selectSpec* selectElements
      fromClause? groupByClause? havingClause? windowClause? orderByClause? limitClause?
    ;

unionParenthesis
    : UNION unionType=(ALL | DISTINCT)? queryExpressionNointo
    ;

unionStatement
    : UNION unionType=(ALL | DISTINCT)?
      (querySpecificationNointo | queryExpressionNointo)
    ;

// details

selectSpec
    : (ALL | DISTINCT | DISTINCTROW)
    | HIGH_PRIORITY | STRAIGHT_JOIN | SQL_SMALL_RESULT
    | SQL_BIG_RESULT | SQL_BUFFER_RESULT
    | (SQL_CACHE | SQL_NO_CACHE)
    | SQL_CALC_FOUND_ROWS
    ;

selectElements
    : (star='*' | selectElement ) (',' selectElement)*
    ;

selectElement
    : fullId '.' '*'                                                #selectStarElement
    | fullColumnName (AS? uid)?                                     #selectColumnElement
    | functionCall (AS? uid)?                                       #selectFunctionElement
    | (LOCAL_ID VAR_ASSIGN)? expression (AS? uid)?                  #selectExpressionElement
    ;

selectIntoExpression
    : INTO assignmentField (',' assignmentField )*                  #selectIntoVariables
    | INTO DUMPFILE STRING_LITERAL                                  #selectIntoDumpFile
    | (
        INTO OUTFILE filename=STRING_LITERAL
        (CHARACTER SET charset=charsetName)?
        (
          fieldsFormat=(FIELDS | COLUMNS)
          selectFieldsInto+
        )?
        (
          LINES selectLinesInto+
        )?
      )                                                             #selectIntoTextFile
    ;

selectFieldsInto
    : TERMINATED BY terminationField=STRING_LITERAL
    | OPTIONALLY? ENCLOSED BY enclosion=STRING_LITERAL
    | ESCAPED BY escaping=STRING_LITERAL
    ;

selectLinesInto
    : STARTING BY starting=STRING_LITERAL
    | TERMINATED BY terminationLine=STRING_LITERAL
    ;

fromClause
    : (FROM tableSources (AS? alias=uid)?)? // refined psql
      (WHERE whereExpr=expression)?
    ;

groupByClause
    :  GROUP BY
        groupByItem (',' groupByItem)*
        (WITH ROLLUP)?
    ;

havingClause
    :  HAVING havingExpr=expression
    ;

windowClause
    :  WINDOW windowName AS '(' windowSpec ')' (',' windowName AS '(' windowSpec ')')*
    ;

groupByItem
    : expression order=(ASC | DESC)?
    ;

limitClause
    : LIMIT
    (
      (offset=limitClauseAtom ',')? limit=limitClauseAtom
      | limit=limitClauseAtom OFFSET offset=limitClauseAtom
    )
    ;

limitClauseAtom
	: decimalLiteral | mysqlVariable | simpleId
	;


// Transaction's Statements

startTransaction
    : START TRANSACTION (transactionMode (',' transactionMode)* )?
    ;

beginWork
    : BEGIN WORK?
    ;

commitWork
    : COMMIT WORK?
      (AND nochain=NO? CHAIN)?
      (norelease=NO? RELEASE)?
    ;

rollbackWork
    : ROLLBACK WORK?
      (AND nochain=NO? CHAIN)?
      (norelease=NO? RELEASE)?
    ;

savepointStatement
    : SAVEPOINT uid
    ;

rollbackStatement
    : ROLLBACK WORK? TO SAVEPOINT? uid
    ;

releaseStatement
    : RELEASE SAVEPOINT uid
    ;

lockTables
    : LOCK TABLES lockTableElement (',' lockTableElement)*
    ;

unlockTables
    : UNLOCK TABLES
    ;


// details

setAutocommitStatement
    : SET AUTOCOMMIT '=' autocommitValue=('0' | '1')
    ;

setTransactionStatement
    : SET transactionContext=(GLOBAL | SESSION)? TRANSACTION
      transactionOption (',' transactionOption)*
    ;

transactionMode
    : WITH CONSISTENT SNAPSHOT
    | READ WRITE
    | READ ONLY
    ;

lockTableElement
    : tableName (AS? uid)? lockAction
    ;

lockAction
    : READ LOCAL? | LOW_PRIORITY? WRITE
    ;

transactionOption
    : ISOLATION LEVEL transactionLevel
    | READ WRITE
    | READ ONLY
    ;

transactionLevel
    : REPEATABLE READ
    | READ COMMITTED
    | READ UNCOMMITTED
    | SERIALIZABLE
    ;


// Replication's Statements

//    Base Replication

changeMaster
    : CHANGE MASTER TO
      masterOption (',' masterOption)* channelOption?
    ;

changeReplicationFilter
    : CHANGE REPLICATION FILTER
      replicationFilter (',' replicationFilter)*
    ;

purgeBinaryLogs
    : PURGE purgeFormat=(BINARY | MASTER) LOGS
       (
           TO fileName=STRING_LITERAL
           | BEFORE timeValue=STRING_LITERAL
       )
    ;

resetMaster
    : RESET MASTER
    ;

resetSlave
    : RESET SLAVE ALL? channelOption?
    ;

startSlave
    : START SLAVE (threadType (',' threadType)*)?
      (UNTIL untilOption)?
      connectionOption* channelOption?
    ;

stopSlave
    : STOP SLAVE (threadType (',' threadType)*)?
    ;

startGroupReplication
    : START GROUP_REPLICATION
    ;

stopGroupReplication
    : STOP GROUP_REPLICATION
    ;

// details

masterOption
    : stringMasterOption '=' STRING_LITERAL                         #masterStringOption
    | decimalMasterOption '=' decimalLiteral                        #masterDecimalOption
    | boolMasterOption '=' boolVal=('0' | '1')                      #masterBoolOption
    | MASTER_HEARTBEAT_PERIOD '=' REAL_LITERAL                      #masterRealOption
    | IGNORE_SERVER_IDS '=' '(' (uid (',' uid)*)? ')'               #masterUidListOption
    ;

stringMasterOption
    : MASTER_BIND | MASTER_HOST | MASTER_USER | MASTER_PASSWORD
    | MASTER_LOG_FILE | RELAY_LOG_FILE | MASTER_SSL_CA
    | MASTER_SSL_CAPATH | MASTER_SSL_CERT | MASTER_SSL_CRL
    | MASTER_SSL_CRLPATH | MASTER_SSL_KEY | MASTER_SSL_CIPHER
    | MASTER_TLS_VERSION
    ;
decimalMasterOption
    : MASTER_PORT | MASTER_CONNECT_RETRY | MASTER_RETRY_COUNT
    | MASTER_DELAY | MASTER_LOG_POS | RELAY_LOG_POS
    ;

boolMasterOption
    : MASTER_AUTO_POSITION | MASTER_SSL
    | MASTER_SSL_VERIFY_SERVER_CERT
    ;

channelOption
    : FOR CHANNEL STRING_LITERAL
    ;

replicationFilter
    : REPLICATE_DO_DB '=' '(' uidList ')'                           #doDbReplication
    | REPLICATE_IGNORE_DB '=' '(' uidList ')'                       #ignoreDbReplication
    | REPLICATE_DO_TABLE '=' '(' tables ')'                         #doTableReplication
    | REPLICATE_IGNORE_TABLE '=' '(' tables ')'                     #ignoreTableReplication
    | REPLICATE_WILD_DO_TABLE '=' '(' simpleStrings ')'             #wildDoTableReplication
    | REPLICATE_WILD_IGNORE_TABLE
       '=' '(' simpleStrings ')'                                    #wildIgnoreTableReplication
    | REPLICATE_REWRITE_DB '='
      '(' tablePair (',' tablePair)* ')'                            #rewriteDbReplication
    ;

tablePair
    : '(' firstTable=tableName ',' secondTable=tableName ')'
    ;

threadType
    : IO_THREAD | SQL_THREAD
    ;

untilOption
    : gtids=(SQL_BEFORE_GTIDS | SQL_AFTER_GTIDS)
      '=' gtuidSet                                                  #gtidsUntilOption
    | MASTER_LOG_FILE '=' STRING_LITERAL
      ',' MASTER_LOG_POS '=' decimalLiteral                         #masterLogUntilOption
    | RELAY_LOG_FILE '=' STRING_LITERAL
      ',' RELAY_LOG_POS '=' decimalLiteral                          #relayLogUntilOption
    | SQL_AFTER_MTS_GAPS                                            #sqlGapsUntilOption
    ;

connectionOption
    : USER '=' conOptUser=STRING_LITERAL                            #userConnectionOption
    | PASSWORD '=' conOptPassword=STRING_LITERAL                    #passwordConnectionOption
    | DEFAULT_AUTH '=' conOptDefAuth=STRING_LITERAL                 #defaultAuthConnectionOption
    | PLUGIN_DIR '=' conOptPluginDir=STRING_LITERAL                 #pluginDirConnectionOption
    ;

gtuidSet
    : uuidSet (',' uuidSet)*
    | STRING_LITERAL
    ;


//    XA Transactions

xaStartTransaction
    : XA xaStart=(START | BEGIN) xid xaAction=(JOIN | RESUME)?
    ;

xaEndTransaction
    : XA END xid (SUSPEND (FOR MIGRATE)?)?
    ;

xaPrepareStatement
    : XA PREPARE xid
    ;

xaCommitWork
    : XA COMMIT xid (ONE PHASE)?
    ;

xaRollbackWork
    : XA ROLLBACK xid
    ;

xaRecoverWork
    : XA RECOVER (CONVERT xid)?
    ;


// Prepared Statements

prepareStatement
    : PREPARE uid FROM
      (query=STRING_LITERAL | variable=LOCAL_ID)
    ;

executeStatement
    : EXECUTE uid (USING userVariables)?
    ;

deallocatePrepare
    : dropFormat=(DEALLOCATE | DROP) PREPARE uid
    ;


// Compound Statements

routineBody
    : blockStatement | sqlStatement
    ;

// details

blockStatement
    : (uid ':')? BEGIN
      (
        (declareVariable SEMI)*
        (declareCondition SEMI)*
        (declareCursor SEMI)*
        (declareHandler SEMI)*
        procedureSqlStatement*
      )?
      END uid?
    ;

caseStatement
    : CASE (uid | expression)? caseAlternative+
      (ELSE (procedureSqlStatement+ | expression))?
      END CASE?
    ;

ifStatement
    : IF expression
      THEN thenStatements+=procedureSqlStatement+
      elifAlternative*
      (ELSE elseStatements+=procedureSqlStatement+ )?
      END IF?
    ;

iterateStatement
    : ITERATE uid
    ;

leaveStatement
    : LEAVE uid
    ;

loopStatement
    : (uid ':')?
      LOOP procedureSqlStatement+
      END LOOP uid?
    ;

repeatStatement
    : (uid ':')?
      REPEAT procedureSqlStatement+
      UNTIL expression
      END REPEAT uid?
    ;

returnStatement
    : RETURN expression
    ;

whileStatement
    : (uid ':')?
      WHILE expression
      DO procedureSqlStatement+
      END WHILE uid?
    ;

cursorStatement
    : CLOSE uid                                                     #CloseCursor
    | FETCH (NEXT? FROM)? uid INTO uidList                          #FetchCursor
    | OPEN uid                                                      #OpenCursor
    ;

// details

declareVariable
    : DECLARE uidList dataType (DEFAULT expression)?
    ;

declareCondition
    : DECLARE uid CONDITION FOR
      ( decimalLiteral | SQLSTATE VALUE? STRING_LITERAL)
    ;

declareCursor
    : DECLARE uid CURSOR FOR selectStatement
    ;

declareHandler
    : DECLARE handlerAction=(CONTINUE | EXIT | UNDO)
      HANDLER FOR
      handlerConditionValue (',' handlerConditionValue)*
      routineBody
    ;

handlerConditionValue
    : decimalLiteral                                                #handlerConditionCode
    | SQLSTATE VALUE? STRING_LITERAL                                #handlerConditionState
    | uid                                                           #handlerConditionName
    | SQLWARNING                                                    #handlerConditionWarning
    | NOT FOUND                                                     #handlerConditionNotfound
    | SQLEXCEPTION                                                  #handlerConditionException
    ;

procedureSqlStatement
    : (compoundStatement | sqlStatement) SEMI
    ;

caseAlternative
    : WHEN (constant | expression)
      THEN (procedureSqlStatement+ | expression) // refined
    ;

elifAlternative
    : ELSEIF expression
      THEN procedureSqlStatement+
    ;

// Administration Statements

//    Account management statements

alterUser
    : ALTER USER
      userSpecification (',' userSpecification)*                    #alterUserMysqlV56
    | ALTER USER ifExists?
        userAuthOption (',' userAuthOption)*
        (
          REQUIRE
          (tlsNone=NONE | tlsOption (AND? tlsOption)* )
        )?
        (WITH userResourceOption+)?
        (userPasswordOption | userLockOption)*                      #alterUserMysqlV57
    ;

createUser
    : CREATE USER userAuthOption (',' userAuthOption)*              #createUserMysqlV56
    | CREATE USER ifNotExists?
        userAuthOption (',' userAuthOption)*
        (
          REQUIRE
          (tlsNone=NONE | tlsOption (AND? tlsOption)* )
        )?
        (WITH userResourceOption+)?
        (userPasswordOption | userLockOption)*                      #createUserMysqlV57
    ;

dropUser
    : DROP USER ifExists? userName (',' userName)*
    ;

grantStatement
    : GRANT privelegeClause (',' privelegeClause)*
      ON
      privilegeObject=(TABLE | FUNCTION | PROCEDURE)?
      privilegeLevel
      TO userAuthOption (',' userAuthOption)*
      (
          REQUIRE
          (tlsNone=NONE | tlsOption (AND? tlsOption)* )
        )?
      (WITH (GRANT OPTION | userResourceOption)* )?
      (AS userName WITH ROLE roleOption)?
    | GRANT (userName | uid ) (',' (userName | uid))*
      TO (userName | uid) (',' (userName | uid))*
      (WITH ADMIN OPTION)?
    ;

roleOption
    : DEFAULT
    | NONE
    | ALL (EXCEPT userName (',' userName)*)?
    | userName (',' userName)*
    ;

grantProxy
    : GRANT PROXY ON fromFirst=userName
      TO toFirst=userName (',' toOther+=userName)*
      (WITH GRANT OPTION)?
    ;

renameUser
    : RENAME USER
      renameUserClause (',' renameUserClause)*
    ;

revokeStatement
    : REVOKE privelegeClause (',' privelegeClause)*
      ON
      privilegeObject=(TABLE | FUNCTION | PROCEDURE)?
      privilegeLevel
      FROM userName (',' userName)*                                 #detailRevoke
    | REVOKE ALL PRIVILEGES? ',' GRANT OPTION
      FROM userName (',' userName)*                                 #shortRevoke
    | REVOKE uid (',' uid)*
      FROM (userName | uid) (',' (userName | uid))*                 #roleRevoke
    ;

revokeProxy
    : REVOKE PROXY ON onUser=userName
      FROM fromFirst=userName (',' fromOther+=userName)*
    ;

setPasswordStatement
    : SET PASSWORD (FOR userName)?
      '=' ( passwordFunctionClause | STRING_LITERAL)
    ;

// details

userSpecification
    : userName userPasswordOption
    ;

userAuthOption
    : userName IDENTIFIED BY PASSWORD hashed=STRING_LITERAL         #passwordAuthOption
    | userName
      IDENTIFIED (WITH authPlugin)? BY STRING_LITERAL
      (RETAIN CURRENT PASSWORD)?                                    #stringAuthOption
    | userName
      IDENTIFIED WITH authPlugin
      (AS STRING_LITERAL)?                                          #hashAuthOption
    | userName                                                      #simpleAuthOption
    ;

tlsOption
    : SSL
    | X509
    | CIPHER STRING_LITERAL
    | ISSUER STRING_LITERAL
    | SUBJECT STRING_LITERAL
    ;

userResourceOption
    : MAX_QUERIES_PER_HOUR decimalLiteral
    | MAX_UPDATES_PER_HOUR decimalLiteral
    | MAX_CONNECTIONS_PER_HOUR decimalLiteral
    | MAX_USER_CONNECTIONS decimalLiteral
    ;

userPasswordOption
    : PASSWORD EXPIRE
      (expireType=DEFAULT
      | expireType=NEVER
      | expireType=INTERVAL decimalLiteral DAY
      )?
    ;

userLockOption
    : ACCOUNT lockType=(LOCK | UNLOCK)
    ;

privelegeClause
    : privilege ( '(' uidList ')' )?
    ;

privilege
    : ALL PRIVILEGES?
    | ALTER ROUTINE?
    | CREATE
      (TEMPORARY TABLES | ROUTINE | VIEW | USER | TABLESPACE | ROLE)?
    | DELETE | DROP (ROLE)? | EVENT | EXECUTE | FILE | GRANT OPTION
    | INDEX | INSERT | LOCK TABLES | PROCESS | PROXY
    | REFERENCES | RELOAD
    | REPLICATION (CLIENT | SLAVE)
    | SELECT
    | SHOW (VIEW | DATABASES)
    | SHUTDOWN | SUPER | TRIGGER | UPDATE | USAGE
    | APPLICATION_PASSWORD_ADMIN | AUDIT_ADMIN | BACKUP_ADMIN | BINLOG_ADMIN | BINLOG_ENCRYPTION_ADMIN | CLONE_ADMIN
    | CONNECTION_ADMIN | ENCRYPTION_KEY_ADMIN | FIREWALL_ADMIN | FIREWALL_USER | FLUSH_OPTIMIZER_COSTS
    | FLUSH_STATUS | FLUSH_TABLES | FLUSH_USER_RESOURCES | GROUP_REPLICATION_ADMIN
    | INNODB_REDO_LOG_ARCHIVE | INNODB_REDO_LOG_ENABLE | NDB_STORED_USER | PERSIST_RO_VARIABLES_ADMIN | REPLICATION_APPLIER
    | REPLICATION_SLAVE_ADMIN | RESOURCE_GROUP_ADMIN | RESOURCE_GROUP_USER | ROLE_ADMIN
    | SERVICE_CONNECTION_ADMIN
    | SESSION_VARIABLES_ADMIN | SET_USER_ID | SHOW_ROUTINE | SYSTEM_USER | SYSTEM_VARIABLES_ADMIN
    | TABLE_ENCRYPTION_ADMIN | VERSION_TOKEN_ADMIN | XA_RECOVER_ADMIN
    ;

privilegeLevel
    : '*'                                                           #currentSchemaPriviLevel
    | '*' '.' '*'                                                   #globalPrivLevel
    | uid '.' '*'                                                   #definiteSchemaPrivLevel
    | uid '.' uid                                                   #definiteFullTablePrivLevel
    | uid dottedId                                                  #definiteFullTablePrivLevel2
    | uid                                                           #definiteTablePrivLevel
    ;

renameUserClause
    : fromFirst=userName TO toFirst=userName
    ;

//    Table maintenance statements

analyzeTable
    : ANALYZE actionOption=(NO_WRITE_TO_BINLOG | LOCAL)?
       (TABLE | TABLES) tables
       ( UPDATE HISTOGRAM ON fullColumnName (',' fullColumnName)* (WITH decimalLiteral BUCKETS)? )?
       ( DROP HISTOGRAM ON fullColumnName (',' fullColumnName)* )?
    ;

checkTable
    : CHECK TABLE tables checkTableOption*
    ;

checksumTable
    : CHECKSUM TABLE tables actionOption=(QUICK | EXTENDED)?
    ;

optimizeTable
    : OPTIMIZE actionOption=(NO_WRITE_TO_BINLOG | LOCAL)?
      (TABLE | TABLES) tables
    ;

repairTable
    : REPAIR actionOption=(NO_WRITE_TO_BINLOG | LOCAL)?
      TABLE tables
      QUICK? EXTENDED? USE_FRM?
    ;

// details

checkTableOption
    : FOR UPGRADE | QUICK | FAST | MEDIUM | EXTENDED | CHANGED
    ;


//    Plugin and udf statements

createUdfunction
    : CREATE AGGREGATE? FUNCTION uid
      RETURNS returnType=(STRING | INTEGER | REAL | DECIMAL)
      SONAME STRING_LITERAL
    ;

installPlugin
    : INSTALL PLUGIN uid SONAME STRING_LITERAL
    ;

uninstallPlugin
    : UNINSTALL PLUGIN uid
    ;


//    Set and show statements

setStatement
    : SET variableClause ('=' | ':=') (expression | ON)
      (',' variableClause ('=' | ':=') (expression | ON))*                      #setVariable
    | SET charSet (charsetName | DEFAULT)          #setCharset
    | SET NAMES
        (charsetName (COLLATE collationName)? | DEFAULT)                        #setNames
    | setPasswordStatement                                                      #setPassword
    | setTransactionStatement                                                   #setTransaction
    | setAutocommitStatement                                                    #setAutocommit
    | SET fullId ('=' | ':=') expression
      (',' fullId ('=' | ':=') expression)*                                     #setNewValueInsideTrigger
    ;

showStatement
    : SHOW logFormat=(BINARY | MASTER) LOGS                         #showMasterLogs
    | SHOW logFormat=(BINLOG | RELAYLOG)
      EVENTS (IN filename=STRING_LITERAL)?
        (FROM fromPosition=decimalLiteral)?
        (LIMIT
          (offset=decimalLiteral ',')?
          rowCount=decimalLiteral
        )?                                                          #showLogEvents
    | SHOW showCommonEntity showFilter?                             #showObjectFilter
    | SHOW FULL? columnsFormat=(COLUMNS | FIELDS)
      tableFormat=(FROM | IN) tableName
        (schemaFormat=(FROM | IN) uid)? showFilter?                 #showColumns
    | SHOW CREATE schemaFormat=(DATABASE | SCHEMA)
      ifNotExists? uid                                              #showCreateDb
    | SHOW CREATE
        namedEntity=(
          EVENT | FUNCTION | PROCEDURE
          | TABLE | TRIGGER | VIEW
        )
        fullId                                                      #showCreateFullIdObject
    | SHOW CREATE USER userName                                     #showCreateUser
    | SHOW ENGINE engineName engineOption=(STATUS | MUTEX)          #showEngine
    | SHOW showGlobalInfoClause                                     #showGlobalInfo
    | SHOW errorFormat=(ERRORS | WARNINGS)
        (LIMIT
          (offset=decimalLiteral ',')?
          rowCount=decimalLiteral
        )?                                                          #showErrors
    | SHOW COUNT '(' '*' ')' errorFormat=(ERRORS | WARNINGS)        #showCountErrors
    | SHOW showSchemaEntity
        (schemaFormat=(FROM | IN) uid)? showFilter?                 #showSchemaFilter
    | SHOW routine=(FUNCTION | PROCEDURE) CODE fullId               #showRoutine
    | SHOW GRANTS (FOR userName)?                                   #showGrants
    | SHOW indexFormat=(INDEX | INDEXES | KEYS)
      tableFormat=(FROM | IN) tableName
        (schemaFormat=(FROM | IN) uid)? (WHERE expression)?         #showIndexes
    | SHOW OPEN TABLES ( schemaFormat=(FROM | IN) uid)?
      showFilter?                                                   #showOpenTables
    | SHOW PROFILE showProfileType (',' showProfileType)*
        (FOR QUERY queryCount=decimalLiteral)?
        (LIMIT
          (offset=decimalLiteral ',')?
          rowCount=decimalLiteral
        )                                                           #showProfile
    | SHOW SLAVE STATUS (FOR CHANNEL STRING_LITERAL)?               #showSlaveStatus
    ;

// details

variableClause
    : LOCAL_ID | GLOBAL_ID | ( ('@' '@')? (GLOBAL | SESSION | LOCAL)  )? uid
    ;

showCommonEntity
    : CHARACTER SET | COLLATION | DATABASES | SCHEMAS
    | FUNCTION STATUS | PROCEDURE STATUS
    | (GLOBAL | SESSION)? (STATUS | VARIABLES)
    ;

showFilter
    : LIKE STRING_LITERAL
    | WHERE expression
    ;

showGlobalInfoClause
    : STORAGE? ENGINES | MASTER STATUS | PLUGINS
    | PRIVILEGES | FULL? PROCESSLIST | PROFILES
    | SLAVE HOSTS | AUTHORS | CONTRIBUTORS
    ;

showSchemaEntity
    : EVENTS | TABLE STATUS | FULL? TABLES | TRIGGERS
    ;

showProfileType
    : ALL | BLOCK IO | CONTEXT SWITCHES | CPU | IPC | MEMORY
    | PAGE FAULTS | SOURCE | SWAPS
    ;


//    Other administrative statements

binlogStatement
    : BINLOG STRING_LITERAL
    ;

cacheIndexStatement
    : CACHE INDEX tableIndexes (',' tableIndexes)*
      ( PARTITION '(' (uidList | ALL) ')' )?
      IN schema=uid
    ;

flushStatement
    : FLUSH flushFormat=(NO_WRITE_TO_BINLOG | LOCAL)?
      flushOption (',' flushOption)*
    ;

killStatement
    : KILL connectionFormat=(CONNECTION | QUERY)?
      decimalLiteral+
    ;

loadIndexIntoCache
    : LOAD INDEX INTO CACHE
      loadedTableIndexes (',' loadedTableIndexes)*
    ;

// remark reset (maser | slave) describe in replication's
//  statements section
resetStatement
    : RESET QUERY CACHE
    ;

shutdownStatement
    : SHUTDOWN
    ;

// details

tableIndexes
    : tableName ( indexFormat=(INDEX | KEY)? '(' uidList ')' )?
    ;

flushOption
    : (
        DES_KEY_FILE | HOSTS
        | (
            BINARY | ENGINE | ERROR | GENERAL | RELAY | SLOW
          )? LOGS
        | OPTIMIZER_COSTS | PRIVILEGES | QUERY CACHE | STATUS
        | USER_RESOURCES | TABLES (WITH READ LOCK)?
       )                                                            #simpleFlushOption
    | RELAY LOGS channelOption?                                     #channelFlushOption
    | (TABLE | TABLES) tables? flushTableOption?                    #tableFlushOption
    ;

flushTableOption
    : WITH READ LOCK
    | FOR EXPORT
    ;

loadedTableIndexes
    : tableName
      ( PARTITION '(' (partitionList=uidList | ALL) ')' )?
      ( indexFormat=(INDEX | KEY)? '(' indexList=uidList ')' )?
      (IGNORE LEAVES)?
    ;


// Utility Statements


simpleDescribeStatement
    : command=(EXPLAIN | DESCRIBE | DESC) tableName
      (column=uid | pattern=STRING_LITERAL)?
    ;

fullDescribeStatement
    : command=(EXPLAIN | DESCRIBE | DESC)
      (
        formatType=(EXTENDED | PARTITIONS | FORMAT )
        '='
        formatValue=(TRADITIONAL | JSON)
      )?
      describeObjectClause
    ;

helpStatement
    : HELP STRING_LITERAL
    ;

useStatement
    : USE uid
    ;

signalStatement
    : SIGNAL ( ( SQLSTATE VALUE? stringLiteral ) | ID | REVERSE_QUOTE_ID )
        ( SET signalConditionInformation ( ',' signalConditionInformation)* )?
    ;

resignalStatement
    : RESIGNAL ( ( SQLSTATE VALUE? stringLiteral ) | ID | REVERSE_QUOTE_ID )?
        ( SET signalConditionInformation ( ',' signalConditionInformation)* )?
    ;

signalConditionInformation
    : ( CLASS_ORIGIN
          | SUBCLASS_ORIGIN
          | MESSAGE_TEXT
          | MYSQL_ERRNO
          | CONSTRAINT_CATALOG
          | CONSTRAINT_SCHEMA
          | CONSTRAINT_NAME
          | CATALOG_NAME
          | SCHEMA_NAME
          | TABLE_NAME
          | COLUMN_NAME
          | CURSOR_NAME
        ) '=' ( stringLiteral | DECIMAL_LITERAL | mysqlVariable | simpleId )
    ;

diagnosticsStatement
    : GET ( CURRENT | STACKED )? DIAGNOSTICS (
          ( variableClause '=' ( NUMBER | ROW_COUNT ) ( ',' variableClause '=' ( NUMBER | ROW_COUNT ) )* )
        | ( CONDITION  ( decimalLiteral | variableClause ) variableClause '=' diagnosticsConditionInformationName ( ',' variableClause '=' diagnosticsConditionInformationName )* )
      )
    ;

diagnosticsConditionInformationName
    : CLASS_ORIGIN
    | SUBCLASS_ORIGIN
    | RETURNED_SQLSTATE
    | MESSAGE_TEXT
    | MYSQL_ERRNO
    | CONSTRAINT_CATALOG
    | CONSTRAINT_SCHEMA
    | CONSTRAINT_NAME
    | CATALOG_NAME
    | SCHEMA_NAME
    | TABLE_NAME
    | COLUMN_NAME
    | CURSOR_NAME
    ;

// details

describeObjectClause
    : (
        selectStatement | deleteStatement | insertStatement
        | replaceStatement | updateStatement
      )                                                             #describeStatements
    | FOR CONNECTION uid                                            #describeConnection
    ;


// Common Clauses

//    DB Objects

fullId
    : uid (DOT_ID | '.' uid)?
    ;

tableName
    : fullId //(AS? alias=uid)?
    ;

fullColumnName
    : uid (dottedId dottedId? )?
    | . dottedId dottedId?
    ;

indexColumnName
    : ((uid | STRING_LITERAL) ('(' decimalLiteral ')')? | expression) sortType=(ASC | DESC)?
    ;

userName
    : STRING_USER_NAME | ID | STRING_LITERAL | ADMIN;

mysqlVariable
    : LOCAL_ID
    | GLOBAL_ID
    ;

charsetName
    : BINARY
    | charsetNameBase
    | STRING_LITERAL
    | CHARSET_REVERSE_QOUTE_STRING
    ;

collationName
    : uid | STRING_LITERAL;

engineName
    : ARCHIVE | BLACKHOLE | CSV | FEDERATED | INNODB | MEMORY
    | MRG_MYISAM | MYISAM | NDB | NDBCLUSTER | PERFORMANCE_SCHEMA
    | TOKUDB
    | ID
    | STRING_LITERAL | REVERSE_QUOTE_ID
    | CONNECT
    ;

uuidSet
    : decimalLiteral '-' decimalLiteral '-' decimalLiteral
      '-' decimalLiteral '-' decimalLiteral
      (':' decimalLiteral '-' decimalLiteral)+
    ;

xid
    : globalTableUid=xuidStringId
      (
        ',' qualifier=xuidStringId
        (',' idFormat=decimalLiteral)?
      )?
    ;

xuidStringId
    : STRING_LITERAL
    | BIT_STRING
    | HEXADECIMAL_LITERAL+
    ;

authPlugin
    : uid | STRING_LITERAL
    ;

uid
    : simpleId
    | aliasKeyword // refined psql
    //| DOUBLE_QUOTE_ID
    | REVERSE_QUOTE_ID
    | CHARSET_REVERSE_QOUTE_STRING
    ;

simpleId
    : ID
    | charsetNameBase
    | transactionLevelBase
    | engineName
    | privilegesBase
    | intervalTypeBase
    | dataTypeBase
    | keywordsCanBeId
    | functionNameBase
    ;

dottedId
    : DOT_ID
    | '.' uid
    ;


//    Literals

decimalLiteral
    : DECIMAL_LITERAL | ZERO_DECIMAL | ONE_DECIMAL | TWO_DECIMAL | REAL_LITERAL | NULL_LITERAL
    ;

fileSizeLiteral
    : FILESIZE_LITERAL | decimalLiteral;

stringLiteral
    : (
        STRING_CHARSET_NAME? STRING_LITERAL
        | START_NATIONAL_STRING_LITERAL
      ) STRING_LITERAL+
    | (
        STRING_CHARSET_NAME? STRING_LITERAL
        | START_NATIONAL_STRING_LITERAL
      ) (COLLATE collationName)?
    ;

booleanLiteral
    : TRUE | FALSE;

hexadecimalLiteral
    : STRING_CHARSET_NAME? HEXADECIMAL_LITERAL;

nullNotnull
    : NOT? (NULL_LITERAL | NULL_SPEC_LITERAL)
    ;

constant
    : stringLiteral | decimalLiteral
    | '-' decimalLiteral
    | hexadecimalLiteral | booleanLiteral
    | REAL_LITERAL | BIT_STRING
    | NOT? nullLiteral=(NULL_LITERAL | NULL_SPEC_LITERAL)
    ;


//    Data Types

dataType
    : typeName=(
      CHAR | CHARACTER | VARCHAR | TINYTEXT | TEXT | MEDIUMTEXT | LONGTEXT
       | NCHAR | NVARCHAR | LONG
      )
      VARYING?
      lengthOneDimension? BINARY?
      (charSet charsetName)?
      (COLLATE collationName | BINARY)?                             #stringDataType
    | NATIONAL typeName=(VARCHAR | CHARACTER)
      lengthOneDimension? BINARY?                                   #nationalStringDataType
    | NCHAR typeName=VARCHAR
      lengthOneDimension? BINARY?                                   #nationalStringDataType
    | NATIONAL typeName=(CHAR | CHARACTER) VARYING
      lengthOneDimension? BINARY?                                   #nationalVaryingStringDataType
    | typeName=(
        TINYINT | SMALLINT | MEDIUMINT | INT | INTEGER | BIGINT
        | MIDDLEINT | INT1 | INT2 | INT3 | INT4 | INT8
      )
      lengthOneDimension? (SIGNED | UNSIGNED | ZEROFILL)*           #dimensionDataType
    | typeName=REAL
      lengthTwoDimension? (SIGNED | UNSIGNED | ZEROFILL)*           #dimensionDataType
    | typeName=DOUBLE PRECISION?
      lengthTwoDimension? (SIGNED | UNSIGNED | ZEROFILL)*           #dimensionDataType
    | typeName=(DECIMAL | DEC | FIXED | NUMERIC | FLOAT | FLOAT4 | FLOAT8)
      lengthTwoOptionalDimension? (SIGNED | UNSIGNED | ZEROFILL)*   #dimensionDataType
    | typeName=(
        DATE | TINYBLOB | MEDIUMBLOB | LONGBLOB
        | BOOL | BOOLEAN | SERIAL
      )                                                             #simpleDataType
    | typeName=(
        BIT | TIME | TIMESTAMP | DATETIME | BINARY
        | VARBINARY | BLOB | YEAR
      )
      lengthOneDimension?                                           #dimensionDataType
    | typeName=(ENUM | SET)
      collectionOptions BINARY?
      (charSet charsetName)?                                        #collectionDataType
    | typeName=(
        GEOMETRYCOLLECTION | GEOMCOLLECTION | LINESTRING | MULTILINESTRING
        | MULTIPOINT | MULTIPOLYGON | POINT | POLYGON | JSON | GEOMETRY
      )                                                             #spatialDataType
    | typeName=LONG VARCHAR?
      BINARY?
      (charSet charsetName)?
      (COLLATE collationName)?                                      #longVarcharDataType    // LONG VARCHAR is the same as LONG
    | LONG VARBINARY                                                #longVarbinaryDataType
    ;

collectionOptions
    : '(' STRING_LITERAL (',' STRING_LITERAL)* ')'
    ;

convertedDataType
    :
    (
      typeName=(BINARY| NCHAR) lengthOneDimension?
      | typeName=CHAR lengthOneDimension? (charSet charsetName)?
      | typeName=(DATE | DATETIME | TIME | JSON | INT | INTEGER)
      | typeName=DECIMAL lengthTwoOptionalDimension?
      | (SIGNED | UNSIGNED) INTEGER?
      | (FLOAT | FLOAT4 | FLOAT8 | DOUBLE | REAL | (DEC '(' constant ',' constant ')')) // refined
    ) ARRAY?
    ;

lengthOneDimension
    : '(' decimalLiteral ')'
    ;

lengthTwoDimension
    : '(' decimalLiteral ',' decimalLiteral ')'
    ;

lengthTwoOptionalDimension
    : '(' decimalLiteral (',' decimalLiteral)? ')'
    ;


//    Common Lists

uidList
    : uid (',' uid)*
    ;

tables
    : tableName (',' tableName)*
    ;

indexColumnNames
    : '(' indexColumnName (',' indexColumnName)* ')'
    ;

expressions
    : expression (',' expression)*
    ;

expressionsWithDefaults
    : expressionOrDefault (',' expressionOrDefault)*
    ;

constants
    : constant (',' constant)*
    ;

simpleStrings
    : STRING_LITERAL (',' STRING_LITERAL)*
    ;

userVariables
    : LOCAL_ID (',' LOCAL_ID)*
    ;


//    Common Expressons

defaultValue
    : (NULL_LITERAL | unaryOperator? constant | currentTimestamp | '(' expression ')') (ON UPDATE currentTimestamp)?
    ;

currentTimestamp
    :
    (
      (CURRENT_TIMESTAMP | LOCALTIME | LOCALTIMESTAMP) ('(' decimalLiteral? ')')?
      | NOW '(' decimalLiteral? ')'
    )
    ;

expressionOrDefault
    : expression | DEFAULT
    ;

ifExists
    : IF EXISTS;

ifNotExists
    : IF NOT EXISTS;


//    Functions

functionCall
    : specificFunction                                              #specificFunctionCall
    | aggregateWindowedFunction                                     #aggregateFunctionCall
    | nonAggregateWindowedFunction                                  #nonAggregateFunctionCall
    | scalarFunctionName '(' functionArgs? ')'                      #scalarFunctionCall
    | fullId '(' functionArgs? ')'                                  #udfFunctionCall
    | passwordFunctionClause                                        #passwordFunctionCall
    ;

specificFunction
    : (
      CURRENT_DATE | CURRENT_TIME | CURRENT_TIMESTAMP
      | CURRENT_USER | LOCALTIME
      ) ('(' ')')?                                                  #simpleFunctionCall
    | CONVERT '(' expression separator=',' convertedDataType ')'    #dataTypeFunctionCall
    | CONVERT '(' expression USING charsetName ')'                  #dataTypeFunctionCall
    | CAST '(' expression AS convertedDataType ')'                  #dataTypeFunctionCall
    | VALUES '(' fullColumnName ')'                                 #valuesFunctionCall
    | CASE expression caseFuncAlternative+
      (ELSE elseArg=functionArg)? END                               #caseExpressionFunctionCall
    | CASE caseFuncAlternative+
      (ELSE elseArg=functionArg)? END                               #caseFunctionCall
    | CHAR '(' functionArgs  (USING charsetName)? ')'               #charFunctionCall
    | POSITION
      '('
          (
            positionString=stringLiteral
            | positionExpression=expression
          )
          IN
          (
            inString=stringLiteral
            | inExpression=expression
          )
      ')'                                                           #positionFunctionCall
    | (SUBSTR | SUBSTRING)
      '('
        (
          sourceString=stringLiteral
          | sourceExpression=expression
        ) FROM
        (
          fromDecimal=decimalLiteral
          | fromExpression=expression
        )
        (
          FOR
          (
            forDecimal=decimalLiteral
            | forExpression=expression
          )
        )?
      ')'                                                           #substrFunctionCall
    | TRIM
      '('
        positioinForm=(BOTH | LEADING | TRAILING)
        (
          sourceString=stringLiteral
          | sourceExpression=expression
        )?
        FROM
        (
          fromString=stringLiteral
          | fromExpression=expression
        )
      ')'                                                           #trimFunctionCall
    | TRIM
      '('
        (
          sourceString=stringLiteral
          | sourceExpression=expression
        )
        FROM
        (
          fromString=stringLiteral
          | fromExpression=expression
        )
      ')'                                                           #trimFunctionCall
    | WEIGHT_STRING
      '('
        (stringLiteral | expression)
        (AS stringFormat=(CHAR | BINARY)
        '(' decimalLiteral ')' )?  levelsInWeightString?
      ')'                                                           #weightFunctionCall
    | EXTRACT
      '('
        intervalType
        FROM
        (
          sourceString=stringLiteral
          | sourceExpression=expression
        )
      ')'                                                           #extractFunctionCall
    | GET_FORMAT
      '('
        datetimeFormat=(DATE | TIME | DATETIME)
        ',' stringLiteral
      ')'                                                           #getFormatFunctionCall
    | JSON_VALUE
      '(' expression
       ',' expression
         (RETURNING convertedDataType)?
         ((NULL_LITERAL | ERROR | (DEFAULT defaultValue)) ON EMPTY)?
         ((NULL_LITERAL | ERROR | (DEFAULT defaultValue)) ON ERROR)?
       ')'                                                          #jsonValueFunctionCall
    ;

caseFuncAlternative
    : WHEN condition=functionArg
      THEN consequent=functionArg
    ;

levelsInWeightString
    : LEVEL levelInWeightListElement
      (',' levelInWeightListElement)*                               #levelWeightList
    | LEVEL
      firstLevel=decimalLiteral '-' lastLevel=decimalLiteral        #levelWeightRange
    ;

levelInWeightListElement
    : decimalLiteral orderType=(ASC | DESC | REVERSE)?
    ;

aggregateWindowedFunction
    : (AVG | MAX | MIN | SUM)
      '(' aggregator=(ALL | DISTINCT)? functionArg ')' overClause?
    | COUNT '(' (starArg='*' | aggregator=ALL? functionArg | aggregator=DISTINCT functionArgs) ')' overClause?
    | (
        BIT_AND | BIT_OR | BIT_XOR | STD | STDDEV | STDDEV_POP
        | STDDEV_SAMP | VAR_POP | VAR_SAMP | VARIANCE
      ) '(' aggregator=ALL? functionArg ')' overClause?
    | GROUP_CONCAT '('
        aggregator=DISTINCT? functionArgs
        (ORDER BY
          orderByExpression (',' orderByExpression)*
        )? (SEPARATOR separator=STRING_LITERAL)?
      ')'
    ;

nonAggregateWindowedFunction
//    : (LAG | LEAD) '(' expression (',' decimalLiteral)? (',' decimalLiteral)? ')' overClause
    : (LAG | LEAD) '(' expression (',' decimalLiteral)? (',' expression)? ')' overClause // refined
    | (FIRST_VALUE | LAST_VALUE) '(' expression ')' overClause
    | (CUME_DIST | DENSE_RANK | PERCENT_RANK | RANK | ROW_NUMBER) '('')' overClause
    | NTH_VALUE '(' expression ',' decimalLiteral ')' overClause
    | NTILE '(' decimalLiteral ')' overClause
    ;

overClause
    : OVER ('(' windowSpec? ')' | windowName)
    ;

windowSpec
    : windowName? partitionClause? orderByClause? frameClause?
    ;

windowName
    : uid
    ;

frameClause
    : frameUnits frameExtent
    ;

frameUnits
    : ROWS
    | RANGE
    ;

frameExtent
    : frameRange
    | frameBetween
    ;

frameBetween
    : BETWEEN frameRange AND frameRange
    ;

frameRange
    : CURRENT ROW
    | UNBOUNDED (PRECEDING | FOLLOWING)
    | expression (PRECEDING | FOLLOWING)
    ;

partitionClause
    : PARTITION BY expression (',' expression)*
    ;

scalarFunctionName
    : functionNameBase
    | ASCII | CURDATE | CURRENT_DATE | CURRENT_TIME
    | CURRENT_TIMESTAMP | CURTIME | DATE_ADD | DATE_SUB
    | IF | INSERT | LOCALTIME | LOCALTIMESTAMP | MID | NOW
    | REPLACE | SUBSTR | SUBSTRING | SYSDATE | TRIM
    | UTC_DATE | UTC_TIME | UTC_TIMESTAMP
    | DIV // refined
    ;

passwordFunctionClause
    : functionName=(PASSWORD | OLD_PASSWORD) '(' functionArg ')'
    ;

functionArgs
    : (constant | fullColumnName | functionCall | expression) orderByClause? // refined psql
    (
      ','
      (constant | fullColumnName | functionCall | expression) orderByClause? // refined psql
    )*
    ;

functionArg
    : constant | fullColumnName | functionCall | expression
    ;


//    Expressions, predicates

// Simplified approach for expression
expression
    : notOperator=(NOT | '!') expression                            #notExpression
    | expression logicalOperator expression                         #logicalExpression
    | predicate IS NOT? testValue=(TRUE | FALSE | UNKNOWN)          #isExpression
    | predicate                                                     #predicateExpression
    ;

predicate
    : predicate NOT? IN '(' (selectStatement | expressions) ')'     #inPredicate
    | predicate IS nullNotnull                                      #isNullPredicate
    | left=predicate comparisonOperator right=predicate             #binaryComparisonPredicate
    | predicate comparisonOperator
      quantifier=(ALL | ANY | SOME) '(' selectStatement ')'         #subqueryComparisonPredicate
    | predicate NOT? BETWEEN predicate AND predicate                #betweenPredicate
    | predicate SOUNDS LIKE predicate                               #soundsLikePredicate
    | predicate NOT? LIKE predicate (ESCAPE STRING_LITERAL)?        #likePredicate
    | predicate NOT? regex=(REGEXP | RLIKE) predicate               #regexpPredicate
    | (LOCAL_ID VAR_ASSIGN)? expressionAtom                         #expressionAtomPredicate
    | predicate MEMBER OF '(' predicate ')'                         #jsonMemberOfPredicate
    ;


// Add in ASTVisitor nullNotnull in constant
expressionAtom
    : datetimeFormat=(DATE | TIME | DATETIME | TIMESTAMP)? constant #constantExpressionAtom // refined
    | fullColumnName                                                #fullColumnNameExpressionAtom
    | functionCall                                                  #functionCallExpressionAtom
    | expressionAtom COLLATE collationName                          #collateExpressionAtom
    | mysqlVariable                                                 #mysqlVariableExpressionAtom
    | unaryOperator expressionAtom                                  #unaryExpressionAtom
    | BINARY expressionAtom                                         #binaryExpressionAtom
    | '(' expression (',' expression)* ')'                          #nestedExpressionAtom
    | ROW '(' expression (',' expression)+ ')'                      #nestedRowExpressionAtom
    | EXISTS '(' selectStatement ')'                                #existsExpressionAtom
    | '(' selectStatement ')'                                       #subqueryExpressionAtom
    | INTERVAL (constant | (expression intervalType))               #intervalExpressionAtom // refined constant
    | left=expressionAtom bitOperator right=expressionAtom          #bitExpressionAtom
    | left=expressionAtom mathOperator right=expressionAtom         #mathExpressionAtom
    | left=expressionAtom jsonOperator right=expressionAtom         #jsonExpressionAtom
    ;

unaryOperator
    : '!' | '~' | '+' | '-' | NOT
    ;

comparisonOperator
    : '=' | '>' | '<' | '<' '=' | '>' '='
    | '<' '>' | '!' '=' | '<' '=' '>'
    ;

logicalOperator
    : AND | '&' '&' | XOR | OR | '|' '|'
    ;

bitOperator
    : '<' '<' | '>' '>' | '&' | '^' | '|'
    ;

mathOperator
    : '*' | '/' | '%' | DIV | MOD | '+' | '-'
    ;

jsonOperator
    : '-' '>' | '-' '>' '>'
    ;

//    Simple id sets
//     (that keyword, which can be id)

charsetNameBase
    : ARMSCII8 | ASCII | BIG5 | BINARY | CP1250 | CP1251 | CP1256 | CP1257
    | CP850 | CP852 | CP866 | CP932 | DEC8 | EUCJPMS | EUCKR
    | GB18030 | GB2312 | GBK | GEOSTD8 | GREEK | HEBREW | HP8 | KEYBCS2
    | KOI8R | KOI8U | LATIN1 | LATIN2 | LATIN5 | LATIN7 | MACCE
    | MACROMAN | SJIS | SWE7 | TIS620 | UCS2 | UJIS | UTF16
    | UTF16LE | UTF32 | UTF8 | UTF8MB3 | UTF8MB4
    ;

transactionLevelBase
    : REPEATABLE | COMMITTED | UNCOMMITTED | SERIALIZABLE
    ;

privilegesBase
    : TABLES | ROUTINE | EXECUTE | FILE | PROCESS
    | RELOAD | SHUTDOWN | SUPER | PRIVILEGES
    ;

intervalTypeBase
    : QUARTER | MONTH | DAY | HOUR
    | MINUTE | WEEK | SECOND | MICROSECOND
    ;

dataTypeBase
    : DATE | TIME | TIMESTAMP | DATETIME | YEAR | ENUM | TEXT
    ;

keywordsCanBeId
    : ACCOUNT | ACTION | ADMIN | AFTER | AGGREGATE | ALGORITHM | ANY
    | AT | AUDIT_ADMIN | AUTHORS | AUTOCOMMIT | AUTOEXTEND_SIZE
    | AUTO_INCREMENT | AVG | AVG_ROW_LENGTH | BACKUP_ADMIN | BEGIN | BINLOG | BINLOG_ADMIN | BINLOG_ENCRYPTION_ADMIN | BIT | BIT_AND | BIT_OR | BIT_XOR
    | BLOCK | BOOL | BOOLEAN | BTREE | CACHE | CASCADED | CHAIN | CHANGED
    | CHANNEL | CHECKSUM | PAGE_CHECKSUM | CATALOG_NAME | CIPHER
    | CLASS_ORIGIN | CLIENT | CLONE_ADMIN | CLOSE | CLUSTERING | COALESCE | CODE
    | COLUMNS | COLUMN_FORMAT | COLUMN_NAME | COMMENT | COMMIT | COMPACT
    | COMPLETION | COMPRESSED | COMPRESSION | CONCURRENT | CONNECT
    | CONNECTION | CONNECTION_ADMIN | CONSISTENT | CONSTRAINT_CATALOG | CONSTRAINT_NAME
    | CONSTRAINT_SCHEMA | CONTAINS | CONTEXT
    | CONTRIBUTORS | COPY | COUNT | CPU | CURRENT | CURSOR_NAME
    | DATA | DATAFILE | DEALLOCATE
    | DEFAULT_AUTH | DEFINER | DELAY_KEY_WRITE | DES_KEY_FILE | DIAGNOSTICS | DIRECTORY
    | DISABLE | DISCARD | DISK | DO | DUMPFILE | DUPLICATE
    | DYNAMIC | ENABLE | ENCRYPTION | ENCRYPTION_KEY_ADMIN | END | ENDS | ENGINE | ENGINE_ATTRIBUTE | ENGINES
    | ERROR | ERRORS | ESCAPE | EUR | EVEN | EVENT | EVENTS | EVERY | EXCEPT
    | EXCHANGE | EXCLUSIVE | EXPIRE | EXPORT | EXTENDED | EXTENT_SIZE | FAST | FAULTS
    | FIELDS | FILE_BLOCK_SIZE | FILTER | FIREWALL_ADMIN | FIREWALL_USER | FIRST | FIXED | FLUSH
    | FOLLOWS | FOUND | FULL | FUNCTION | GENERAL | GLOBAL | GRANTS | GROUP | GROUP_CONCAT
    | GROUP_REPLICATION | GROUP_REPLICATION_ADMIN | HANDLER | HASH | HELP | HOST | HOSTS | IDENTIFIED
    | IGNORED | IGNORE_SERVER_IDS | IMPORT | INDEXES | INITIAL_SIZE | INNODB_REDO_LOG_ARCHIVE
    | INPLACE | INSERT_METHOD | INSTALL | INSTANCE | INSTANT | INTERNAL | INVOKER | IO
    | IO_THREAD | IPC | ISO | ISOLATION | ISSUER | JIS | JSON | KEY_BLOCK_SIZE
    | LANGUAGE | LAST | LEAVES | LESS | LEVEL | LIST | LOCAL
    | LOGFILE | LOGS | MASTER | MASTER_AUTO_POSITION
    | MASTER_CONNECT_RETRY | MASTER_DELAY
    | MASTER_HEARTBEAT_PERIOD | MASTER_HOST | MASTER_LOG_FILE
    | MASTER_LOG_POS | MASTER_PASSWORD | MASTER_PORT
    | MASTER_RETRY_COUNT | MASTER_SSL | MASTER_SSL_CA
    | MASTER_SSL_CAPATH | MASTER_SSL_CERT | MASTER_SSL_CIPHER
    | MASTER_SSL_CRL | MASTER_SSL_CRLPATH | MASTER_SSL_KEY
    | MASTER_TLS_VERSION | MASTER_USER
    | MAX_CONNECTIONS_PER_HOUR | MAX_QUERIES_PER_HOUR
    | MAX | MAX_ROWS | MAX_SIZE | MAX_UPDATES_PER_HOUR
    | MAX_USER_CONNECTIONS | MEDIUM | MEMBER | MEMORY | MERGE | MESSAGE_TEXT
    | MID | MIGRATE
    | MIN | MIN_ROWS | MODE | MODIFY | MUTEX | MYSQL | MYSQL_ERRNO | NAME | NAMES
    | NCHAR | NDB_STORED_USER | NEVER | NEXT | NO | NOCOPY | NODEGROUP | NONE | NOWAIT | NUMBER | ODBC | OFFLINE | OFFSET
    | OF | OJ | OLD_PASSWORD | ONE | ONLINE | ONLY | OPEN | OPTIMIZER_COSTS
    | OPTIONAL | OPTIONS | ORDER | OWNER | PACK_KEYS | PAGE | PARSER | PARTIAL
    | PARTITIONING | PARTITIONS | PASSWORD | PERSIST_RO_VARIABLES_ADMIN | PHASE | PLUGINS
    | PLUGIN_DIR | PLUGIN | PORT | PRECEDES | PREPARE | PRESERVE | PREV
    | PROCESSLIST | PROFILE | PROFILES | PROXY | QUERY | QUICK
    | REBUILD | RECOVER | RECURSIVE | REDO_BUFFER_SIZE | REDUNDANT
    | RELAY | RELAYLOG | RELAY_LOG_FILE | RELAY_LOG_POS | REMOVE
    | REORGANIZE | REPAIR | REPLICATE_DO_DB | REPLICATE_DO_TABLE
    | REPLICATE_IGNORE_DB | REPLICATE_IGNORE_TABLE
    | REPLICATE_REWRITE_DB | REPLICATE_WILD_DO_TABLE
    | REPLICATE_WILD_IGNORE_TABLE | REPLICATION | REPLICATION_APPLIER | REPLICATION_SLAVE_ADMIN | RESET
    | RESOURCE_GROUP_ADMIN | RESOURCE_GROUP_USER | RESUME
    | RETURNED_SQLSTATE | RETURNS | ROLE | ROLE_ADMIN | ROLLBACK | ROLLUP | ROTATE | ROW | ROWS
    | ROW_FORMAT | RTREE | SAVEPOINT | SCHEDULE | SCHEMA_NAME | SECURITY | SECONDARY_ENGINE_ATTRIBUTE | SERIAL | SERVER
    | SESSION | SESSION_VARIABLES_ADMIN | SET_USER_ID | SHARE | SHARED | SHOW_ROUTINE | SIGNED | SIMPLE | SLAVE
    | SLOW | SNAPSHOT | SOCKET | SOME | SONAME | SOUNDS | SOURCE
    | SQL_AFTER_GTIDS | SQL_AFTER_MTS_GAPS | SQL_BEFORE_GTIDS
    | SQL_BUFFER_RESULT | SQL_CACHE | SQL_NO_CACHE | SQL_THREAD
    | STACKED | START | STARTS | STATS_AUTO_RECALC | STATS_PERSISTENT
    | STATS_SAMPLE_PAGES | STATUS | STD | STDDEV | STDDEV_POP | STDDEV_SAMP | STOP | STORAGE | STRING
    | SUBCLASS_ORIGIN | SUBJECT | SUBPARTITION | SUBPARTITIONS | SUM | SUSPEND | SWAPS
    | SWITCHES | SYSTEM_VARIABLES_ADMIN | TABLE_NAME | TABLESPACE | TABLE_ENCRYPTION_ADMIN
    | TEMPORARY | TEMPTABLE | THAN | TRADITIONAL
    | TRANSACTION | TRANSACTIONAL | TRIGGERS | TRUNCATE | UNDEFINED | UNDOFILE
    | UNDO_BUFFER_SIZE | UNINSTALL | UNKNOWN | UNTIL | UPGRADE | USA | USER | USE_FRM | USER_RESOURCES
    | VALIDATION | VALUE | VAR_POP | VAR_SAMP | VARIABLES | VARIANCE | VERSION_TOKEN_ADMIN | VIEW | WAIT | WARNINGS | WITHOUT
    | WORK | WRAPPER | X509 | XA | XA_RECOVER_ADMIN | XML
    ;

functionNameBase
    : ABS | ACOS | ADDDATE | ADDTIME | AES_DECRYPT | AES_ENCRYPT
    | AREA | ASBINARY | ASIN | ASTEXT | ASWKB | ASWKT
    | ASYMMETRIC_DECRYPT | ASYMMETRIC_DERIVE
    | ASYMMETRIC_ENCRYPT | ASYMMETRIC_SIGN | ASYMMETRIC_VERIFY
    | ATAN | ATAN2 | BENCHMARK | BIN | BIT_COUNT | BIT_LENGTH
    | BUFFER | CEIL | CEILING | CENTROID | CHARACTER_LENGTH
    | CHARSET | CHAR_LENGTH | COERCIBILITY | COLLATION
    | COMPRESS | CONCAT | CONCAT_WS | CONNECTION_ID | CONV
    | CONVERT_TZ | COS | COT | COUNT | CRC32
    | CREATE_ASYMMETRIC_PRIV_KEY | CREATE_ASYMMETRIC_PUB_KEY
    | CREATE_DH_PARAMETERS | CREATE_DIGEST | CROSSES | CUME_DIST | DATABASE | DATE
    | DATEDIFF | DATE_FORMAT | DAY | DAYNAME | DAYOFMONTH
    | DAYOFWEEK | DAYOFYEAR | DECODE | DEGREES | DENSE_RANK | DES_DECRYPT
    | DES_ENCRYPT | DIMENSION | DISJOINT | ELT | ENCODE
    | ENCRYPT | ENDPOINT | ENVELOPE | EQUALS | EXP | EXPORT_SET
    | EXTERIORRING | EXTRACTVALUE | FIELD | FIND_IN_SET | FIRST_VALUE | FLOOR
    | FORMAT | FOUND_ROWS | FROM_BASE64 | FROM_DAYS
    | FROM_UNIXTIME | GEOMCOLLFROMTEXT | GEOMCOLLFROMWKB
    | GEOMETRYCOLLECTION | GEOMETRYCOLLECTIONFROMTEXT
    | GEOMETRYCOLLECTIONFROMWKB | GEOMETRYFROMTEXT
    | GEOMETRYFROMWKB | GEOMETRYN | GEOMETRYTYPE | GEOMFROMTEXT
    | GEOMFROMWKB | GET_FORMAT | GET_LOCK | GLENGTH | GREATEST
    | GTID_SUBSET | GTID_SUBTRACT | HEX | HOUR | IFNULL
    | INET6_ATON | INET6_NTOA | INET_ATON | INET_NTOA | INSTR
    | INTERIORRINGN | INTERSECTS | INVISIBLE
    | ISCLOSED | ISEMPTY | ISNULL
    | ISSIMPLE | IS_FREE_LOCK | IS_IPV4 | IS_IPV4_COMPAT
    | IS_IPV4_MAPPED | IS_IPV6 | IS_USED_LOCK | LAG | LAST_INSERT_ID | LAST_VALUE
    | LCASE | LEAD | LEAST | LEFT | LENGTH | LINEFROMTEXT | LINEFROMWKB
    | LINESTRING | LINESTRINGFROMTEXT | LINESTRINGFROMWKB | LN
    | LOAD_FILE | LOCATE | LOG | LOG10 | LOG2 | LOWER | LPAD
    | LTRIM | MAKEDATE | MAKETIME | MAKE_SET | MASTER_POS_WAIT
    | MBRCONTAINS | MBRDISJOINT | MBREQUAL | MBRINTERSECTS
    | MBROVERLAPS | MBRTOUCHES | MBRWITHIN | MD5 | MICROSECOND
    | MINUTE | MLINEFROMTEXT | MLINEFROMWKB | MOD| MONTH | MONTHNAME
    | MPOINTFROMTEXT | MPOINTFROMWKB | MPOLYFROMTEXT
    | MPOLYFROMWKB | MULTILINESTRING | MULTILINESTRINGFROMTEXT
    | MULTILINESTRINGFROMWKB | MULTIPOINT | MULTIPOINTFROMTEXT
    | MULTIPOINTFROMWKB | MULTIPOLYGON | MULTIPOLYGONFROMTEXT
    | MULTIPOLYGONFROMWKB | NAME_CONST | NTH_VALUE | NTILE | NULLIF | NUMGEOMETRIES
    | NUMINTERIORRINGS | NUMPOINTS | OCT | OCTET_LENGTH | ORD
    | OVERLAPS | PERCENT_RANK | PERIOD_ADD | PERIOD_DIFF | PI | POINT
    | POINTFROMTEXT | POINTFROMWKB | POINTN | POLYFROMTEXT
    | POLYFROMWKB | POLYGON | POLYGONFROMTEXT | POLYGONFROMWKB
    | POSITION | POW | POWER | QUARTER | QUOTE | RADIANS | RAND | RANK
    | RANDOM_BYTES | RELEASE_LOCK | REVERSE | RIGHT | ROUND
    | ROW_COUNT | ROW_NUMBER | RPAD | RTRIM | SECOND | SEC_TO_TIME
    | SCHEMA | SESSION_USER | SESSION_VARIABLES_ADMIN
    | SHA | SHA1 | SHA2 | SIGN | SIN | SLEEP
    | SOUNDEX | SQL_THREAD_WAIT_AFTER_GTIDS | SQRT | SRID
    | STARTPOINT | STRCMP | STR_TO_DATE | ST_AREA | ST_ASBINARY
    | ST_ASTEXT | ST_ASWKB | ST_ASWKT | ST_BUFFER | ST_CENTROID
    | ST_CONTAINS | ST_CROSSES | ST_DIFFERENCE | ST_DIMENSION
    | ST_DISJOINT | ST_DISTANCE | ST_ENDPOINT | ST_ENVELOPE
    | ST_EQUALS | ST_EXTERIORRING | ST_GEOMCOLLFROMTEXT
    | ST_GEOMCOLLFROMTXT | ST_GEOMCOLLFROMWKB
    | ST_GEOMETRYCOLLECTIONFROMTEXT
    | ST_GEOMETRYCOLLECTIONFROMWKB | ST_GEOMETRYFROMTEXT
    | ST_GEOMETRYFROMWKB | ST_GEOMETRYN | ST_GEOMETRYTYPE
    | ST_GEOMFROMTEXT | ST_GEOMFROMWKB | ST_INTERIORRINGN
    | ST_INTERSECTION | ST_INTERSECTS | ST_ISCLOSED | ST_ISEMPTY
    | ST_ISSIMPLE | ST_LINEFROMTEXT | ST_LINEFROMWKB
    | ST_LINESTRINGFROMTEXT | ST_LINESTRINGFROMWKB
    | ST_NUMGEOMETRIES | ST_NUMINTERIORRING
    | ST_NUMINTERIORRINGS | ST_NUMPOINTS | ST_OVERLAPS
    | ST_POINTFROMTEXT | ST_POINTFROMWKB | ST_POINTN
    | ST_POLYFROMTEXT | ST_POLYFROMWKB | ST_POLYGONFROMTEXT
    | ST_POLYGONFROMWKB | ST_SRID | ST_STARTPOINT
    | ST_SYMDIFFERENCE | ST_TOUCHES | ST_UNION | ST_WITHIN
    | ST_X | ST_Y | SUBDATE | SUBSTRING_INDEX | SUBTIME
    | SYSTEM_USER | TAN | TIME | TIMEDIFF | TIMESTAMP
    | TIMESTAMPADD | TIMESTAMPDIFF | TIME_FORMAT | TIME_TO_SEC
    | TOUCHES | TO_BASE64 | TO_DAYS | TO_SECONDS | UCASE
    | UNCOMPRESS | UNCOMPRESSED_LENGTH | UNHEX | UNIX_TIMESTAMP
    | UPDATEXML | UPPER | UUID | UUID_SHORT
    | VALIDATE_PASSWORD_STRENGTH | VERSION | VISIBLE
    | WAIT_UNTIL_SQL_THREAD_AFTER_GTIDS | WEEK | WEEKDAY
    | WEEKOFYEAR | WEIGHT_STRING | WITHIN | YEAR | YEARWEEK
    | Y_FUNCTION | X_FUNCTION
    | JSON_ARRAY | JSON_OBJECT | JSON_QUOTE | JSON_CONTAINS | JSON_CONTAINS_PATH
    | JSON_EXTRACT | JSON_KEYS | JSON_OVERLAPS | JSON_SEARCH | JSON_VALUE
    | JSON_ARRAY_APPEND | JSON_ARRAY_INSERT | JSON_INSERT | JSON_MERGE
    | JSON_MERGE_PATCH | JSON_MERGE_PRESERVE | JSON_REMOVE | JSON_REPLACE
    | JSON_SET | JSON_UNQUOTE | JSON_DEPTH | JSON_LENGTH | JSON_TYPE
    | JSON_VALID | JSON_TABLE | JSON_SCHEMA_VALID | JSON_SCHEMA_VALIDATION_REPORT
    | JSON_PRETTY | JSON_STORAGE_FREE | JSON_STORAGE_SIZE | JSON_ARRAYAGG
    | JSON_OBJECTAGG
    ;



// SKIP

SPACE:                               [ \t\r\n]+    -> channel(HIDDEN);
SPEC_MYSQL_COMMENT:                  '/*!' .+? '*/' -> channel(HIDDEN);
COMMENT_INPUT:                       '/*' .*? '*/' -> channel(HIDDEN);
LINE_COMMENT:                        (
                                       ('--' [ \t] | '#') ~[\r\n]* ('\r'? '\n' | EOF)
                                       | '--' ('\r'? '\n' | EOF)
                                     ) -> channel(HIDDEN);


// Keywords
// Common Keywords

ADD:                                 'ADD';
ALL:                                 'ALL';
ALTER:                               'ALTER';
ALWAYS:                              'ALWAYS';
ANALYZE:                             'ANALYZE';
AND:                                 'AND';
ARRAY:                               'ARRAY';
AS:                                  'AS';
ASC:                                 'ASC';
BEFORE:                              'BEFORE';
BETWEEN:                             'BETWEEN';
BOTH:                                'BOTH';
BUCKETS:                             'BUCKETS';
BY:                                  'BY';
CALL:                                'CALL';
CASCADE:                             'CASCADE';
CASE:                                'CASE';
CAST:                                'CAST';
CHANGE:                              'CHANGE';
CHARACTER:                           'CHARACTER';
CHECK:                               'CHECK';
COLLATE:                             'COLLATE';
COLUMN:                              'COLUMN';
CONDITION:                           'CONDITION';
CONSTRAINT:                          'CONSTRAINT';
CONTINUE:                            'CONTINUE';
CONVERT:                             'CONVERT';
CREATE:                              'CREATE';
CROSS:                               'CROSS';
CURRENT:                             'CURRENT';
CURRENT_USER:                        'CURRENT_USER';
CURSOR:                              'CURSOR';
DATABASE:                            'DATABASE';
DATABASES:                           'DATABASES';
DECLARE:                             'DECLARE';
DEFAULT:                             'DEFAULT';
DELAYED:                             'DELAYED';
DELETE:                              'DELETE';
DESC:                                'DESC';
DESCRIBE:                            'DESCRIBE';
DETERMINISTIC:                       'DETERMINISTIC';
DIAGNOSTICS:                         'DIAGNOSTICS';
DISTINCT:                            'DISTINCT';
DISTINCTROW:                         'DISTINCTROW';
DROP:                                'DROP';
EACH:                                'EACH';
ELSE:                                'ELSE';
ELSEIF:                              'ELSEIF';
EMPTY:                               'EMPTY';
ENCLOSED:                            'ENCLOSED';
ESCAPED:                             'ESCAPED';
EXCEPT:                              'EXCEPT';
EXISTS:                              'EXISTS';
EXIT:                                'EXIT';
EXPLAIN:                             'EXPLAIN';
FALSE:                               'FALSE';
FETCH:                               'FETCH';
FOR:                                 'FOR';
FORCE:                               'FORCE';
FOREIGN:                             'FOREIGN';
FROM:                                'FROM';
FULLTEXT:                            'FULLTEXT';
GENERATED:                           'GENERATED';
GET:                                 'GET';
GRANT:                               'GRANT';
GROUP:                               'GROUP';
HAVING:                              'HAVING';
HIGH_PRIORITY:                       'HIGH_PRIORITY';
HISTOGRAM:                           'HISTOGRAM';
IF:                                  'IF';
IGNORE:                              'IGNORE';
IGNORED:                             'IGNORED';
IN:                                  'IN';
INDEX:                               'INDEX';
INFILE:                              'INFILE';
INNER:                               'INNER';
INOUT:                               'INOUT';
INSERT:                              'INSERT';
INTERVAL:                            'INTERVAL';
INTO:                                'INTO';
IS:                                  'IS';
ITERATE:                             'ITERATE';
JOIN:                                'JOIN';
KEY:                                 'KEY';
KEYS:                                'KEYS';
KILL:                                'KILL';
LEADING:                             'LEADING';
LEAVE:                               'LEAVE';
LEFT:                                'LEFT';
LIKE:                                'LIKE';
LIMIT:                               'LIMIT';
LINEAR:                              'LINEAR';
LINES:                               'LINES';
LOAD:                                'LOAD';
LOCK:                                'LOCK';
LOOP:                                'LOOP';
LOW_PRIORITY:                        'LOW_PRIORITY';
MASTER_BIND:                         'MASTER_BIND';
MASTER_SSL_VERIFY_SERVER_CERT:       'MASTER_SSL_VERIFY_SERVER_CERT';
MATCH:                               'MATCH';
MAXVALUE:                            'MAXVALUE';
MODIFIES:                            'MODIFIES';
NATURAL:                             'NATURAL';
NOT:                                 'NOT';
NO_WRITE_TO_BINLOG:                  'NO_WRITE_TO_BINLOG';
NULL_LITERAL:                        'NULL';
NUMBER:                              'NUMBER';
ON:                                  'ON';
OPTIMIZE:                            'OPTIMIZE';
OPTION:                              'OPTION';
OPTIONAL:                            'OPTIONAL';
OPTIONALLY:                          'OPTIONALLY';
OR:                                  'OR';
ORDER:                               'ORDER';
OUT:                                 'OUT';
OVER:                                'OVER';
OUTER:                               'OUTER';
OUTFILE:                             'OUTFILE';
PARTITION:                           'PARTITION';
PRIMARY:                             'PRIMARY';
PROCEDURE:                           'PROCEDURE';
PURGE:                               'PURGE';
RANGE:                               'RANGE';
READ:                                'READ';
READS:                               'READS';
REFERENCES:                          'REFERENCES';
REGEXP:                              'REGEXP';
RELEASE:                             'RELEASE';
RENAME:                              'RENAME';
REPEAT:                              'REPEAT';
REPLACE:                             'REPLACE';
REQUIRE:                             'REQUIRE';
RESIGNAL:                            'RESIGNAL';
RESTRICT:                            'RESTRICT';
RETAIN:                              'RETAIN';
RETURN:                              'RETURN';
REVOKE:                              'REVOKE';
RIGHT:                               'RIGHT';
RLIKE:                               'RLIKE';
SCHEMA:                              'SCHEMA';
SCHEMAS:                             'SCHEMAS';
SELECT:                              'SELECT';
SET:                                 'SET';
SEPARATOR:                           'SEPARATOR';
SHOW:                                'SHOW';
SIGNAL:                              'SIGNAL';
SPATIAL:                             'SPATIAL';
SQL:                                 'SQL';
SQLEXCEPTION:                        'SQLEXCEPTION';
SQLSTATE:                            'SQLSTATE';
SQLWARNING:                          'SQLWARNING';
SQL_BIG_RESULT:                      'SQL_BIG_RESULT';
SQL_CALC_FOUND_ROWS:                 'SQL_CALC_FOUND_ROWS';
SQL_SMALL_RESULT:                    'SQL_SMALL_RESULT';
SSL:                                 'SSL';
STACKED:                             'STACKED';
STARTING:                            'STARTING';
STRAIGHT_JOIN:                       'STRAIGHT_JOIN';
TABLE:                               'TABLE';
TERMINATED:                          'TERMINATED';
THEN:                                'THEN';
TO:                                  'TO';
TRAILING:                            'TRAILING';
TRIGGER:                             'TRIGGER';
TRUE:                                'TRUE';
UNDO:                                'UNDO';
UNION:                               'UNION';
UNIQUE:                              'UNIQUE';
UNLOCK:                              'UNLOCK';
UNSIGNED:                            'UNSIGNED';
UPDATE:                              'UPDATE';
USAGE:                               'USAGE';
USE:                                 'USE';
USING:                               'USING';
VALUES:                              'VALUES';
WHEN:                                'WHEN';
WHERE:                               'WHERE';
WHILE:                               'WHILE';
WITH:                                'WITH';
WRITE:                               'WRITE';
XOR:                                 'XOR';
ZEROFILL:                            'ZEROFILL';


// DATA TYPE Keywords

TINYINT:                             'TINYINT';
SMALLINT:                            'SMALLINT';
MEDIUMINT:                           'MEDIUMINT';
MIDDLEINT:                           'MIDDLEINT';
INT:                                 'INT';
INT1:                                'INT1';
INT2:                                'INT2';
INT3:                                'INT3';
INT4:                                'INT4';
INT8:                                'INT8';
INTEGER:                             'INTEGER';
BIGINT:                              'BIGINT';
REAL:                                'REAL';
DOUBLE:                              'DOUBLE';
PRECISION:                           'PRECISION';
FLOAT:                               'FLOAT';
FLOAT4:                              'FLOAT4';
FLOAT8:                              'FLOAT8';
DECIMAL:                             'DECIMAL';
DEC:                                 'DEC';
NUMERIC:                             'NUMERIC';
DATE:                                'DATE';
TIME:                                'TIME';
TIMESTAMP:                           'TIMESTAMP';
DATETIME:                            'DATETIME';
YEAR:                                'YEAR';
EPOCH:                               'EPOCH';
CHAR:                                'CHAR';
VARCHAR:                             'VARCHAR';
NVARCHAR:                            'NVARCHAR';
NATIONAL:                            'NATIONAL';
BINARY:                              'BINARY';
VARBINARY:                           'VARBINARY';
TINYBLOB:                            'TINYBLOB';
BLOB:                                'BLOB';
MEDIUMBLOB:                          'MEDIUMBLOB';
LONG:                                'LONG';
LONGBLOB:                            'LONGBLOB';
TINYTEXT:                            'TINYTEXT';
TEXT:                                'TEXT';
MEDIUMTEXT:                          'MEDIUMTEXT';
LONGTEXT:                            'LONGTEXT';
ENUM:                                'ENUM';
VARYING:                             'VARYING';
SERIAL:                              'SERIAL';


// Interval type Keywords

YEAR_MONTH:                          'YEAR_MONTH';
DAY_HOUR:                            'DAY_HOUR';
DAY_MINUTE:                          'DAY_MINUTE';
DAY_SECOND:                          'DAY_SECOND';
HOUR_MINUTE:                         'HOUR_MINUTE';
HOUR_SECOND:                         'HOUR_SECOND';
MINUTE_SECOND:                       'MINUTE_SECOND';
SECOND_MICROSECOND:                  'SECOND_MICROSECOND';
MINUTE_MICROSECOND:                  'MINUTE_MICROSECOND';
HOUR_MICROSECOND:                    'HOUR_MICROSECOND';
DAY_MICROSECOND:                     'DAY_MICROSECOND';

// JSON keywords
JSON_ARRAY:                          'JSON_ARRAY';
JSON_OBJECT:                         'JSON_OBJECT';
JSON_QUOTE:                          'JSON_QUOTE';
JSON_CONTAINS:                       'JSON_CONTAINS';
JSON_CONTAINS_PATH:                  'JSON_CONTAINS_PATH';
JSON_EXTRACT:                        'JSON_EXTRACT';
JSON_KEYS:                           'JSON_KEYS';
JSON_OVERLAPS:                       'JSON_OVERLAPS';
JSON_SEARCH:                         'JSON_SEARCH';
JSON_VALUE:                          'JSON_VALUE';
JSON_ARRAY_APPEND:                   'JSON_ARRAY_APPEND';
JSON_ARRAY_INSERT:                   'JSON_ARRAY_INSERT';
JSON_INSERT:                         'JSON_INSERT';
JSON_MERGE:                          'JSON_MERGE';
JSON_MERGE_PATCH:                    'JSON_MERGE_PATCH';
JSON_MERGE_PRESERVE:                 'JSON_MERGE_PRESERVE';
JSON_REMOVE:                         'JSON_REMOVE';
JSON_REPLACE:                        'JSON_REPLACE';
JSON_SET:                            'JSON_SET';
JSON_UNQUOTE:                        'JSON_UNQUOTE';
JSON_DEPTH:                          'JSON_DEPTH';
JSON_LENGTH:                         'JSON_LENGTH';
JSON_TYPE:                           'JSON_TYPE';
JSON_VALID:                          'JSON_VALID';
JSON_TABLE:                          'JSON_TABLE';
JSON_SCHEMA_VALID:                   'JSON_SCHEMA_VALID';
JSON_SCHEMA_VALIDATION_REPORT:       'JSON_SCHEMA_VALIDATION_REPORT';
JSON_PRETTY:                         'JSON_PRETTY';
JSON_STORAGE_FREE:                   'JSON_STORAGE_FREE';
JSON_STORAGE_SIZE:                   'JSON_STORAGE_SIZE';
JSON_ARRAYAGG:                       'JSON_ARRAYAGG';
JSON_OBJECTAGG:                      'JSON_OBJECTAGG';

// Group function Keywords

AVG:                                 'AVG';
BIT_AND:                             'BIT_AND';
BIT_OR:                              'BIT_OR';
BIT_XOR:                             'BIT_XOR';
COUNT:                               'COUNT';
CUME_DIST:                           'CUME_DIST';
DENSE_RANK:                          'DENSE_RANK';
FIRST_VALUE:                         'FIRST_VALUE';
GROUP_CONCAT:                        'GROUP_CONCAT';
LAG:                                 'LAG';
LAST_VALUE:                          'LAST_VALUE';
LEAD:                                'LEAD';
MAX:                                 'MAX';
MIN:                                 'MIN';
NTILE:                               'NTILE';
NTH_VALUE:                           'NTH_VALUE';
PERCENT_RANK:                        'PERCENT_RANK';
RANK:                                'RANK';
ROW_NUMBER:                          'ROW_NUMBER';
STD:                                 'STD';
STDDEV:                              'STDDEV';
STDDEV_POP:                          'STDDEV_POP';
STDDEV_SAMP:                         'STDDEV_SAMP';
SUM:                                 'SUM';
VAR_POP:                             'VAR_POP';
VAR_SAMP:                            'VAR_SAMP';
VARIANCE:                            'VARIANCE';

// Common function Keywords

CURRENT_DATE:                        'CURRENT_DATE';
CURRENT_TIME:                        'CURRENT_TIME';
CURRENT_TIMESTAMP:                   'CURRENT_TIMESTAMP';
LOCALTIME:                           'LOCALTIME';
CURDATE:                             'CURDATE';
CURTIME:                             'CURTIME';
DATE_ADD:                            'DATE_ADD';
DATE_SUB:                            'DATE_SUB';
EXTRACT:                             'EXTRACT';
LOCALTIMESTAMP:                      'LOCALTIMESTAMP';
NOW:                                 'NOW';
POSITION:                            'POSITION';
SUBSTR:                              'SUBSTR';
SUBSTRING:                           'SUBSTRING';
SYSDATE:                             'SYSDATE';
TRIM:                                'TRIM';
UTC_DATE:                            'UTC_DATE';
UTC_TIME:                            'UTC_TIME';
UTC_TIMESTAMP:                       'UTC_TIMESTAMP';

// Keywords, but can be ID
// Common Keywords, but can be ID

ACCOUNT:                             'ACCOUNT';
ACTION:                              'ACTION';
AFTER:                               'AFTER';
AGGREGATE:                           'AGGREGATE';
ALGORITHM:                           'ALGORITHM';
ANY:                                 'ANY';
AT:                                  'AT';
AUTHORS:                             'AUTHORS';
AUTOCOMMIT:                          'AUTOCOMMIT';
AUTOEXTEND_SIZE:                     'AUTOEXTEND_SIZE';
AUTO_INCREMENT:                      'AUTO_INCREMENT';
AVG_ROW_LENGTH:                      'AVG_ROW_LENGTH';
BEGIN:                               'BEGIN';
BINLOG:                              'BINLOG';
BIT:                                 'BIT';
BLOCK:                               'BLOCK';
BOOL:                                'BOOL';
BOOLEAN:                             'BOOLEAN';
BTREE:                               'BTREE';
CACHE:                               'CACHE';
CASCADED:                            'CASCADED';
CHAIN:                               'CHAIN';
CHANGED:                             'CHANGED';
CHANNEL:                             'CHANNEL';
CHECKSUM:                            'CHECKSUM';
PAGE_CHECKSUM:                       'PAGE_CHECKSUM';
CIPHER:                              'CIPHER';
CLASS_ORIGIN:                        'CLASS_ORIGIN';
CLIENT:                              'CLIENT';
CLOSE:                               'CLOSE';
CLUSTERING:                          'CLUSTERING';
COALESCE:                            'COALESCE';
CODE:                                'CODE';
COLUMNS:                             'COLUMNS';
COLUMN_FORMAT:                       'COLUMN_FORMAT';
COLUMN_NAME:                         'COLUMN_NAME';
COMMENT:                             'COMMENT';
COMMIT:                              'COMMIT';
COMPACT:                             'COMPACT';
COMPLETION:                          'COMPLETION';
COMPRESSED:                          'COMPRESSED';
COMPRESSION:                         'COMPRESSION';
CONCURRENT:                          'CONCURRENT';
CONNECT:                             'CONNECT';
CONNECTION:                          'CONNECTION';
CONSISTENT:                          'CONSISTENT';
CONSTRAINT_CATALOG:                  'CONSTRAINT_CATALOG';
CONSTRAINT_SCHEMA:                   'CONSTRAINT_SCHEMA';
CONSTRAINT_NAME:                     'CONSTRAINT_NAME';
CONTAINS:                            'CONTAINS';
CONTEXT:                             'CONTEXT';
CONTRIBUTORS:                        'CONTRIBUTORS';
COPY:                                'COPY';
CPU:                                 'CPU';
CURSOR_NAME:                         'CURSOR_NAME';
DATA:                                'DATA';
DATAFILE:                            'DATAFILE';
DEALLOCATE:                          'DEALLOCATE';
DEFAULT_AUTH:                        'DEFAULT_AUTH';
DEFINER:                             'DEFINER';
DELAY_KEY_WRITE:                     'DELAY_KEY_WRITE';
DES_KEY_FILE:                        'DES_KEY_FILE';
DIRECTORY:                           'DIRECTORY';
DISABLE:                             'DISABLE';
DISCARD:                             'DISCARD';
DISK:                                'DISK';
DO:                                  'DO';
DUMPFILE:                            'DUMPFILE';
DUPLICATE:                           'DUPLICATE';
DYNAMIC:                             'DYNAMIC';
ENABLE:                              'ENABLE';
ENCRYPTION:                          'ENCRYPTION';
END:                                 'END';
ENDS:                                'ENDS';
ENGINE:                              'ENGINE';
ENGINES:                             'ENGINES';
ERROR:                               'ERROR';
ERRORS:                              'ERRORS';
ESCAPE:                              'ESCAPE';
EVEN:                                'EVEN';
EVENT:                               'EVENT';
EVENTS:                              'EVENTS';
EVERY:                               'EVERY';
EXCHANGE:                            'EXCHANGE';
EXCLUSIVE:                           'EXCLUSIVE';
EXPIRE:                              'EXPIRE';
EXPORT:                              'EXPORT';
EXTENDED:                            'EXTENDED';
EXTENT_SIZE:                         'EXTENT_SIZE';
FAST:                                'FAST';
FAULTS:                              'FAULTS';
FIELDS:                              'FIELDS';
FILE_BLOCK_SIZE:                     'FILE_BLOCK_SIZE';
FILTER:                              'FILTER';
FIRST:                               'FIRST';
FIXED:                               'FIXED';
FLUSH:                               'FLUSH';
FOLLOWING:                           'FOLLOWING';
FOLLOWS:                             'FOLLOWS';
FOUND:                               'FOUND';
FULL:                                'FULL';
FUNCTION:                            'FUNCTION';
GENERAL:                             'GENERAL';
GLOBAL:                              'GLOBAL';
GRANTS:                              'GRANTS';
GROUP_REPLICATION:                   'GROUP_REPLICATION';
HANDLER:                             'HANDLER';
HASH:                                'HASH';
HELP:                                'HELP';
HOST:                                'HOST';
HOSTS:                               'HOSTS';
IDENTIFIED:                          'IDENTIFIED';
IGNORE_SERVER_IDS:                   'IGNORE_SERVER_IDS';
IMPORT:                              'IMPORT';
INDEXES:                             'INDEXES';
INITIAL_SIZE:                        'INITIAL_SIZE';
INPLACE:                             'INPLACE';
INSERT_METHOD:                       'INSERT_METHOD';
INSTALL:                             'INSTALL';
INSTANCE:                            'INSTANCE';
INSTANT:                             'INSTANT';
INVISIBLE:                           'INVISIBLE';
INVOKER:                             'INVOKER';
IO:                                  'IO';
IO_THREAD:                           'IO_THREAD';
IPC:                                 'IPC';
ISOLATION:                           'ISOLATION';
ISSUER:                              'ISSUER';
JSON:                                'JSON';
KEY_BLOCK_SIZE:                      'KEY_BLOCK_SIZE';
LANGUAGE:                            'LANGUAGE';
LAST:                                'LAST';
LEAVES:                              'LEAVES';
LESS:                                'LESS';
LEVEL:                               'LEVEL';
LIST:                                'LIST';
LOCAL:                               'LOCAL';
LOGFILE:                             'LOGFILE';
LOGS:                                'LOGS';
MASTER:                              'MASTER';
MASTER_AUTO_POSITION:                'MASTER_AUTO_POSITION';
MASTER_CONNECT_RETRY:                'MASTER_CONNECT_RETRY';
MASTER_DELAY:                        'MASTER_DELAY';
MASTER_HEARTBEAT_PERIOD:             'MASTER_HEARTBEAT_PERIOD';
MASTER_HOST:                         'MASTER_HOST';
MASTER_LOG_FILE:                     'MASTER_LOG_FILE';
MASTER_LOG_POS:                      'MASTER_LOG_POS';
MASTER_PASSWORD:                     'MASTER_PASSWORD';
MASTER_PORT:                         'MASTER_PORT';
MASTER_RETRY_COUNT:                  'MASTER_RETRY_COUNT';
MASTER_SSL:                          'MASTER_SSL';
MASTER_SSL_CA:                       'MASTER_SSL_CA';
MASTER_SSL_CAPATH:                   'MASTER_SSL_CAPATH';
MASTER_SSL_CERT:                     'MASTER_SSL_CERT';
MASTER_SSL_CIPHER:                   'MASTER_SSL_CIPHER';
MASTER_SSL_CRL:                      'MASTER_SSL_CRL';
MASTER_SSL_CRLPATH:                  'MASTER_SSL_CRLPATH';
MASTER_SSL_KEY:                      'MASTER_SSL_KEY';
MASTER_TLS_VERSION:                  'MASTER_TLS_VERSION';
MASTER_USER:                         'MASTER_USER';
MAX_CONNECTIONS_PER_HOUR:            'MAX_CONNECTIONS_PER_HOUR';
MAX_QUERIES_PER_HOUR:                'MAX_QUERIES_PER_HOUR';
MAX_ROWS:                            'MAX_ROWS';
MAX_SIZE:                            'MAX_SIZE';
MAX_UPDATES_PER_HOUR:                'MAX_UPDATES_PER_HOUR';
MAX_USER_CONNECTIONS:                'MAX_USER_CONNECTIONS';
MEDIUM:                              'MEDIUM';
MEMBER:                              'MEMBER';
MERGE:                               'MERGE';
MESSAGE_TEXT:                        'MESSAGE_TEXT';
MID:                                 'MID';
MIGRATE:                             'MIGRATE';
MIN_ROWS:                            'MIN_ROWS';
MODE:                                'MODE';
MODIFY:                              'MODIFY';
MUTEX:                               'MUTEX';
MYSQL:                               'MYSQL';
MYSQL_ERRNO:                         'MYSQL_ERRNO';
NAME:                                'NAME';
NAMES:                               'NAMES';
NCHAR:                               'NCHAR';
NEVER:                               'NEVER';
NEXT:                                'NEXT';
NO:                                  'NO';
NOCOPY:                              'NOCOPY';
NOWAIT:                              'NOWAIT';
NODEGROUP:                           'NODEGROUP';
NONE:                                'NONE';
ODBC:                                'ODBC';
OFFLINE:                             'OFFLINE';
OFFSET:                              'OFFSET';
OF:                                  'OF';
OJ:                                  'OJ';
OLD_PASSWORD:                        'OLD_PASSWORD';
ONE:                                 'ONE';
ONLINE:                              'ONLINE';
ONLY:                                'ONLY';
OPEN:                                'OPEN';
OPTIMIZER_COSTS:                     'OPTIMIZER_COSTS';
OPTIONS:                             'OPTIONS';
OWNER:                               'OWNER';
PACK_KEYS:                           'PACK_KEYS';
PAGE:                                'PAGE';
PARSER:                              'PARSER';
PARTIAL:                             'PARTIAL';
PARTITIONING:                        'PARTITIONING';
PARTITIONS:                          'PARTITIONS';
PASSWORD:                            'PASSWORD';
PHASE:                               'PHASE';
PLUGIN:                              'PLUGIN';
PLUGIN_DIR:                          'PLUGIN_DIR';
PLUGINS:                             'PLUGINS';
PORT:                                'PORT';
PRECEDES:                            'PRECEDES';
PRECEDING:                           'PRECEDING';
PREPARE:                             'PREPARE';
PRESERVE:                            'PRESERVE';
PREV:                                'PREV';
PROCESSLIST:                         'PROCESSLIST';
PROFILE:                             'PROFILE';
PROFILES:                            'PROFILES';
PROXY:                               'PROXY';
QUERY:                               'QUERY';
QUICK:                               'QUICK';
REBUILD:                             'REBUILD';
RECOVER:                             'RECOVER';
RECURSIVE:                           'RECURSIVE';
REDO_BUFFER_SIZE:                    'REDO_BUFFER_SIZE';
REDUNDANT:                           'REDUNDANT';
RELAY:                               'RELAY';
RELAY_LOG_FILE:                      'RELAY_LOG_FILE';
RELAY_LOG_POS:                       'RELAY_LOG_POS';
RELAYLOG:                            'RELAYLOG';
REMOVE:                              'REMOVE';
REORGANIZE:                          'REORGANIZE';
REPAIR:                              'REPAIR';
REPLICATE_DO_DB:                     'REPLICATE_DO_DB';
REPLICATE_DO_TABLE:                  'REPLICATE_DO_TABLE';
REPLICATE_IGNORE_DB:                 'REPLICATE_IGNORE_DB';
REPLICATE_IGNORE_TABLE:              'REPLICATE_IGNORE_TABLE';
REPLICATE_REWRITE_DB:                'REPLICATE_REWRITE_DB';
REPLICATE_WILD_DO_TABLE:             'REPLICATE_WILD_DO_TABLE';
REPLICATE_WILD_IGNORE_TABLE:         'REPLICATE_WILD_IGNORE_TABLE';
REPLICATION:                         'REPLICATION';
RESET:                               'RESET';
RESUME:                              'RESUME';
RETURNED_SQLSTATE:                   'RETURNED_SQLSTATE';
RETURNING:                           'RETURNING';
RETURNS:                             'RETURNS';
ROLE:                                'ROLE';
ROLLBACK:                            'ROLLBACK';
ROLLUP:                              'ROLLUP';
ROTATE:                              'ROTATE';
ROW:                                 'ROW';
ROWS:                                'ROWS';
ROW_FORMAT:                          'ROW_FORMAT';
RTREE:                               'RTREE';
SAVEPOINT:                           'SAVEPOINT';
SCHEDULE:                            'SCHEDULE';
SECURITY:                            'SECURITY';
SERVER:                              'SERVER';
SESSION:                             'SESSION';
SHARE:                               'SHARE';
SHARED:                              'SHARED';
SIGNED:                              'SIGNED';
SIMPLE:                              'SIMPLE';
SLAVE:                               'SLAVE';
SLOW:                                'SLOW';
SNAPSHOT:                            'SNAPSHOT';
SOCKET:                              'SOCKET';
SOME:                                'SOME';
SONAME:                              'SONAME';
SOUNDS:                              'SOUNDS';
SOURCE:                              'SOURCE';
SQL_AFTER_GTIDS:                     'SQL_AFTER_GTIDS';
SQL_AFTER_MTS_GAPS:                  'SQL_AFTER_MTS_GAPS';
SQL_BEFORE_GTIDS:                    'SQL_BEFORE_GTIDS';
SQL_BUFFER_RESULT:                   'SQL_BUFFER_RESULT';
SQL_CACHE:                           'SQL_CACHE';
SQL_NO_CACHE:                        'SQL_NO_CACHE';
SQL_THREAD:                          'SQL_THREAD';
START:                               'START';
STARTS:                              'STARTS';
STATS_AUTO_RECALC:                   'STATS_AUTO_RECALC';
STATS_PERSISTENT:                    'STATS_PERSISTENT';
STATS_SAMPLE_PAGES:                  'STATS_SAMPLE_PAGES';
STATUS:                              'STATUS';
STOP:                                'STOP';
STORAGE:                             'STORAGE';
STORED:                              'STORED';
STRING:                              'STRING';
SUBCLASS_ORIGIN:                     'SUBCLASS_ORIGIN';
SUBJECT:                             'SUBJECT';
SUBPARTITION:                        'SUBPARTITION';
SUBPARTITIONS:                       'SUBPARTITIONS';
SUSPEND:                             'SUSPEND';
SWAPS:                               'SWAPS';
SWITCHES:                            'SWITCHES';
TABLE_NAME:                          'TABLE_NAME';
TABLESPACE:                          'TABLESPACE';
TABLE_TYPE:                          'TABLE_TYPE';
TEMPORARY:                           'TEMPORARY';
TEMPTABLE:                           'TEMPTABLE';
THAN:                                'THAN';
TRADITIONAL:                         'TRADITIONAL';
TRANSACTION:                         'TRANSACTION';
TRANSACTIONAL:                       'TRANSACTIONAL';
TRIGGERS:                            'TRIGGERS';
TRUNCATE:                            'TRUNCATE';
UNBOUNDED:                           'UNBOUNDED';
UNDEFINED:                           'UNDEFINED';
UNDOFILE:                            'UNDOFILE';
UNDO_BUFFER_SIZE:                    'UNDO_BUFFER_SIZE';
UNINSTALL:                           'UNINSTALL';
UNKNOWN:                             'UNKNOWN';
UNTIL:                               'UNTIL';
UPGRADE:                             'UPGRADE';
USER:                                'USER';
USE_FRM:                             'USE_FRM';
USER_RESOURCES:                      'USER_RESOURCES';
VALIDATION:                          'VALIDATION';
VALUE:                               'VALUE';
VARIABLES:                           'VARIABLES';
VIEW:                                'VIEW';
VIRTUAL:                             'VIRTUAL';
VISIBLE:                             'VISIBLE';
WAIT:                                'WAIT';
WARNINGS:                            'WARNINGS';
WINDOW:                              'WINDOW';
WITHOUT:                             'WITHOUT';
WORK:                                'WORK';
WRAPPER:                             'WRAPPER';
X509:                                'X509';
XA:                                  'XA';
XML:                                 'XML';
YES:                                 'YES';

// Date format Keywords

EUR:                                 'EUR';
USA:                                 'USA';
JIS:                                 'JIS';
ISO:                                 'ISO';
INTERNAL:                            'INTERNAL';


// Interval type Keywords

QUARTER:                             'QUARTER';
MONTH:                               'MONTH';
DAY:                                 'DAY';
HOUR:                                'HOUR';
MINUTE:                              'MINUTE';
WEEK:                                'WEEK';
SECOND:                              'SECOND';
MICROSECOND:                         'MICROSECOND';


// PRIVILEGES

TABLES:                              'TABLES';
ROUTINE:                             'ROUTINE';
EXECUTE:                             'EXECUTE';
FILE:                                'FILE';
PROCESS:                             'PROCESS';
RELOAD:                              'RELOAD';
SHUTDOWN:                            'SHUTDOWN';
SUPER:                               'SUPER';
PRIVILEGES:                          'PRIVILEGES';
APPLICATION_PASSWORD_ADMIN:          'APPLICATION_PASSWORD_ADMIN';
AUDIT_ADMIN:                         'AUDIT_ADMIN';
BACKUP_ADMIN:                        'BACKUP_ADMIN';
BINLOG_ADMIN:                        'BINLOG_ADMIN';
BINLOG_ENCRYPTION_ADMIN:             'BINLOG_ENCRYPTION_ADMIN';
CLONE_ADMIN:                         'CLONE_ADMIN';
CONNECTION_ADMIN:                    'CONNECTION_ADMIN';
ENCRYPTION_KEY_ADMIN:                'ENCRYPTION_KEY_ADMIN';
FIREWALL_ADMIN:                      'FIREWALL_ADMIN';
FIREWALL_USER:                       'FIREWALL_USER';
FLUSH_OPTIMIZER_COSTS:               'FLUSH_OPTIMIZER_COSTS';
FLUSH_STATUS:                        'FLUSH_STATUS';
FLUSH_TABLES:                        'FLUSH_TABLES';
FLUSH_USER_RESOURCES:                'FLUSH_USER_RESOURCES';
ADMIN:                               'ADMIN';
GROUP_REPLICATION_ADMIN:             'GROUP_REPLICATION_ADMIN';
INNODB_REDO_LOG_ARCHIVE:             'INNODB_REDO_LOG_ARCHIVE';
INNODB_REDO_LOG_ENABLE:              'INNODB_REDO_LOG_ENABLE';
NDB_STORED_USER:                     'NDB_STORED_USER';
PERSIST_RO_VARIABLES_ADMIN:          'PERSIST_RO_VARIABLES_ADMIN';
REPLICATION_APPLIER:                 'REPLICATION_APPLIER';
REPLICATION_SLAVE_ADMIN:             'REPLICATION_SLAVE_ADMIN';
RESOURCE_GROUP_ADMIN:                'RESOURCE_GROUP_ADMIN';
RESOURCE_GROUP_USER:                 'RESOURCE_GROUP_USER';
ROLE_ADMIN:                          'ROLE_ADMIN';
SERVICE_CONNECTION_ADMIN:            'SERVICE_CONNECTION_ADMIN';
SESSION_VARIABLES_ADMIN:             QUOTE_SYMB? 'SESSION_VARIABLES_ADMIN' QUOTE_SYMB?;
SET_USER_ID:                         'SET_USER_ID';
SHOW_ROUTINE:                        'SHOW_ROUTINE';
SYSTEM_VARIABLES_ADMIN:              'SYSTEM_VARIABLES_ADMIN';
TABLE_ENCRYPTION_ADMIN:              'TABLE_ENCRYPTION_ADMIN';
VERSION_TOKEN_ADMIN:                 'VERSION_TOKEN_ADMIN';
XA_RECOVER_ADMIN:                    'XA_RECOVER_ADMIN';


// Charsets

ARMSCII8:                            'ARMSCII8';
ASCII:                               'ASCII';
BIG5:                                'BIG5';
CP1250:                              'CP1250';
CP1251:                              'CP1251';
CP1256:                              'CP1256';
CP1257:                              'CP1257';
CP850:                               'CP850';
CP852:                               'CP852';
CP866:                               'CP866';
CP932:                               'CP932';
DEC8:                                'DEC8';
EUCJPMS:                             'EUCJPMS';
EUCKR:                               'EUCKR';
GB18030:                             'GB18030';
GB2312:                              'GB2312';
GBK:                                 'GBK';
GEOSTD8:                             'GEOSTD8';
GREEK:                               'GREEK';
HEBREW:                              'HEBREW';
HP8:                                 'HP8';
KEYBCS2:                             'KEYBCS2';
KOI8R:                               'KOI8R';
KOI8U:                               'KOI8U';
LATIN1:                              'LATIN1';
LATIN2:                              'LATIN2';
LATIN5:                              'LATIN5';
LATIN7:                              'LATIN7';
MACCE:                               'MACCE';
MACROMAN:                            'MACROMAN';
SJIS:                                'SJIS';
SWE7:                                'SWE7';
TIS620:                              'TIS620';
UCS2:                                'UCS2';
UJIS:                                'UJIS';
UTF16:                               'UTF16';
UTF16LE:                             'UTF16LE';
UTF32:                               'UTF32';
UTF8:                                'UTF8';
UTF8MB3:                             'UTF8MB3';
UTF8MB4:                             'UTF8MB4';


// DB Engines

ARCHIVE:                             'ARCHIVE';
BLACKHOLE:                           'BLACKHOLE';
CSV:                                 'CSV';
FEDERATED:                           'FEDERATED';
INNODB:                              'INNODB';
MEMORY:                              'MEMORY';
MRG_MYISAM:                          'MRG_MYISAM';
MYISAM:                              'MYISAM';
NDB:                                 'NDB';
NDBCLUSTER:                          'NDBCLUSTER';
PERFORMANCE_SCHEMA:                  'PERFORMANCE_SCHEMA';
TOKUDB:                              'TOKUDB';


// Transaction Levels

REPEATABLE:                          'REPEATABLE';
COMMITTED:                           'COMMITTED';
UNCOMMITTED:                         'UNCOMMITTED';
SERIALIZABLE:                        'SERIALIZABLE';


// Spatial data types

GEOMETRYCOLLECTION:                  'GEOMETRYCOLLECTION';
GEOMCOLLECTION:                      'GEOMCOLLECTION';
GEOMETRY:                            'GEOMETRY';
LINESTRING:                          'LINESTRING';
MULTILINESTRING:                     'MULTILINESTRING';
MULTIPOINT:                          'MULTIPOINT';
MULTIPOLYGON:                        'MULTIPOLYGON';
POINT:                               'POINT';
POLYGON:                             'POLYGON';


// Common function names

ABS:                                 'ABS';
ACOS:                                'ACOS';
ADDDATE:                             'ADDDATE';
ADDTIME:                             'ADDTIME';
AES_DECRYPT:                         'AES_DECRYPT';
AES_ENCRYPT:                         'AES_ENCRYPT';
AREA:                                'AREA';
ASBINARY:                            'ASBINARY';
ASIN:                                'ASIN';
ASTEXT:                              'ASTEXT';
ASWKB:                               'ASWKB';
ASWKT:                               'ASWKT';
ASYMMETRIC_DECRYPT:                  'ASYMMETRIC_DECRYPT';
ASYMMETRIC_DERIVE:                   'ASYMMETRIC_DERIVE';
ASYMMETRIC_ENCRYPT:                  'ASYMMETRIC_ENCRYPT';
ASYMMETRIC_SIGN:                     'ASYMMETRIC_SIGN';
ASYMMETRIC_VERIFY:                   'ASYMMETRIC_VERIFY';
ATAN:                                'ATAN';
ATAN2:                               'ATAN2';
BENCHMARK:                           'BENCHMARK';
BIN:                                 'BIN';
BIT_COUNT:                           'BIT_COUNT';
BIT_LENGTH:                          'BIT_LENGTH';
BUFFER:                              'BUFFER';
CATALOG_NAME:                        'CATALOG_NAME';
CEIL:                                'CEIL';
CEILING:                             'CEILING';
CENTROID:                            'CENTROID';
CHARACTER_LENGTH:                    'CHARACTER_LENGTH';
CHARSET:                             'CHARSET';
CHAR_LENGTH:                         'CHAR_LENGTH';
COERCIBILITY:                        'COERCIBILITY';
COLLATION:                           'COLLATION';
COMPRESS:                            'COMPRESS';
CONCAT:                              'CONCAT';
CONCAT_WS:                           'CONCAT_WS';
CONNECTION_ID:                       'CONNECTION_ID';
CONV:                                'CONV';
CONVERT_TZ:                          'CONVERT_TZ';
COS:                                 'COS';
COT:                                 'COT';
CRC32:                               'CRC32';
CREATE_ASYMMETRIC_PRIV_KEY:          'CREATE_ASYMMETRIC_PRIV_KEY';
CREATE_ASYMMETRIC_PUB_KEY:           'CREATE_ASYMMETRIC_PUB_KEY';
CREATE_DH_PARAMETERS:                'CREATE_DH_PARAMETERS';
CREATE_DIGEST:                       'CREATE_DIGEST';
CROSSES:                             'CROSSES';
DATEDIFF:                            'DATEDIFF';
DATE_FORMAT:                         'DATE_FORMAT';
DAYNAME:                             'DAYNAME';
DAYOFMONTH:                          'DAYOFMONTH';
DAYOFWEEK:                           'DAYOFWEEK';
DAYOFYEAR:                           'DAYOFYEAR';
DECODE:                              'DECODE';
DEGREES:                             'DEGREES';
DES_DECRYPT:                         'DES_DECRYPT';
DES_ENCRYPT:                         'DES_ENCRYPT';
DIMENSION:                           'DIMENSION';
DISJOINT:                            'DISJOINT';
ELT:                                 'ELT';
ENCODE:                              'ENCODE';
ENCRYPT:                             'ENCRYPT';
ENDPOINT:                            'ENDPOINT';
ENGINE_ATTRIBUTE:                    'ENGINE_ATTRIBUTE';
ENVELOPE:                            'ENVELOPE';
EQUALS:                              'EQUALS';
EXP:                                 'EXP';
EXPORT_SET:                          'EXPORT_SET';
EXTERIORRING:                        'EXTERIORRING';
EXTRACTVALUE:                        'EXTRACTVALUE';
FIELD:                               'FIELD';
FIND_IN_SET:                         'FIND_IN_SET';
FLOOR:                               'FLOOR';
FORMAT:                              'FORMAT';
FOUND_ROWS:                          'FOUND_ROWS';
FROM_BASE64:                         'FROM_BASE64';
FROM_DAYS:                           'FROM_DAYS';
FROM_UNIXTIME:                       'FROM_UNIXTIME';
GEOMCOLLFROMTEXT:                    'GEOMCOLLFROMTEXT';
GEOMCOLLFROMWKB:                     'GEOMCOLLFROMWKB';
GEOMETRYCOLLECTIONFROMTEXT:          'GEOMETRYCOLLECTIONFROMTEXT';
GEOMETRYCOLLECTIONFROMWKB:           'GEOMETRYCOLLECTIONFROMWKB';
GEOMETRYFROMTEXT:                    'GEOMETRYFROMTEXT';
GEOMETRYFROMWKB:                     'GEOMETRYFROMWKB';
GEOMETRYN:                           'GEOMETRYN';
GEOMETRYTYPE:                        'GEOMETRYTYPE';
GEOMFROMTEXT:                        'GEOMFROMTEXT';
GEOMFROMWKB:                         'GEOMFROMWKB';
GET_FORMAT:                          'GET_FORMAT';
GET_LOCK:                            'GET_LOCK';
GLENGTH:                             'GLENGTH';
GREATEST:                            'GREATEST';
GTID_SUBSET:                         'GTID_SUBSET';
GTID_SUBTRACT:                       'GTID_SUBTRACT';
HEX:                                 'HEX';
IFNULL:                              'IFNULL';
INET6_ATON:                          'INET6_ATON';
INET6_NTOA:                          'INET6_NTOA';
INET_ATON:                           'INET_ATON';
INET_NTOA:                           'INET_NTOA';
INSTR:                               'INSTR';
INTERIORRINGN:                       'INTERIORRINGN';
INTERSECTS:                          'INTERSECTS';
ISCLOSED:                            'ISCLOSED';
ISEMPTY:                             'ISEMPTY';
ISNULL:                              'ISNULL';
ISSIMPLE:                            'ISSIMPLE';
IS_FREE_LOCK:                        'IS_FREE_LOCK';
IS_IPV4:                             'IS_IPV4';
IS_IPV4_COMPAT:                      'IS_IPV4_COMPAT';
IS_IPV4_MAPPED:                      'IS_IPV4_MAPPED';
IS_IPV6:                             'IS_IPV6';
IS_USED_LOCK:                        'IS_USED_LOCK';
LAST_INSERT_ID:                      'LAST_INSERT_ID';
LCASE:                               'LCASE';
LEAST:                               'LEAST';
LENGTH:                              'LENGTH';
LINEFROMTEXT:                        'LINEFROMTEXT';
LINEFROMWKB:                         'LINEFROMWKB';
LINESTRINGFROMTEXT:                  'LINESTRINGFROMTEXT';
LINESTRINGFROMWKB:                   'LINESTRINGFROMWKB';
LN:                                  'LN';
LOAD_FILE:                           'LOAD_FILE';
LOCATE:                              'LOCATE';
LOG:                                 'LOG';
LOG10:                               'LOG10';
LOG2:                                'LOG2';
LOWER:                               'LOWER';
LPAD:                                'LPAD';
LTRIM:                               'LTRIM';
MAKEDATE:                            'MAKEDATE';
MAKETIME:                            'MAKETIME';
MAKE_SET:                            'MAKE_SET';
MASTER_POS_WAIT:                     'MASTER_POS_WAIT';
MBRCONTAINS:                         'MBRCONTAINS';
MBRDISJOINT:                         'MBRDISJOINT';
MBREQUAL:                            'MBREQUAL';
MBRINTERSECTS:                       'MBRINTERSECTS';
MBROVERLAPS:                         'MBROVERLAPS';
MBRTOUCHES:                          'MBRTOUCHES';
MBRWITHIN:                           'MBRWITHIN';
MD5:                                 'MD5';
MLINEFROMTEXT:                       'MLINEFROMTEXT';
MLINEFROMWKB:                        'MLINEFROMWKB';
MONTHNAME:                           'MONTHNAME';
MPOINTFROMTEXT:                      'MPOINTFROMTEXT';
MPOINTFROMWKB:                       'MPOINTFROMWKB';
MPOLYFROMTEXT:                       'MPOLYFROMTEXT';
MPOLYFROMWKB:                        'MPOLYFROMWKB';
MULTILINESTRINGFROMTEXT:             'MULTILINESTRINGFROMTEXT';
MULTILINESTRINGFROMWKB:              'MULTILINESTRINGFROMWKB';
MULTIPOINTFROMTEXT:                  'MULTIPOINTFROMTEXT';
MULTIPOINTFROMWKB:                   'MULTIPOINTFROMWKB';
MULTIPOLYGONFROMTEXT:                'MULTIPOLYGONFROMTEXT';
MULTIPOLYGONFROMWKB:                 'MULTIPOLYGONFROMWKB';
NAME_CONST:                          'NAME_CONST';
NULLIF:                              'NULLIF';
NUMGEOMETRIES:                       'NUMGEOMETRIES';
NUMINTERIORRINGS:                    'NUMINTERIORRINGS';
NUMPOINTS:                           'NUMPOINTS';
OCT:                                 'OCT';
OCTET_LENGTH:                        'OCTET_LENGTH';
ORD:                                 'ORD';
OVERLAPS:                            'OVERLAPS';
PERIOD_ADD:                          'PERIOD_ADD';
PERIOD_DIFF:                         'PERIOD_DIFF';
PI:                                  'PI';
POINTFROMTEXT:                       'POINTFROMTEXT';
POINTFROMWKB:                        'POINTFROMWKB';
POINTN:                              'POINTN';
POLYFROMTEXT:                        'POLYFROMTEXT';
POLYFROMWKB:                         'POLYFROMWKB';
POLYGONFROMTEXT:                     'POLYGONFROMTEXT';
POLYGONFROMWKB:                      'POLYGONFROMWKB';
POW:                                 'POW';
POWER:                               'POWER';
QUOTE:                               'QUOTE';
RADIANS:                             'RADIANS';
RAND:                                'RAND';
RANDOM_BYTES:                        'RANDOM_BYTES';
RELEASE_LOCK:                        'RELEASE_LOCK';
REVERSE:                             'REVERSE';
ROUND:                               'ROUND';
ROW_COUNT:                           'ROW_COUNT';
RPAD:                                'RPAD';
RTRIM:                               'RTRIM';
SEC_TO_TIME:                         'SEC_TO_TIME';
SECONDARY_ENGINE_ATTRIBUTE:          'SECONDARY_ENGINE_ATTRIBUTE';
SESSION_USER:                        'SESSION_USER';
SHA:                                 'SHA';
SHA1:                                'SHA1';
SHA2:                                'SHA2';
SCHEMA_NAME:                         'SCHEMA_NAME';
SIGN:                                'SIGN';
SIN:                                 'SIN';
SLEEP:                               'SLEEP';
SOUNDEX:                             'SOUNDEX';
SQL_THREAD_WAIT_AFTER_GTIDS:         'SQL_THREAD_WAIT_AFTER_GTIDS';
SQRT:                                'SQRT';
SRID:                                'SRID';
STARTPOINT:                          'STARTPOINT';
STRCMP:                              'STRCMP';
STR_TO_DATE:                         'STR_TO_DATE';
ST_AREA:                             'ST_AREA';
ST_ASBINARY:                         'ST_ASBINARY';
ST_ASTEXT:                           'ST_ASTEXT';
ST_ASWKB:                            'ST_ASWKB';
ST_ASWKT:                            'ST_ASWKT';
ST_BUFFER:                           'ST_BUFFER';
ST_CENTROID:                         'ST_CENTROID';
ST_CONTAINS:                         'ST_CONTAINS';
ST_CROSSES:                          'ST_CROSSES';
ST_DIFFERENCE:                       'ST_DIFFERENCE';
ST_DIMENSION:                        'ST_DIMENSION';
ST_DISJOINT:                         'ST_DISJOINT';
ST_DISTANCE:                         'ST_DISTANCE';
ST_ENDPOINT:                         'ST_ENDPOINT';
ST_ENVELOPE:                         'ST_ENVELOPE';
ST_EQUALS:                           'ST_EQUALS';
ST_EXTERIORRING:                     'ST_EXTERIORRING';
ST_GEOMCOLLFROMTEXT:                 'ST_GEOMCOLLFROMTEXT';
ST_GEOMCOLLFROMTXT:                  'ST_GEOMCOLLFROMTXT';
ST_GEOMCOLLFROMWKB:                  'ST_GEOMCOLLFROMWKB';
ST_GEOMETRYCOLLECTIONFROMTEXT:       'ST_GEOMETRYCOLLECTIONFROMTEXT';
ST_GEOMETRYCOLLECTIONFROMWKB:        'ST_GEOMETRYCOLLECTIONFROMWKB';
ST_GEOMETRYFROMTEXT:                 'ST_GEOMETRYFROMTEXT';
ST_GEOMETRYFROMWKB:                  'ST_GEOMETRYFROMWKB';
ST_GEOMETRYN:                        'ST_GEOMETRYN';
ST_GEOMETRYTYPE:                     'ST_GEOMETRYTYPE';
ST_GEOMFROMTEXT:                     'ST_GEOMFROMTEXT';
ST_GEOMFROMWKB:                      'ST_GEOMFROMWKB';
ST_INTERIORRINGN:                    'ST_INTERIORRINGN';
ST_INTERSECTION:                     'ST_INTERSECTION';
ST_INTERSECTS:                       'ST_INTERSECTS';
ST_ISCLOSED:                         'ST_ISCLOSED';
ST_ISEMPTY:                          'ST_ISEMPTY';
ST_ISSIMPLE:                         'ST_ISSIMPLE';
ST_LINEFROMTEXT:                     'ST_LINEFROMTEXT';
ST_LINEFROMWKB:                      'ST_LINEFROMWKB';
ST_LINESTRINGFROMTEXT:               'ST_LINESTRINGFROMTEXT';
ST_LINESTRINGFROMWKB:                'ST_LINESTRINGFROMWKB';
ST_NUMGEOMETRIES:                    'ST_NUMGEOMETRIES';
ST_NUMINTERIORRING:                  'ST_NUMINTERIORRING';
ST_NUMINTERIORRINGS:                 'ST_NUMINTERIORRINGS';
ST_NUMPOINTS:                        'ST_NUMPOINTS';
ST_OVERLAPS:                         'ST_OVERLAPS';
ST_POINTFROMTEXT:                    'ST_POINTFROMTEXT';
ST_POINTFROMWKB:                     'ST_POINTFROMWKB';
ST_POINTN:                           'ST_POINTN';
ST_POLYFROMTEXT:                     'ST_POLYFROMTEXT';
ST_POLYFROMWKB:                      'ST_POLYFROMWKB';
ST_POLYGONFROMTEXT:                  'ST_POLYGONFROMTEXT';
ST_POLYGONFROMWKB:                   'ST_POLYGONFROMWKB';
ST_SRID:                             'ST_SRID';
ST_STARTPOINT:                       'ST_STARTPOINT';
ST_SYMDIFFERENCE:                    'ST_SYMDIFFERENCE';
ST_TOUCHES:                          'ST_TOUCHES';
ST_UNION:                            'ST_UNION';
ST_WITHIN:                           'ST_WITHIN';
ST_X:                                'ST_X';
ST_Y:                                'ST_Y';
SUBDATE:                             'SUBDATE';
SUBSTRING_INDEX:                     'SUBSTRING_INDEX';
SUBTIME:                             'SUBTIME';
SYSTEM_USER:                         'SYSTEM_USER';
TAN:                                 'TAN';
TIMEDIFF:                            'TIMEDIFF';
TIMESTAMPADD:                        'TIMESTAMPADD';
TIMESTAMPDIFF:                       'TIMESTAMPDIFF';
TIME_FORMAT:                         'TIME_FORMAT';
TIME_TO_SEC:                         'TIME_TO_SEC';
TOUCHES:                             'TOUCHES';
TO_BASE64:                           'TO_BASE64';
TO_DAYS:                             'TO_DAYS';
TO_SECONDS:                          'TO_SECONDS';
UCASE:                               'UCASE';
UNCOMPRESS:                          'UNCOMPRESS';
UNCOMPRESSED_LENGTH:                 'UNCOMPRESSED_LENGTH';
UNHEX:                               'UNHEX';
UNIX_TIMESTAMP:                      'UNIX_TIMESTAMP';
UPDATEXML:                           'UPDATEXML';
UPPER:                               'UPPER';
UUID:                                'UUID';
UUID_SHORT:                          'UUID_SHORT';
VALIDATE_PASSWORD_STRENGTH:          'VALIDATE_PASSWORD_STRENGTH';
VERSION:                             'VERSION';
WAIT_UNTIL_SQL_THREAD_AFTER_GTIDS:   'WAIT_UNTIL_SQL_THREAD_AFTER_GTIDS';
WEEKDAY:                             'WEEKDAY';
WEEKOFYEAR:                          'WEEKOFYEAR';
WEIGHT_STRING:                       'WEIGHT_STRING';
WITHIN:                              'WITHIN';
YEARWEEK:                            'YEARWEEK';
Y_FUNCTION:                          'Y';
X_FUNCTION:                          'X';



// Operators
// Operators. Assigns

VAR_ASSIGN:                          ':=';
PLUS_ASSIGN:                         '+=';
MINUS_ASSIGN:                        '-=';
MULT_ASSIGN:                         '*=';
DIV_ASSIGN:                          '/=';
MOD_ASSIGN:                          '%=';
AND_ASSIGN:                          '&=';
XOR_ASSIGN:                          '^=';
OR_ASSIGN:                           '|=';


// Operators. Arithmetics

STAR:                                '*';
DIVIDE:                              '/';
MODULE:                              '%';
PLUS:                                '+';
MINUS:                               '-';
DIV:                                 'DIV';
MOD:                                 'MOD';


// Operators. Comparation

EQUAL_SYMBOL:                        '=';
GREATER_SYMBOL:                      '>';
LESS_SYMBOL:                         '<';
EXCLAMATION_SYMBOL:                  '!';


// Operators. Bit

BIT_NOT_OP:                          '~';
BIT_OR_OP:                           '|';
BIT_AND_OP:                          '&';
BIT_XOR_OP:                          '^';


// Constructors symbols

DOT:                                 '.';
LR_BRACKET:                          '(';
RR_BRACKET:                          ')';
COMMA:                               ',';
SEMI:                                ';';
AT_SIGN:                             '@';
ZERO_DECIMAL:                        '0';
ONE_DECIMAL:                         '1';
TWO_DECIMAL:                         '2';
SINGLE_QUOTE_SYMB:                   '\'';
DOUBLE_QUOTE_SYMB:                   '"';
REVERSE_QUOTE_SYMB:                  '`';
COLON_SYMB:                          ':';

fragment QUOTE_SYMB
    : SINGLE_QUOTE_SYMB | DOUBLE_QUOTE_SYMB | REVERSE_QUOTE_SYMB
    ;



// Charsets

CHARSET_REVERSE_QOUTE_STRING:        '`' CHARSET_NAME '`';



// File's sizes


FILESIZE_LITERAL:                    DEC_DIGIT+ ('K'|'M'|'G'|'T');



// Literal Primitives


START_NATIONAL_STRING_LITERAL:       'N' SQUOTA_STRING;
STRING_LITERAL:                      DQUOTA_STRING | SQUOTA_STRING | BQUOTA_STRING;
DECIMAL_LITERAL:                     DEC_DIGIT+;
HEXADECIMAL_LITERAL:                 'X' '\'' (HEX_DIGIT HEX_DIGIT)+ '\''
                                     | '0X' HEX_DIGIT+;

REAL_LITERAL:                        (DEC_DIGIT+)? '.' DEC_DIGIT+
                                     | DEC_DIGIT+ '.' (DEC_DIGIT+)? // refined
                                     | DEC_DIGIT+ '.' EXPONENT_NUM_PART
                                     | (DEC_DIGIT+)? '.' (DEC_DIGIT+ EXPONENT_NUM_PART)
                                     | DEC_DIGIT+ EXPONENT_NUM_PART;
NULL_SPEC_LITERAL:                   '\\' 'N';
BIT_STRING:                          BIT_STRING_L;
STRING_CHARSET_NAME:                 '_' CHARSET_NAME;




// Hack for dotID
// Prevent recognize string:         .123somelatin AS ((.123), FLOAT_LITERAL), ((somelatin), ID)
//  it must recoginze:               .123somelatin AS ((.), DOT), (123somelatin, ID)

DOT_ID:                              '.' ID_LITERAL;



// Identifiers

ID:                                  ID_LITERAL;
// DOUBLE_QUOTE_ID:                  '"' ~'"'+ '"';
REVERSE_QUOTE_ID:                    '`' ~'`'+ '`';
STRING_USER_NAME:                    (
                                       SQUOTA_STRING | DQUOTA_STRING
                                       | BQUOTA_STRING | ID_LITERAL
                                     ) '@'
                                     (
                                       SQUOTA_STRING | DQUOTA_STRING
                                       | BQUOTA_STRING | ID_LITERAL
                                       | IP_ADDRESS
                                     );
IP_ADDRESS:                          (
                                       [0-9]+ '.' [0-9.]+
                                       | [0-9A-F:]+ ':' [0-9A-F:]+
                                     );
LOCAL_ID:                            '@'
                                (
                                  [A-Z0-9._$]+
                                  | SQUOTA_STRING
                                  | DQUOTA_STRING
                                  | BQUOTA_STRING
                                );
GLOBAL_ID:                           '@' '@'
                                (
                                  [A-Z0-9._$]+
                                  | BQUOTA_STRING
                                );


// Fragments for Literal primitives

fragment CHARSET_NAME:               ARMSCII8 | ASCII | BIG5 | BINARY | CP1250
                                     | CP1251 | CP1256 | CP1257 | CP850
                                     | CP852 | CP866 | CP932 | DEC8 | EUCJPMS
                                     | EUCKR | GB2312 | GBK | GEOSTD8 | GREEK
                                     | HEBREW | HP8 | KEYBCS2 | KOI8R | KOI8U
                                     | LATIN1 | LATIN2 | LATIN5 | LATIN7
                                     | MACCE | MACROMAN | SJIS | SWE7 | TIS620
                                     | UCS2 | UJIS | UTF16 | UTF16LE | UTF32
                                     | UTF8 | UTF8MB3 | UTF8MB4;

fragment EXPONENT_NUM_PART:          'E' [-+]? DEC_DIGIT+;
fragment ID_LITERAL:                 [A-Z_$0-9\u0080-\uFFFF]*?[A-Z_$\u0080-\uFFFF]+?[A-Z_$0-9\u0080-\uFFFF]*;
fragment DQUOTA_STRING:              '"' ( '\\'. | '""' | ~('"'| '\\') )* '"';
fragment SQUOTA_STRING:              '\'' ('\\'. | '\'\'' | ~('\'' | '\\'))* '\'';
fragment BQUOTA_STRING:              '`' ( '\\'. | '``' | ~('`'|'\\'))* '`';
fragment HEX_DIGIT:                  [0-9A-F];
fragment DEC_DIGIT:                  [0-9];
fragment BIT_STRING_L:               'B' '\'' [01]+ '\'';


// refined psql, to fix conflct
aliasKeyword
   : ABORT
   | ABSOLUTE
   | ACCESS
   | ACTION
   | ADD
   | ADMIN
   | AFTER
   | AGGREGATE
   | ALSO
   | ALTER
   | ALWAYS
   | ASSERTION
   | ASSIGNMENT
   | AT
   | ATTACH
   | ATTRIBUTE
   | BACKWARD
   | BEFORE
   | BEGIN
   | BY
   | CACHE
   | CALL
   | CALLED
   | CASCADE
   | CASCADED
   | CATALOG
   | CHAIN
   | CHARACTERISTICS
   | CHECKPOINT
   | CLASS
   | CLOSE
   | CLUSTER
   | COLUMNS
   | COMMENT
   | COMMENTS
   | COMMIT
   | COMMITTED
   | CONFIGURATION
   | CONFLICT
   | CONNECTION
   | CONSTRAINTS
   | CONTENT
   | CONTINUE
   | CONVERSION
   | COPY
   | COST
   | CSV
   | CUBE
   | CURRENT
   | CURSOR
   | CYCLE
   | DATA
   | DATABASE
   | DAY
   | DEALLOCATE
   | DECLARE
   | DEFAULTS
   | DEFERRED
   | DEFINER
   | DELETE
   | DELIMITER
   | DELIMITERS
   | DEPENDS
   | DETACH
   | DICTIONARY
   | DISABLE
   | DISCARD
   | DOCUMENT
   | DOMAIN
   | DOUBLE
   | DROP
   | EACH
   | ENABLE
   | ENCODING
   | ENCRYPTED
   | ENUM
   | ESCAPE
   | EVENT
   | EXCLUDE
   | EXCLUDING
   | EXCLUSIVE
   | EXECUTE
   | EXPLAIN
   | EXPRESSION
   | EXTENSION
   | EXTERNAL
   | FAMILY
   | FILTER
   | FIRST
   | FOLLOWING
   | FORCE
   | FORWARD
   | FUNCTION
   | FUNCTIONS
   | GENERATED
   | GLOBAL
   | GRANTED
   | GROUPS
   | HANDLER
   | HEADER
   | HOLD
   | HOUR
   | IDENTITY
   | IF
   | IMMEDIATE
   | IMMUTABLE
   | IMPLICIT
   | IMPORT
   | INCLUDE
   | INCLUDING
   | INCREMENT
   | INDEX
   | INDEXES
   | INHERIT
   | INHERITS
   | INLINE
   | INPUT
   | INSENSITIVE
   | INSERT
   | INSTEAD
   | INVOKER
   | ISOLATION
   | KEY
   | LABEL
   | LANGUAGE
   | LARGE
   | LAST
   | LEAKPROOF
   | LEVEL
   | LISTEN
   | LOAD
   | LOCAL
   | LOCATION
   | LOCK
   | LOCKED
   | LOGGED
   | MAPPING
   | MATCH
   | MATERIALIZED
   | MAXVALUE
   | METHOD
   | MINUTE
   | MINVALUE
   | MODE
   | MONTH
   | MOVE
   | NAME
   | NAMES
   | NATIONAL
   | NEW
   | NEXT
   | NFC
   | NFD
   | NFKC
   | NFKD
   | NO
   | NORMALIZED
   | NOTHING
   | NOTIFY
   | NOWAIT
   | NULLS
   | OBJECT
   | OF
   | OFF
   | OIDS
   | OLD
   | OPERATOR
   | OPTION
   | OPTIONS
   | ORDINALITY
   | OTHERS
   | OVER
   | OVERRIDING
   | OWNED
   | OWNER
   | PARALLEL
   | PARSER
   | PARTIAL
   | PARTITION
   | PASSING
   | PASSWORD
   | PLANS
   | POLICY
   | PRECEDING
   | PREPARE
   | PREPARED
   | PRESERVE
   | PRIOR
   | PRIVILEGES
   | PROCEDURAL
   | PROCEDURE
   | PROCEDURES
   | PROGRAM
   | PUBLICATION
   | QUOTE
   | RANGE
   | READ
   | REASSIGN
   | RECHECK
   | RECURSIVE
   | REF
   | REFERENCING
   | REFRESH
   | REINDEX
   | RELATIVE
   | RELEASE
   | RENAME
   | REPEATABLE
   | REPLACE
   | REPLICA
   | RESET
   | RESTART
   | RESTRICT
   | RETAIN
   | RETURNS
   | REVOKE
   | ROLE
   | ROLLBACK
   | ROLLUP
   | ROUTINE
   | ROUTINES
   | ROWS
   | RULE
   | SAVEPOINT
   | SCHEMA
   | SCHEMAS
   | SCROLL
   | SEARCH
   | SECOND
   | SECURITY
   | SEQUENCE
   | SEQUENCES
   | SERIALIZABLE
   | SERVER
   | SESSION
   | SET
   | SETS
   | SHARE
   | SHOW
   | SIMPLE
   | SKIP
   | SNAPSHOT
   | SQL
   | STABLE
   | STANDALONE
   | START
   | STATEMENT
   | STATISTICS
   | STDIN
   | STDOUT
   | STORAGE
   | STORED
   | STRICT
   | STRIP
   | SUBSCRIPTION
   | SUPPORT
   | SYSID
   | SYSTEM
   | TABLES
   | TABLESPACE
   | TEMP
   | TEMPLATE
   | TEMPORARY
   | TEXT
   | TIES
   | TRANSACTION
   | TRANSFORM
   | TRIGGER
   | TRUNCATE
   | TRUSTED
   | TYPE
   | TYPES
   | UESCAPE
   | UNBOUNDED
   | UNCOMMITTED
   | UNENCRYPTED
   | UNKNOWN
   | UNLISTEN
   | UNLOGGED
   | UNTIL
   | UPDATE
   | VACUUM
   | VALID
   | VALIDATE
   | VALIDATOR
   | VALUE
   | VARYING
   | VERSION
   | VIEW
   | VIEWS
   | VOLATILE
   | WHITESPACE
   | WITHIN
   | WITHOUT
   | WORK
   | WRAPPER
   | WRITE
   | XML
   | YEAR
   | YES
   | ZONE
   ;


ABORT
   : 'ABORT'
   ;

ABSOLUTE
   : 'ABSOLUTE'
   ;

ACCESS
   : 'ACCESS'
   ;


ALSO
   : 'ALSO'
   ;

ASSERTION
   : 'ASSERTION'
   ;

ASSIGNMENT
   : 'ASSIGNMENT'
   ;

ATTRIBUTE
   : 'ATTRIBUTE'
   ;

BACKWARD
   : 'BACKWARD'
   ;

CALLED
   : 'CALLED'
   ;

CATALOG
   : 'CATALOG'
   ;

CHARACTERISTICS
   : 'CHARACTERISTICS'
   ;

CHECKPOINT
   : 'CHECKPOINT'
   ;

CLASS
   : 'CLASS'
   ;

CLUSTER
   : 'CLUSTER'
   ;

COMMENTS
   : 'COMMENTS'
   ;

CONFIGURATION
   : 'CONFIGURATION'
   ;

CONSTRAINTS
   : 'CONSTRAINTS'
   ;

CONTENT
   : 'CONTENT'
   ;

CONVERSION
   : 'CONVERSION'
   ;

COST
   : 'COST'
   ;

CYCLE
   : 'CYCLE'
   ;

DEFAULTS
   : 'DEFAULTS'
   ;

DEFERRED
   : 'DEFERRED'
   ;

DELIMITER
   : 'DELIMITER'
   ;

DELIMITERS
   : 'DELIMITERS'
   ;

DICTIONARY
   : 'DICTIONARY'
   ;

DOCUMENT
   : 'DOCUMENT'
   ;

DOMAIN
   : 'DOMAIN'
   ;

ENCODING
   : 'ENCODING'
   ;

ENCRYPTED
   : 'ENCRYPTED'
   ;

EXCLUDE
   : 'EXCLUDE'
   ;

EXCLUDING
   : 'EXCLUDING'
   ;

EXTENSION
   : 'EXTENSION'
   ;

EXTERNAL
   : 'EXTERNAL'
   ;

FAMILY
   : 'FAMILY'
   ;

FORWARD
   : 'FORWARD'
   ;

FUNCTIONS
   : 'FUNCTIONS'
   ;

GRANTED
   : 'GRANTED'
   ;

HEADER
   : 'HEADER'
   ;

HOLD
   : 'HOLD'
   ;

IDENTITY
   : 'IDENTITY'
   ;

IMMEDIATE
   : 'IMMEDIATE'
   ;

IMMUTABLE
   : 'IMMUTABLE'
   ;

IMPLICIT
   : 'IMPLICIT'
   ;

INCLUDING
   : 'INCLUDING'
   ;

INCREMENT
   : 'INCREMENT'
   ;

INHERIT
   : 'INHERIT'
   ;

INHERITS
   : 'INHERITS'
   ;

INLINE
   : 'INLINE'
   ;

INSENSITIVE
   : 'INSENSITIVE'
   ;

INSTEAD
   : 'INSTEAD'
   ;

LABEL
   : 'LABEL'
   ;

LARGE
   : 'LARGE'
   ;

LEAKPROOF
   : 'LEAKPROOF'
   ;

LISTEN
   : 'LISTEN'
   ;

LOCATION
   : 'LOCATION'
   ;

MAPPING
   : 'MAPPING'
   ;

MATERIALIZED
   : 'MATERIALIZED'
   ;

MINVALUE
   : 'MINVALUE'
   ;

MOVE
   : 'MOVE'
   ;

NOTHING
   : 'NOTHING'
   ;

NOTIFY
   : 'NOTIFY'
   ;

NULLS
   : 'NULLS'
   ;

OBJECT
   : 'OBJECT'
   ;

OFF
   : 'OFF'
   ;

OIDS
   : 'OIDS'
   ;

OPERATOR
   : 'OPERATOR'
   ;

OWNED
   : 'OWNED'
   ;

PASSING
   : 'PASSING'
   ;

PLANS
   : 'PLANS'
   ;

PREPARED
   : 'PREPARED'
   ;

PRIOR
   : 'PRIOR'
   ;

PROCEDURAL
   : 'PROCEDURAL'
   ;

PROGRAM
   : 'PROGRAM'
   ;

REASSIGN
   : 'REASSIGN'
   ;

RECHECK
   : 'RECHECK'
   ;

REF
   : 'REF'
   ;

REFRESH
   : 'REFRESH'
   ;

REINDEX
   : 'REINDEX'
   ;

RELATIVE
   : 'RELATIVE'
   ;

REPLICA
   : 'REPLICA'
   ;

RESTART
   : 'RESTART'
   ;

RULE
   : 'RULE'
   ;

SCROLL
   : 'SCROLL'
   ;

SEARCH
   : 'SEARCH'
   ;

SEQUENCE
   : 'SEQUENCE'
   ;

SEQUENCES
   : 'SEQUENCES'
   ;

STABLE
   : 'STABLE'
   ;

STANDALONE
   : 'STANDALONE'
   ;

STATEMENT
   : 'STATEMENT'
   ;

STATISTICS
   : 'STATISTICS'
   ;

STDIN
   : 'STDIN'
   ;

STDOUT
   : 'STDOUT'
   ;

STRICT
   : 'STRICT'
   ;

STRIP
   : 'STRIP'
   ;

SYSID
   : 'SYSID'
   ;

SYSTEM
   : 'SYSTEM'
   ;

TEMP
   : 'TEMP'
   ;

TEMPLATE
   : 'TEMPLATE'
   ;

TRUSTED
   : 'TRUSTED'
   ;

TYPE
   : 'TYPE'
   ;

TYPES
   : 'TYPES'
   ;

UNENCRYPTED
   : 'UNENCRYPTED'
   ;

UNLISTEN
   : 'UNLISTEN'
   ;

UNLOGGED
   : 'UNLOGGED'
   ;

VACUUM
   : 'VACUUM'
   ;

VALID
   : 'VALID'
   ;

VALIDATE
   : 'VALIDATE'
   ;

VALIDATOR
   : 'VALIDATOR'
   ;

VOLATILE
   : 'VOLATILE'
   ;

WHITESPACE
   : 'WHITESPACE'
   ;

ZONE
   : 'ZONE'
   ;

ATTACH
   : 'ATTACH'
   ;

CONFLICT
   : 'CONFLICT'
   ;

CUBE
   : 'CUBE'
   ;

DEPENDS
   : 'DEPENDS'
   ;

DETACH
   : 'DETACH'
   ;

EXPRESSION
   : 'EXPRESSION'
   ;

GROUPS
   : 'GROUPS'
   ;

INCLUDE
   : 'INCLUDE'
   ;

INPUT
   : 'INPUT'
   ;

LOCKED
   : 'LOCKED'
   ;

LOGGED
   : 'LOGGED'
   ;

METHOD
   : 'METHOD'
   ;

NEW
   : 'NEW'
   ;

NFC
    : 'NFC'
    ;

NFD
    : 'NFD'
    ;

NFKC
   : 'NFKC'
   ;

NFKD
    : 'NFKD'
    ;

NORMALIZED
    : 'NORMALIZED'
    ;

OLD
    : 'OLD'
    ;

ORDINALITY
    : 'ORDINALITY'
    ;

OTHERS
    : 'OTHERS'
    ;

OVERRIDING
    : 'OVERRIDING'
    ;

PARALLEL
    : 'PARALLEL'
    ;

POLICY
    : 'POLICY'
    ;

PROCEDURES
    : 'PROCEDURES'
    ;

PUBLICATION
    : 'PUBLICATION'
    ;

REFERENCING
    : 'REFERENCING'
    ;

ROUTINES
    : 'ROUTINES'
    ;

SETS
    : 'SETS'
    ;

SUBSCRIPTION
    : 'SUBSCRIPTION'
    ;

SUPPORT
    : 'SUPPORT'
    ;

TIES
    : 'TIES'
    ;

TRANSFORM
    : 'TRANSFORM'
    ;

UESCAPE
    : 'UESCAPE'
    ;

VIEWS
    : 'VIEWS'
    ;