{*******************************************************}
{                                                       }
{               Delphi DataSnap Framework               }
{                                                       }
{ Copyright(c) 1995-2019 Embarcadero Technologies, Inc. }
{              All rights reserved                      }
{                                                       }
{*******************************************************}

unit Amazon.Storage.Service.API;

interface

uses System.Classes,
     System.JSON,
     System.SysUtils,
     System.Generics.Collections,
     Data.Cloud.CloudAPI,
     Amazon.Storage.Service.API.Life.Cycle,
     Xml.XMLIntf;

type
  /// <summary>Bucket/Object ACL types</summary>
  TAmazonACLType = (amzbaNotSpecified, amzbaPrivate, amzbaPublicRead, amzbaPublicReadWrite,
                    amzbaAuthenticatedRead, amzbaBucketOwnerRead, amzbaBucketOwnerFullControl,
                    amzbaAWSExecRead, amzbaLogDeliveryWrite);

  /// <summary>Regions which can be used with Amazon Services.</summary>
  TAmazonRegion = (amzrNotSpecified, amzrEUWest1, amzrEUWest2, amzrEUWest3, amzrEUCentral1,
                   amzrUSEast1, amzrUSWest1, amzrUSWest2, amzrAPSoutheast1, amzrAPSoutheast2,
                   amzrAPNortheast1, amzrAPNortheast2, amzrAPNortheast3, amzrSAEast1,
                   amzrUSClassic, amzrEU, amzrCNNorth1, amzrCNNorthwest1);


  /// <summary>The available Grant permissions.</summary>
  TAmazonGrantPermission = (amgpFullControl, amgpWrite, amgpWriteACP, amgpRead, amgpReadACP, amgpUnknown);

  /// <summary>The available Grantee types.</summary>
  TAmazonGranteeType = (agtCanonicalUser, agtCustomerByEmail, agtGroup, agtUnknown);


  /// <summary>Amazon payer options.</summary>
  TAmazonPayer = (ampRequester, ampBucketOwner, ampUnknown);


  //The item names must exactly match the available Amazon attribute names, with a 3 letter prefix.
  /// <summary>The available property types for an Amazon queue.</summary>
  TAmazonQueueAttribute = (aqaAll, aqaApproximateNumberOfMessages, aqaApproximateNumberOfMessagesNotVisible,
                           aqaVisibilityTimeout, aqaCreatedTimestamp, aqaLastModifiedTimestamp,
                           aqaPolicy, aqaMaximumMessageSize, aqaMessageRetentionPeriod,
                           aqaQueueArn, aqaApproximateNumberOfMessagesDelayed, aqaDelaySeconds,
                           aqaReceiveMessageWaitTimeSeconds, aqaRedrivePolicy);

  /// <summary>The available actions for an Amazon queue, for which permissions can be established.</summary>
  TAmazonQueueActions = (aqacAll, aqacSendMessage, aqacReceiveMessage, aqacDeleteMessage,
                         aqacChangeMessageVisibility, aqacGetQueueAttributes);

  /// <summary>Amazon specific implementation of TCloudSHA256Authentication</summary>
  /// <remarks>Sets the Authorization type to 'AWS'</remarks>
  TAmazonAuthentication = class(TCloudSHA256Authentication)
  public const
    AuthorizationType = 'AWS';
  protected
    /// <summary>Specifies if the Auth is in header, or as a query parameter</summary>
    FAuthInHeader: Boolean;
  public
    /// <summary>Creates a new instance of TAmazonAuthentication</summary>
    /// <remarks>Sets the authorization type (for the authorization header) to 'AWS'</remarks>
    // / <param name="ConnectionInfo">The connection info to use in authentication</param>
    // / <param name="AuthInHeader">Specifies if the Auth is in header, or as a query parameter</param>
    constructor Create(const ConnectionInfo: TCloudConnectionInfo; AuthInHeader: Boolean = False); overload;
    /// <summary>Builds the string to use as the value of the Authorization header or 'Signature' Query Parameter.</summary>
    /// <remarks>The 'StringToSign' passed in is encoded using the 'ConnectionInfo' of this class,
    ///          and the 'SignString' function of the subclass. The result of this is then combined with
    ///          the result returned by 'GetAuthorizationType' to build the value string to use with the
    ///          Authorization header, or 'Signature' Query Parameter of all requests to the cloud.
    ///
    ///          Note that the resulting format depends on the value of 'AuthInHeader'. The signed string will
    ///          either be returned directly, or as part of an Authorization header formatted string.
    /// </remarks>
    /// <param name="StringToSign">The string to sign and use in authentication</param>
    function BuildAuthorizationString(const StringToSign: string): string; override;
  end;

  /// <summary>Amazon AWS4 specific implementation of TCloudSHA256Authentication</summary>
  /// <remarks>Sets the Authorization type to 'AWS4-HMAC-SHA256'</remarks>
  TAmazonAWS4Authentication = class(TCloudSHA256Authentication)
  public const
    AuthorizationType = 'AWS4-HMAC-SHA256';
  protected
    /// <summary>Specifies if the Auth is in header, or as a query parameter</summary>
    FAuthInHeader: Boolean;
    procedure AssignKey(const AccountKey: string); override;
  public
    constructor Create(const ConnectionInfo: TCloudConnectionInfo; AuthInHeader: Boolean = False); overload;
    /// <summary>Builds the string to use as the value of the Authorization header of requests.</summary>
    /// <remarks>http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html</remarks>
    /// <param name="StringToSign">The string to sign and use in the Authorization header value.</param>
    /// <param name="DateISO">Specific date used to build the signature key.</param>
    /// <param name="Region">Specific region used to build the signature key.</param>
    /// <param name="SignedStrHeaders">Signed headers used to build the authorization string.</param>
    function BuildAuthorizationString(const StringToSign, DateISO, Region, SignedStrHeaders: string): string; reintroduce; overload;
    function BuildAuthorizationString(const StringToSign, DateISO, Region, ServiceName, SignedStrHeaders: string): string; reintroduce; overload;
  end;


  /// <summary>Amazon specific implementation of TCloudSHA1uthentication</summary>
  /// <remarks>Sets the Authorization type to 'AWS'</remarks>
  TAmazonSHA1Authentication = class(TCloudSHA1Authentication)
  public const
    AuthorizationType = 'AWS';
  public
    /// <summary>Creates a new instance of TAmazonAuthentication</summary>
    /// <remarks>Sets the authorization type (for the authorization header) to 'AWS'</remarks>
    // / <param name="ConnectionInfo">The connection info to use in authentication</param>
    constructor Create(const ConnectionInfo: TCloudConnectionInfo); overload;
  end;

  /// <summary>Amazon extension of TCloudConnectionInfo</summary>
  TAmazonConnectionInfo = class(TCloudConnectionInfo)
  public const
    DefaultStorageEndpoint = 's3.amazonaws.com';
    DefaultTableEndpoint = 'sdb.amazonaws.com';
    DefaultQueueEndpoint = 'queue.amazonaws.com';
    RegionStorageEndpoint = 's3.%s.amazonaws.com';
    RegionTableEndpoint = 'sdb.%s.amazonaws.com';
    RegionQueueEndpoint = '%s.queue.amazonaws.com';
    DefaultRegion = amzrUSEast1;
  private
    FConsistentRead: Boolean;
    FMFASerialNumber: string;
    FMFAAuthCode: string;
    FStorageEndpoint: string;
    FTableEndpoint: string;
    FQueueEndpoint: string;
    FRegion: TAmazonRegion;

    function GetServiceURL(const AHost: string): string; overload;
    function GetServiceURL(const AHost, ARegionHost: string; ARegion: TAmazonRegion): string; overload;
    function GetQueueURL: string;
    function GetTableURL: string;

    function GetQueueEndpoint: string;
    function GetTableEndpoint: string;
    function GetStorageEndpoint: string;
    procedure SetStorageEndpoint(const AValue: string);
    procedure SetQueueEndpoint(const AValue: string);
    procedure SetTableEndpoint(const AValue: string);
    procedure SetRegion(const AValue: TAmazonRegion);
    function GetRegion: TAmazonRegion;
    function GetVirtualHost(const AHost, ARegionHost: string; ARegion: TAmazonRegion): string;
  public
    /// <summary>Creates a new instance of this connection info class</summary>
    /// <param name="AOwner">The component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>The queue service URL for issuing requests.</summary>
    property QueueURL: string read GetQueueURL;
    /// <summary>The SimpleDB (Table service) URL for issuing requests.</summary>
    property TableURL: string read GetTableURL;
    /// <summary>The S3 (Storage service) URL for issuing requests.</summary>
    /// <param name="ABucketName">The optional bucket name to prefix the URL with</param>
    /// <param name="ARegion">The optional region of the backet</param>
    /// <returns>The S3 (Storage service) URL for issuing requests.</returns>
    function StorageURL(const ABucketName: string = ''; ARegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Determines S3 Virtual Host name based on bucket and endpoint.</summary>
    /// <param name="ABucketName">The optional bucket name to prefix the host path</param>
    /// <param name="ARegion">The optional region of the backet</param>
    /// <returns>The S3 (Storage service) Virtual hostname .</returns>
    function StorageVirtualHost(const ABucketName: string = ''; ARegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the string representation of the given region.</summary>
    /// <param name="Region">The region</param>
    /// <returns>The string representation of the given region.</returns>
    class function GetRegionString(Region: TAmazonRegion): string; static;
    /// <summary>Returns the region for the given string representation.</summary>
    /// <param name="Region">The region in string form</param>
    /// <returns>The region for the given string representation.</returns>
    class function GetRegionFromString(const Region: string): TAmazonRegion; static;
  published
    /// <summary>Raising the property to published</summary>
    property AccountName;
    /// <summary>Raising the property to published</summary>
    property AccountKey;
    /// <summary>The protocol to use as part of the service URL (http|https)</summary>
    property Protocol;
    /// <summary>The proxy host to use for the HTTP requests to the cloud, or empty string to use none</summary>
    property RequestProxyHost;
    /// <summary>The proxy host's port to use for the HTTP requests to the cloud</summary>
    property RequestProxyPort;
    /// <summary>True to use consistent read, whenever possible.</summary>
    /// <remarks>Amazon often uses the 'eventual consistency' read option, which doesn't promise
    ///          that any one read operation is returning the most recent data. Some services allow for
    ///          setting ConsistenRead to true, which disables this eventual consistency model.
    /// </remarks>
    [Default(True)]
    property ConsistentRead: Boolean read FConsistentRead write FConsistentRead default True;
    /// <summary>The serial number to use when MFA Delete is enabled.</summary>
    property MFASerialNumber: string read FMFASerialNumber write FMFASerialNumber;
    /// <summary>The authentication code to use when MFA Delete is enabled.</summary>
    property MFAAuthCode: string read FMFAAuthCode write FMFAAuthCode;
    /// <summary>The host/endpoint to use when connecting with the SimpleDB (Table) service.</summary>
    property TableEndpoint: string read GetTableEndpoint write SetTableEndpoint;
    /// <summary>The host/endpoint to use when connecting with the queue service.</summary>
    property QueueEndpoint: string read GetQueueEndpoint write SetQueueEndpoint;
    /// <summary>The host/endpoint to use when connecting with the S3 (Storage) service.</summary>
    property StorageEndpoint: string read GetStorageEndpoint write SetStorageEndpoint;
    property Region: TAmazonRegion read GetRegion write SetRegion default DefaultRegion;
    /// <summary>True to use the default service URLs, false to use endpoints from the endpoint properties.
    /// </summary>
    property UseDefaultEndpoints;
  end;

  /// <summary>Abstract extension of the TCloudService class.</summary>
  /// <remarks>This implements all functionality common to the Amazon S3m SQS and SimpleDB services,
  ///          or common to two of them (allowing the third to extend further and override.)
  ///</remarks>
  TAmazonService = class abstract(TCloudService)
  protected
    /// <summary>URL encodes the given value.</summary>
    /// <param name="Value">The string to URL encode</param>
    /// <returns>The URL encoded value.</returns>
    function URLEncodeValue(const Value: string): string; override;
    /// <summary>Returns the ConnectionInfo, cast as a TAmazonConnectionInfo</summary>
    /// <returns>ConnectionInfo, cast as a TAmazonConnectionInfo</returns>
    function GetConnectionInfo: TAmazonConnectionInfo;
    /// <summary>Returns nil, as SQS and SimpleDB don't have required header values.</summary>
    /// <returns>nil</returns>
    function GetRequiredHeaderNames(out InstanceOwner: Boolean): TStrings; override;
    /// <summary>Returns empty string, as SQS and SimpleDB don't use Canonicalized Headers.</summary>
    /// <returns>empty string</returns>
    function GetCanonicalizedHeaderPrefix: string; override;
    /// <summary>Returns the current time, formatted properly as a string.</summary>
    /// <returns>The current time, formatted properly as a string</returns>
    function CurrentTime: string; virtual;
    /// <summary>Returns the authentication instance to use for the given connection info.</summary>
    /// <returns>The authentication instance to use for the given connection info.</returns>
    function CreateAuthInstance(const ConnectionInfo: TAmazonConnectionInfo): TCloudAuthentication; virtual; abstract;
    /// <summary>Sorts the given list of Headers.</summary>
    /// <remarks>Extend this if you wish to modify how the list is sorted.</remarks>
    /// <param name="Headers">List of headers to sort.</param>
    procedure SortHeaders(const Headers: TStringList); override;
    /// <summary>Returns a ISO8601 date with no separator characters</summary>
    function ISODateTime_noSeparators: string;
    /// <summary>Populates the given ResponseInfo with error information, if any.</summary>
    /// <remarks>If the given ResponseInfo is non-null, and the ResultString holds an XML error message,
    ///          then this procedure will parse the error XML and populate the ResponseInfo's message
    ///          with the error message.
    /// </remarks>
    /// <param name="ResponseInfo">The optional response info to populate, or nil</param>
    /// <param name="ResultString">The request's response string to parse for an error message.</param>
    procedure ParseResponseError(const ResponseInfo: TCloudResponseInfo; const ResultString: string); virtual; abstract;
  public
    /// <summary>Creates a new instance of TAmazonService</summary>
    /// <remarks>This class does not own the ConnectionInfo instance.</remarks>
    // / <param name="ConnectionInfo">The Amazon service connection info</param>
    constructor Create(const ConnectionInfo: TAmazonConnectionInfo);
    /// <summary>Frees the required headers list and destroys the instance</summary>
    destructor Destroy; override;
  end;

  /// <summary>A queue permission, specifying the AWS account it applies to, and the allowed action.</summary>
  TAmazonQueuePermission = record
    /// <summary>The AWS account Id this permission applies to.</summary>
    /// <remarks>Must be a valid 12-digit AWS account number, without hyphens</remarks>
    AccountId: string;
    /// <summary>The action which this permission is allowing.</summary>
    Action: TAmazonQueueActions;

    /// <summary>Creates a new instance of TAmazonQueuePermission</summary>
    /// <param name="AccountId">The AWS account Id this permission applies to.</param>
    /// <param name="Action">The action which this permission is allowing. Defaults to All</param>
    /// <returns>The new initialised instance of TAmazonQueuePermission</returns>
    class function Create(const AccountId: string; Action: TAmazonQueueActions = aqacAll): TAmazonQueuePermission; static;

    /// <summary>Returns the string representation of the action</summary>
    /// <returns>The string representation of the action</returns>
    function GetAction: string;
  end;

  /// <summary>Authentication and other common functionality shared by table and queue services, but not S3.</summary>
  TAmazonBasicService = class(TAmazonService)
  protected
    /// <summary>Returns the authentication instance to use for the given connection info.</summary>
    /// <returns>The authentication instance to use for the given connection info.</returns>
    function CreateAuthInstance(const ConnectionInfo: TAmazonConnectionInfo): TCloudAuthentication; override;
    /// <summary>Handles the StringToSign after it is created.</summary>
    /// <remarks>This modifies the provided URL or the content stream, adding a 'Signature' query parameter.
    /// </remarks>
    /// <param name="HTTPVerb">The HTTP verb (eg: GET, POST) of the request.</param>
    /// <param name="Headers">The header name/value pairs</param>
    /// <param name="QueryParameters">The query parameter name/value pairs</param>
    /// <param name="StringToSign">The StringToSign for the request</param>
    /// <param name="URL">The URL of the request</param>
    /// <param name="Request">The request object</param>
    /// <param name="Content">The content stream of the request.</param>
    procedure PrepareRequestSignature(const HTTPVerb: string;
                                      const Headers, QueryParameters: TStringList;
                                      const StringToSign: string;
                                      var URL: string; Request: TCloudHTTP; var Content: TStream); override;
    /// <summary>Takes in a URL and optionally uses it to parse the HTTPRequestURI</summary>
    /// <remarks>The overrides the base implementation, adding "ValueOfHostHeaderInLowercase"
    ///          on a new line before the URI.
    /// </remarks>
    /// <param name="URL">The URL of the request.</param>
    /// <returns>The second and third portions of the StringToSign, ending with a newline character.</returns>
    function BuildStringToSignResourcePath(const URL: string): string; override;
    /// <summary>Creates the list of query parameters to use for the given action.</summary>
    /// <remarks>Returns the action query parameter, as well as the other parameters common to all requests.
    ///          The action itself should be something like "ListQueues".
    /// </remarks>
    /// <param name="Action">The action currently being performed</param>
    /// <returns></returns>
    function BuildQueryParameters(const Action: string): TStringList;
    /// <summary>Sorts the query parameters by name.</summary>
    /// <remarks>This sorts by name, but keeps AWSAccessKeyId at the beginning of the list.</remarks>
    /// <param name="QueryParameters">The list of parameters to sort</param>
    /// <param name="ForURL">True if the parameters are for use in a URL, false otherwise.</param>
    procedure SortQueryParameters(const QueryParameters: TStringList; ForURL: Boolean); override;
    /// <summary>Issues the request, as either a GET or a POST</summary>
    /// <remarks>If the RequestStream is specified, then a POST request is issued and the stream is used
    ///          in the HTTP request as the body and the query parameters are placed in the URL of the request.
    ///          Otherwise, if it is nil, then the CanonicalizedQueryString is built from the given
    ///          information and is placed in the body of the request, which is issued as a GET.
    /// </remarks>
    /// <param name="URL">The request URL, without any query parameters</param>
    /// <param name="QueryParams">The query parameters of the request</param>
    /// <param name="ResponseInfo">The optional response info to populate, or nil</param>
    /// <param name="ResultString">The string representation of the response content.</param>
    /// <param name="RequestStream">The request stream to set as the body of the request, or nil.</param>
    /// <returns>The HTTP request/response object</returns>
    function IssueRequest(URL: string; QueryParams: TStringList; ResponseInfo: TCloudResponseInfo;
                          out ResultString: string; RequestStream: TStream = nil): TCloudHTTP; overload;
    /// <summary>Issues the request, as either a GET or a POST</summary>
    /// <remarks>If the RequestStream is specified, then a POST request is issued and the stream is used
    ///          in the HTTP request as the body and the query parameters are placed in the URL of the request.
    ///          Otherwise, if it is nil, then the CanonicalizedQueryString is built from the given
    ///          information and is placed in the body of the request, which is issued as a GET.
    /// </remarks>
    /// <param name="URL">The request URL, without any query parameters</param>
    /// <param name="QueryParams">The query parameters of the request</param>
    /// <param name="ResponseInfo">The optional response info to populate, or nil</param>
    /// <param name="RequestStream">The request stream to set as the body of the request, or nil.</param>
    /// <returns>The HTTP request/response object</returns>
    function IssueRequest(URL: string; QueryParams: TStringList; ResponseInfo: TCloudResponseInfo;
                          RequestStream: TStream = nil): TCloudHTTP; overload;
    /// <summary>Populates the given ResponseInfo with error information, if any.</summary>
    /// <remarks>If the given ResponseInfo is non-null, and the ResultString holds an XML error message,
    ///          then this procedure will parse the error XML and populate the ResponseInfo's message
    ///          with the error message.
    ///
    ///          This also populates a header value with key 'RequestId', regardless of if the ResultString
    ///          is error XML, or representing a successful request.
    /// </remarks>
    /// <param name="ResponseInfo">The optional response info to populate, or nil</param>
    /// <param name="ResultString">The request's response string to parse for an error message.</param>
    procedure ParseResponseError(const ResponseInfo: TCloudResponseInfo; const ResultString: string); override;
    /// <summary>Returns the version query parameter value to use in requests.</summary>
    /// <returns>The version query parameter value to use in requests.</returns>
    function GetServiceVersion: string; virtual; abstract;
    /// <summary>Returns the host string for the service.</summary>
    /// <returns>The host string for the service.</returns>
    function GetServiceHost: string; virtual; abstract;
  end;

  /// <summary>Represents a single row to be updated in a batch execution.</summary>
  TAmazonBatchRow = record
    /// <summary>The unique ID of the row to update with this content</summary>
    RowId: string;
    /// <summary>The row content to commit</summary>
    Row: TCloudTableRow;
    /// <summary>True to replace any column content that matches any of the given column names.</summary>
    /// <remarks>Columns can have multiple values. If this is set to false, then any existing values for
    ///          a column being specified here will remain, and the new value will simply be added beside it.
    /// </remarks>
    ReplaceAll: Boolean;
    /// <summary>Creates a new instance of TAmazonBatchRow</summary>
    /// <param name="RowId">The unique ID of the row to update with this content</param>
    /// <param name="Row">The row content to commit</param>
    /// <param name="ReplaceAll">True to replace any column content that matches any of the given column names.</param>
    /// <returns>The new instance of TAmazonBatchRow</returns>
    class function Create(const RowId: string; Row: TCloudTableRow;
                          ReplaceAll: Boolean = True): TAmazonBatchRow; static;
  end;

  /// <summary>Conditional for inserting/updating a row.</summary>
  /// <remarks>When inserting or deleting a row (in a non-batch operation) you can specify one or more
  ///          conditions which must be met in order to perform the action. These conditions are either that
  ///          the server already contains a specific value for a specific column, or that the column doesn't exist.
  ///          This can be used to insure multiple processes do not overwrite each other.
  /// </remarks>
  TAmazonRowConditional = record
    /// <summary>The column name to check.</summary>
    ColumnName: string;
    /// <summary>The column value to check for, if not just checking column existence.</summary>
    ColumnValue: string;
    /// <summary>True to check that the column exists. False to check that it doesn't exist.</summary>
    ColumnExists: Boolean;

    /// <summary>Creates a new instance of TAmazonRowConditional, checking only column existence.</summary>
    /// <remarks>If ColumnExists is set to true, The column Value is checked.</remarks>
    /// <param name="ColumnName">The name of the column to check.</param>
    /// <param name="ColumnValue">The value of the column to expect and check against.</param>
    /// <param name="ColumnExists">true to check if the column exists, false to check that it doesn't</param>
    /// <returns>The new instance of TAmazonRowConditional</returns>
    class function Create(const ColumnName, ColumnValue: string;
                          const ColumnExists: Boolean = True): TAmazonRowConditional; static;
  end;

  /// <summary>Implementation of TAmazonBasicService for managing an Amazon SimpleDB account.</summary>
  TAmazonTableService =  class(TAmazonBasicService)
  protected
    /// <summary>Returns the version query parameter value to use in requests.</summary>
    /// <returns>The version query parameter value to use in requests.</returns>
    function GetServiceVersion: string; override;
    /// <summary>Returns the host string for the service.</summary>
    /// <returns>The host string for the service.</returns>
    function GetServiceHost: string; override;
  public
    /// <summary>Creates a table (Domain) with the given name.</summary>
    /// <remarks>The name can range between 3 and 255 characters and
    ///          can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'
    /// </remarks>
    /// <param name="TableName">The name of the table to create</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the creation was a success, false otherwise.</returns>
    function CreateTable(const TableName: string; ResponseInfo: TCloudResponseInfo = nil): Boolean;
    /// <summary>Deletes the table (Domain) with the given name.</summary>
    /// <remarks>This marks the table for delete and hides it from future calls when querying the
    ///          list of available tables. However, it isn't deleted from the server right away,
    ///          and for a short time after calling delete, you will not be able to create a new table
    ///          with the same name.
    /// </remarks>
    /// <param name="TableName">The name of the table (Domain) to delete</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete is successful, false otherwise</returns>
    function DeleteTable(const TableName: string; ResponseInfo: TCloudResponseInfo = nil): Boolean;
    /// <summary>Returns an XML representation of the tables existing in the table service account.</summary>
    /// <remarks>ContinuationToken is used if there exists more than 'MaxNumberOfTables' tables,
    ///     and a previous call didn't return the last of the tables. It would have provided a
    ///     ContinuationToken in the 'NextToken' XML element.
    ///
    ///     The server will default the value of MaxNumberOfTables to 100 (the maximum) if you set it to
    ///     a number of zero or less.
    /// </remarks>
    /// <param name="ContinuationToken">The optional NextToken to continue table population from.</param>
    /// <param name="MaxNumberOfTables">The maximum number of tables to return</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The XML representation of the available tables for the service</returns>
    function QueryTablesXML(const ContinuationToken: string = ''; const MaxNumberOfTables: Integer = 0;
                            ResponseInfo: TCloudResponseInfo = nil): string;

    /// <summary>Returns a list of the tables existing in the table service account.</summary>
    /// <remarks>ContinuationToken is used if there exists more than 'MaxNumberOfTables' tables,
    ///     and a previous call didn't return the last of the tables. It would have provided a
    ///     ContinuationToken in the 'NextToken' XML element.
    ///
    ///     The server will default the value of MaxNumberOfTables to 100 (the maximum) if you set it to
    ///     a number of zero or less.
    /// </remarks>
    /// <param name="ContinuationToken">The optional NextToken to continue table population from.</param>
    /// <param name="MaxNumberOfTables">The maximum number of tables to return</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The list of available tables for the service, or nil if a failure occurred.</returns>
    function QueryTables(const ContinuationToken: string = ''; const MaxNumberOfTables: Integer = 0;
                            ResponseInfo: TCloudResponseInfo = nil): TStrings;
    /// <summary>Returns a list of metadata associated with the given table.</summary>
    /// <remarks>Returns the following information:
    ///          Timestamp - the date/time the metadata was last modified
    ///          ItemCount - the number of items in the table (domain)
    ///          AttributeValueCount - The total number of name/value pairs
    ///          AttributeNameCount - The number of (unique) attribute names in the pairs
    ///          ItemNamesSizeBytes - The total size (in bytes) of all item names in the table
    ///          AttributeValuesSizeBytes - The total size (in bytes) of all attribute values
    ///          AttributeNamesSizeBytes - The total size (in bytes) of all unique attribute names
    /// </remarks>
    /// <param name="TableName">The name of the table (Domain) to get metadata for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The XML representation of the available tables for the service.</returns>
    function GetTableMetadataXML(const TableName: string; ResponseInfo: TCloudResponseInfo = nil): string;
    /// <summary>Returns a list of metadata associated with the given table.</summary>
    /// <remarks>Returns the following information:
    ///          Timestamp - the date/time the metadata was last modified
    ///          ItemCount - the number of items in the table (domain)
    ///          AttributeValueCount - The total number of name/value pairs
    ///          AttributeNameCount - The number of (unique) attribute names in the pairs
    ///          ItemNamesSizeBytes - The total size (in bytes) of all item names in the table
    ///          AttributeValuesSizeBytes - The total size (in bytes) of all attribute values
    ///          AttributeNamesSizeBytes - The total size (in bytes) of all unique attribute names
    /// </remarks>
    /// <param name="TableName">The name of the table (Domain) to get metadata for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The list of available tables for the service, or nil if a failure occurred.</returns>
    function GetTableMetadata(const TableName: string; ResponseInfo: TCloudResponseInfo = nil): TStrings;
    /// <summary>Inserts a row into the given table.</summary>
    /// <remarks>Columns can contain multiple values. You can insert one or more name-value pairs
    ///          where the names (which are the column names) are the same. Furthermore, values could already
    ///          exist on the server for a specific column. If you don't set ReplaceAll to true, then any
    ///          pre-existing values for a column you specify will remain, and your new value(s) will be added.
    ///
    ///          Note that if columns exist on the server, but you don't specify them in this call, then they
    ///          will remain on the server, regardless of the value of ReplaceAll.
    ///
    ///          Conditionals can only be used with single-values attributes.
    /// </remarks>
    /// <param name="TableName">The name of the table to insert the row into</param>
    /// <param name="RowId">The unique Id of the row being inserted/updated</param>
    /// <param name="Row">The row to insert or update</param>
    /// <param name="Conditionals">The conditionals for performing the insert, or nil.</param>
    /// <param name="ReplaceAll">True to replace the values already stored for any specified column names.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the insertion is successful, false otherwise</returns>
    function InsertRow(const TableName, RowId: string; Row: TCloudTableRow;
                       Conditionals: TList<TAmazonRowConditional>;
                       ReplaceAll: Boolean = True;
                       ResponseInfo: TCloudResponseInfo = nil): Boolean;
    /// <summary>Does a batch insert of the given rows into the specified table.</summary>
    /// <remarks>Columns can contain multiple values. You can insert one or more name-value pairs
    ///          where the names (which are the column names) are the same. Furthermore, values could already
    ///          exist on the server for a specific column. If you don't set ReplaceAll to true, then any
    ///          pre-existing values for a column you specify will remain, and your new value(s) will be added.
    ///
    ///          Note that if columns exist on the server, but you don't specify them in this call, then they
    ///          will remain on the server, regardless of the value of ReplaceAll.
    /// </remarks>
    /// <param name="TableName">The name of the table to insert the rows into</param>
    /// <param name="Rows">The rows to batch insert/update</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the insertion is successful, false otherwise</returns>
    function InsertRows(const TableName: string; Rows: TList<TAmazonBatchRow>;
                        ResponseInfo: TCloudResponseInfo = nil): Boolean;
    /// <summary>Returns the rows for the specified table.</summary>
    /// <remarks>The select statement must be a properly formatted Select statement, beginning with "select".
    ///          If you want to specify the 'ItemId' column, use the string: 'ItemName()'
    ///          You can select any columns you wish, use where, like, order by and limit clauses,
    ///          as you would expect from a select statement.
    ///
    ///          If ResponseInfo is specified and there is a NextToken value specified in the resulting
    ///          XML, then a NextToken key/value pair will be put into the ResponseInfo's Headers list.
    /// </remarks>
    /// <param name="SelectStatement">The select statement to issue</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="NextToken">Continuation token (NextToken) value from a previous request</param>
    /// <returns>The XML representation of the row IDs</returns>
    function SelectRowsXML(const SelectStatement: string;
                           ResponseInfo: TCloudResponseInfo = nil;
                           const NextToken: string = ''): string;
    /// <summary>Returns the row (Item) IDs for the specified table.</summary>
    /// <remarks>This selects all attributes of all rows returned, or just the row IDs.
    ///          You can optionally limit the number of results. For more fine-grained control, use SelectRows.
    ///
    ///          If ResponseInfo is specified and there is a NextToken value specified in the resulting
    ///          XML, then a NextToken key/value pair will be put into the ResponseInfo's Headers list.
    /// </remarks>
    /// <param name="TableName">The name of the table to get the row IDs for</param>
    /// <param name="MaxNumberOfItems">The number of rows to return, or 0 to return the maximum allowed number</param>
    /// <param name="ItemIdOnly">True to only return the item name, false to return all attributes (columns)</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="NextToken">Continuation token (NextToken) value from a previous request</param>
    /// <returns>The XML representation of the row IDs</returns>
    function GetRowsXML(const TableName: string;
                        MaxNumberOfItems: Integer = 0;
                        ItemIdOnly: Boolean = False;
                        ResponseInfo: TCloudResponseInfo = nil;
                        const NextToken: string = ''): string;
    /// <summary>Returns the rows (Items) for the specified table.</summary>
    /// <remarks>This selects all attributes of all rows returned. You can optionally limit the number of results.
    ///          For more fine-grained control, use SelectRows.
    ///
    ///          For each row, the first column is called 'ItemName()' and is the Row's unique ID. This can not
    ///          be used in all situations that other column name/value pairs can be used. For example, 'ItemName()'
    ///          can be used in a select statement, but it cannot be deleted from a row.
    /// </remarks>
    /// <param name="TableName">The name of the table to get the row IDs for</param>
    /// <param name="MaxNumberOfItems">The number of rows to return, or 0 to return the maximum allowed number</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="NextToken">Continuation token (NextToken) value from a previous request</param>
    /// <returns>The list of rows, or nil if the call failed</returns>
    function GetRows(const TableName: string;
                     MaxNumberOfItems: Integer = 0;
                     ResponseInfo: TCloudResponseInfo = nil;
                     const NextToken: string = ''): TList<TCloudTableRow>;
    /// <summary>Returns the row (Item) IDs for the specified table.</summary>
    /// <remarks>This selects all attributes of all rows returned. You can optionally limit the number of results.
    ///          For more fine-grained control, use SelectRows.
    /// </remarks>
    /// <param name="TableName">The name of the table to get the row IDs for</param>
    /// <param name="MaxNumberOfItems">The number of rows to return, or 0 to return the maximum allowed number</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="NextToken">Continuation token (NextToken) value from a previous request</param>
    /// <returns>The list of row IDs, or nil if the call failed</returns>
    function GetRowIDs(const TableName: string;
                       MaxNumberOfItems: Integer = 0;
                       ResponseInfo: TCloudResponseInfo = nil;
                       const NextToken: string = ''): TStrings;
    /// <summary>Deletes the specified columns from the given row.</summary>
    /// <remarks>If no columns are specified, then the row is deleted.
    ///          The optional conditionals specify the condition(s) when the delete should happen,
    ///          and when it should not. For more information, see documentation on TAmazonRowConditional.
    ///
    ///          Each item in the list can be either just a column name, or a delimited pair of the column
    ///          name and the column value.
    /// </remarks>
    /// <param name="TableName">The name of the table the row is in</param>
    /// <param name="RowId">The row to delete columns from (or the row to delete, if no columns are specified.)</param>
    /// <param name="Columns">The columns to delete, or nil or empty list to delete the row</param>
    /// <param name="Conditionals">The optional conditionals to be met for the delete to happen</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete terminates without exception, false otherwise.</returns>
    function DeleteColumns(const TableName, RowId: string; const Columns: TStrings;
                           Conditionals: TList<TAmazonRowConditional>;
                           ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
    /// <summary>Deletes the specified columns from the given row.</summary>
    /// <remarks>If no columns are specified, then the row is deleted.
    ///
    ///          Each item in the list can be either just a column name, or a delimited pair of the column
    ///          name and the column value.
    /// </remarks>
    /// <param name="TableName">The name of the table the row is in</param>
    /// <param name="RowId">The row to delete columns from (or the row to delete, if no columns are specified.)</param>
    /// <param name="Columns">The columns to delete, or nil or empty list to delete the row</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete terminates without exception, false otherwise.</returns>
    function DeleteColumns(const TableName, RowId: string; const Columns: TStrings;
                           ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
    /// <summary>Deletes the specified row from the given table.</summary>
    /// <remarks>The optional conditionals specify the condition(s) when the delete should happen,
    ///          and when it should not. For more information, see documentation on TAmazonRowConditional.
    /// </remarks>
    /// <param name="TableName">The name of the table the row is in</param>
    /// <param name="RowId">The Name of the row to delete</param>
    /// <param name="Conditionals">The optional conditionals to be met for the delete to happen</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete terminates without exception, false otherwise.</returns>
    function DeleteRow(const TableName, RowId: string; Conditionals: TList<TAmazonRowConditional>;
                       ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
    /// <summary>Deletes the specified row from the given table.</summary>
    /// <param name="TableName">The name of the table the row is in</param>
    /// <param name="RowId">The Name of the row to delete</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete terminates without exception, false otherwise.</returns>
    function DeleteRow(const TableName, RowId: string; ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
    /// <summary>Deletes the specified columns from the given row.</summary>
    /// <remarks>Each TCloudTableRow in the list must have a column stored internally called 'itemName()',
    ///          which is the name of the row to delete columns from. This column will not be deleted unless
    ///          it is the last column remaining in the row after this delete operation.
    ///
    ///          Note that there is a limit of 25 items (rows) per call.
    /// </remarks>
    /// <param name="TableName">The name of the table the rows are in</param>
    /// <param name="BatchColumns">The rows containing the columns to delete, as well as the itemName() column</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete terminates without exception, false otherwise.</returns>
    function BatchDeleteColumns(const TableName: string; BatchColumns: TList<TCloudTableRow>;
                                ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
  end;

  /// <summary>Implementation of TAmazonBasicService for managing an Amazon Queue Service account.</summary>
  TAmazonQueueService = class(TAmazonBasicService)
  public type
    TQueueAttributePair = TPair<TAmazonQueueAttribute, string>;
    TQueueAttributePairs = TArray<TQueueAttributePair>;
  private
    function IsUniqueMessageId(const AMessageId: string; const AMessageList: array of TCloudQueueMessageItem): Boolean;

    /// <summary>Returns messages from the given queue.</summary>
    /// <remarks>The maximum ANumOfMessages allowed value is 10.
    ///          The maximum AVisibilityTimeout allowed value is 12 hours.
    ///          Note that messages returned by this call will have their PopReceipt specified, which is a
    ///          token unique to the message during the VisibilityTimeout which can be used to delete the message.
    /// </remarks>
    /// <param name="AQueueURL">The URL of the queue to get the messages for.</param>
    /// <param name="ANumOfMessages">The maximum number of messages to return.</param>
    /// <param name="AVisibilityTimeout">How long the messages should be reserved for.</param>
    /// <param name="AResponseInfo">The class for storing response info into.</param>
    /// <returns>The XML representation of the messages.</returns>
    function ReceiveMessageXML(const AQueueURL: string; ANumOfMessages, AVisibilityTimeout: Integer;
      const AResponseInfo: TCloudResponseInfo): string;
    /// <summary>Returns one or more properties for the specified Queue.</summary>
    /// <remarks>The attributes specified will be the property returned by this call. If you specify 'All'
    ///          as an attribute to return, then all properties of the queue will be returned.
    ///          If you pass an empty array, then all attributes will be returned.
    /// </remarks>
    /// <param name="AQueueURL">The URL of the Queue to get the attributes for</param>
    /// <param name="AAttributes">The attributes (or All) to get</param>
    /// <param name="AResponseInfo">The class for storing response info into</param>
    /// <returns>Returns one or more properties of the given queue.</returns>
    function GetQueueAttributesXML(const AQueueURL: string; AAttributes: array of TAmazonQueueAttribute;
      const AResponseInfo: TCloudResponseInfo): string;
  protected
    /// <summary>Returns the version query parameter value to use in requests.</summary>
    /// <returns>The version query parameter value to use in requests.</returns>
    function GetServiceVersion: string; override;
    /// <summary>Returns the Amazon name for the given attribute</summary>
    /// <param name="Attribute">The attribute to get the amazon parameter name for</param>
    /// <returns>The Amazon parameter name representation of the attribute</returns>
    function GetQueueAttributeName(const Attribute: TAmazonQueueAttribute): string;
    /// <summary>Returns the Amazon attribute for the given name</summary>
    /// <param name="AAttributeName">The attribute name</param>
    /// <returns>The Amazon attribute</returns>
    function GetQueueAttributeFromName(const AAttributeName: string): TAmazonQueueAttribute;
    /// <summary>Returns the host string for the service.</summary>
    /// <returns>The host string for the service.</returns>
    function GetServiceHost: string; override;
  public
    /// <summary>Returns the maximum number of queue messages that can be returned.</summary>
    /// <returns>The number of queue messages which can be returned by the API for a given queue.</returns>
    function GetMaxMessageReturnCount: Integer;
    /// <summary>Lists the queues currently available in the queue service account.</summary>
    /// <remarks>The supported optional parameters are: QueueNamePrefix
    ///          The 'QueueNamePrefix' parameter has a value which is the prefix a queue name must start with
    ///          in order to be includes in the list of queues returned by this request.
    /// </remarks>
    /// <param name="OptionalParams">Optional parameters to use in the query. See remarks for more information.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The XML string representing the queues</returns>
    function ListQueuesXML(OptionalParams: TStrings = nil; ResponseInfo: TCloudResponseInfo = nil): string;
    /// <summary>Lists the queues currently available in the queue service account.</summary>
    /// <remarks>The supported optional parameters are: QueueNamePrefix
    ///          The 'QueueNamePrefix' parameter has a value which is the prefix a queue name must start with
    ///          in order to be includes in the list of queues returned by this request.
    /// </remarks>
    /// <param name="OptionalParams">Optional parameters to use in the query. See remarks for more information.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The list of queues, or an empty list</returns>
    function ListQueues(OptionalParams: TStrings = nil; ResponseInfo: TCloudResponseInfo = nil): TList<TCloudQueue>;
    /// <summary>Creates a queue with the given name.</summary>
    /// <remarks>If DefaultVisibilityTimeout is set to -1, then the service default of 30 seconds is used.
    /// </remarks>
    /// <param name="QueueName">The name of the queue to create.</param>
    /// <param name="DefaultVisibilityTimeout">The visibility timeout (in seconds) to use for this queue.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the create was successful, false otherwise.</returns>
    function CreateQueue(const QueueName: string; const DefaultVisibilityTimeout: Integer = -1;
                         ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
    /// <summary>Creates a queue with the given name.</summary>
    /// <remarks>If the call is successful, it sets the value of QueueURL to the newly created Queue's URL.
    ///          If DefaultVisibilityTimeout is set to -1, then the service default of 30 seconds is used.
    ///          For the name: max 80 characters; alphanumeric, hyphens, and underscores are allowed.
    /// </remarks>
    /// <param name="QueueName">The name of the queue to create.</param>
    /// <param name="QueueURL">The resulting queue's URL, or empty string is the request fails</param>
    /// <param name="DefaultVisibilityTimeout">The visibility timeout (in seconds) to use for this queue.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the create was successful, false otherwise.</returns>
    function CreateQueue(const QueueName: string; out QueueURL: string; const DefaultVisibilityTimeout: Integer = -1;
                         ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;
    /// <summary>Creates a queue with the given name.</summary>
    /// <remarks>If the call is successful, it sets the value of QueueURL to the newly created Queue's URL.
    ///          For the name: max 80 characters; alphanumeric, hyphens, and underscores are allowed.
    /// </remarks>
    /// <param name="QueueName">The name of the queue to create.</param>
    /// <param name="QueueURL">The resulting queue's URL, or empty string is the request fails</param>
    /// <param name="Attributes">The list of names and values of the special request parameters the CreateQueue action uses.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the create was successful, false otherwise.</returns>
    function CreateQueue(const QueueName: string; out QueueURL: string; Attributes: array of TQueueAttributePair;
                         ResponseInfo: TCloudResponseInfo = nil): Boolean; overload;

    /// <summary>Deletes the queue with the given URL.</summary>
    /// <remarks>The queue is marked for delete and won't show up in queries, but there will be a short time
    ///          before the server allows another queue with the same name to be created again.
    ///          Note that you must specify the Queue URL, and not just the queue name when deleting.
    ///          The queue URL is provided when calling ListQueues, and is a URL ending in the queue's name.
    /// </remarks>
    /// <param name="QueueURL">The URL of the queue to delete.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete is successful, false otherwise</returns>
    function DeleteQueue(const QueueURL: string; ResponseInfo: TCloudResponseInfo = nil): Boolean;
    /// <summary>This fuction is deprecated. Instead, use GetQueueAttributesXML function.</summary>
    function GetQueuePropertiesXML(const QueueURL: string; Attribute: TAmazonQueueAttribute = aqaAll;
                                   ResponseInfo: TCloudResponseInfo = nil): string; overload; deprecated;
    /// <summary>This fuction is deprecated. Instead, use GetQueueAttributesXML function.</summary>
    function GetQueuePropertiesXML(const QueueURL: string; Attributes: array of TAmazonQueueAttribute;
                                   ResponseInfo: TCloudResponseInfo = nil): string; overload; deprecated;
    /// <summary>This fuction is deprecated. Instead, use GetQueueAttributes function.</summary>
    function GetQueueProperties(const QueueURL: string; Attribute: TAmazonQueueAttribute = aqaAll;
                                ResponseInfo: TCloudResponseInfo = nil): TStrings; overload; deprecated;
    /// <summary>This fuction is deprecated. Instead, use GetQueueAttributes function.</summary>
    function GetQueueProperties(const QueueURL: string; Attributes: array of TAmazonQueueAttribute;
                                ResponseInfo: TCloudResponseInfo = nil): TStrings; overload; deprecated;
    /// <summary>Gets attributes for the specified queue.</summary>
    /// <remarks>If you specify 'All' or an empty array as an attribute to return,
    ///          then all properties of the queue will be returned.
    /// </remarks>
    /// <param name="AQueueURL">The URL of the Queue to get the attributes for.</param>
    /// <param name="AAttributes">The attributes (or All) to get.</param>
    /// <param name="AResponseXML">The response in XML format.</param>
    /// <param name="AResponseInfo">The class for storing response info into.</param>
    /// <returns>Returns one or more properties of the given queue.</returns>
    function GetQueueAttributes(const AQueueURL: string; AAttributes: array of TAmazonQueueAttribute;
      out AResponseXML: string; const AResponseInfo: TCloudResponseInfo): TQueueAttributePairs;
    /// <summary>This fuction is deprecated. Instead, use SetQueueAttributes function.</summary>
    function SetQueueProperty(const QueueURL, Key, Value: string;
                              ResponseInfo: TCloudResponseInfo = nil): Boolean; deprecated;
    /// <summary>Sets the given queue's attributes</summary>
    /// <remarks>See AWS documentation for supported attributes (http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SetQueueAttributes.html)
    /// </remarks>
    /// <param name="AQueueURL">The URL of the Queue to set the attributes for</param>
    /// <param name="AAttributes">The list of attributes to set. See remarks for more information.</param>
    /// <param name="AResponseInfo">The class for storing response info into</param>
    /// <returns>True if the operation was successful, false otherwise.</returns>
    function SetQueueAttributes(const AQueueURL: string; AAttributes: array of TQueueAttributePair;
      const AResponseInfo: TCloudResponseInfo): Boolean;
    /// <summary>This fuction is deprecated. Instead, use AddPermission function.</summary>
    function AddQueuePermissions(const QueueURL, PermissionsLabel: string;
                                 Permissions: array of TAmazonQueuePermission;
                                 ResponseInfo: TCloudResponseInfo = nil): Boolean; deprecated;
    /// <summary>Adds the given permissions to the specified queue.</summary>
    /// <remarks>The specified label will uniquely identify the permission being set.
    ///          The label must be a maximum of 80 characters;
    ///            alphanumeric characters, hyphens (-), and underscores (_) are allowed.
    /// </remarks>
    /// <param name="AQueueURL">The URL of the Queue to add the permissions to.</param>
    /// <param name="APermissionsLabel">The unique identifier for these permissions.</param>
    /// <param name="APermissions">The permissions to add.</param>
    /// <param name="AResponseInfo">The class for storing response info into.</param>
    /// <returns>True if the operation was successful, false otherwise.</returns>
    function AddPermission(const AQueueURL, APermissionsLabel: string; APermissions: array of TAmazonQueuePermission;
      const AResponseInfo: TCloudResponseInfo): Boolean;
    /// <summary>This fuction is deprecated. Instead, use RemovePermission function.</summary>
    function RemoveQueuePermissions(const QueueURL, PermissionsLabel: string;
                                    ResponseInfo: TCloudResponseInfo = nil): Boolean; deprecated;
    /// <summary>Removes the permissions with the given label from the specified queue.</summary>
    /// <param name="AQueueURL">The URL of the Queue to remove the permissions from.</param>
    /// <param name="APermissionsLabel">The unique identifier for the permissions to remove.</param>
    /// <param name="AResponseInfo">The class for storing response info into.</param>
    /// <returns>True if the operation was successful, false otherwise.</returns>
    function RemovePermission(const AQueueURL: string; const APermissionsLabel: string;
      const AResponseInfo: TCloudResponseInfo): Boolean;
    /// <summary>Deletes the messages in a queue specified by the queue URL.</summary>
    /// <param name="AQueueURL">The URL of the Queue to remove the messages from.</param>
    /// <param name="AResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the operation was successful, false otherwise.</returns>
    function PurgeQueue(const AQueueURL: string; const AResponseInfo: TCloudResponseInfo): Boolean;
    /// <summary>This fuction is deprecated. Instead, use SendMessage function.</summary>
    function AddMessage(const QueueURL: string; const MessageText: string;
                        ResponseInfo: TCloudResponseInfo = nil): Boolean; overload; deprecated;
    /// <summary>This fuction is deprecated. Instead, use SendMessage function.</summary>
    function AddMessage(const QueueURL: string; const MessageText: string; out MessageId: string;
                        ResponseInfo: TCloudResponseInfo = nil): Boolean; overload; deprecated;
    /// <summary>Adds a message to the given queue</summary>
    /// <param name="AQueueURL">The URL of the queue to add the message to</param>
    /// <param name="AMessageText">The text of the message</param>
    /// <param name="AMessageId">The Id of the message in the queue, or empty string if add failed.</param>
    /// <param name="AResponseInfo">The class for storing response info into</param>
    /// <returns>True if the message was added successfully, false otherwise.</returns>
    function SendMessage(const AQueueURL, AMessageText: string; out AMessageId: string;
      const AResponseInfo: TCloudResponseInfo): Boolean;

    function SendMessageBatch(const AQueueURL: string; AMessageList: TArray<string>;
      const AResponseInfo: TCloudResponseInfo): TArray<string>;

    /// <summary>This fuction is deprecated. Instead, use ReceiveMessageXML function.</summary>
    function GetMessagesXML(const QueueURL: string;
                            NumOfMessages: Integer = 0;
                            VisibilityTimeout: Integer = -1;
                            ResponseInfo: TCloudResponseInfo = nil): string; deprecated;
    /// <summary>This fuction is deprecated. Instead, use ReceiveMessage function.</summary>
    function GetMessages(const QueueURL: string;
                         NumOfMessages: Integer = 0;
                         VisibilityTimeout: Integer = -1;
                         ResponseInfo: TCloudResponseInfo = nil): TList<TCloudQueueMessage>; deprecated;
    /// <summary>Returns messages from the given queue.</summary>
    /// <remarks>The maximum ANumOfMessages allowed value is 10.
    ///          The maximum AVisibilityTimeout allowed value is 12 hours.
    ///          Note that messages returned by this call will have their PopReceipt specified, which is a
    ///          token unique to the message during the VisibilityTimeout which can be used to delete the message.
    /// </remarks>
    /// <param name="AQueueURL">The URL of the queue to get the messages for.</param>
    /// <param name="ANumOfMessages">The maximum number of messages to return.</param>
    /// <param name="AVisibilityTimeout">How long the messages should be reserved for.</param>
    /// <param name="AResponseXML">The response in XML format.</param>
    /// <param name="AResponseInfo">The class for storing response info into.</param>
    /// <returns>The list of messages, with their pop receipts populated.</returns>
    function ReceiveMessage(const AQueueURL: string; ANumOfMessages: Integer; AVisibilityTimeout: Integer;
      out AResponseXML: string; const AResponseInfo: TCloudResponseInfo): TArray<TCloudQueueMessageItem>;

    /// <summary>This fuction is deprecated. Instead, use ReceiveMessage function.</summary>
    function PeekMessages(const QueueURL: string; NumOfMessages: Integer;
                          ResponseInfo: TCloudResponseInfo = nil): TList<TCloudQueueMessage>; deprecated;
    /// <summary>Deletes the given message from the specified queue</summary>
    /// <param name="QueueURL">URL of the queue to delete a message from</param>
    /// <param name="PopReceipt">The pop receipt required for deleting the message</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the delete was successful, false otherwise</returns>
    function DeleteMessage(const QueueURL: string; const PopReceipt: string;
                           ResponseInfo: TCloudResponseInfo = nil): Boolean;

    function DeleteMessageBatch(const AQueueURL: string; const APopReceiptList: TArray<string>;
      const AResponseInfo: TCloudResponseInfo): Boolean;
    /// <summary>Extends or ends the visibility timeout of a message.</summary>
    /// <remarks>If zero is passed in as the VisibilityTimeout, then the message instantly becomes
    ///          visible by calls to GetMessages. Otherwise, the value passed in, which must be
    ///          between o and 43200 seconds (12 hours) and will be set as the new value for
    ///          VisibilityTimeout for the message associated with the given pop receipt, if any.
    /// </remarks>
    /// <param name="QueueURL">The URL of the queue to get the messages for</param>
    /// <param name="PopReceipt">The previously obtained pop receipt. Associated with a message.</param>
    /// <param name="VisibilityTimeout">Time (in seconds) to have the message hidden for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the operation is successful, false otherwise.</returns>
    function ChangeMessageVisibility(const QueueURL: string; const PopReceipt: string;
                                     const VisibilityTimeout: Integer = 0;
                                     ResponseInfo: TCloudResponseInfo = nil): Boolean;

    function ChangeMessageVisibilityBatch(const AQueueURL: string; AMessageInfoList: TArray<TPair<string, integer>>;
      const AResponseInfo: TCloudResponseInfo): Boolean;

    function ListDeadLetterSourceQueues(const AQueueURL: string; const AResponseInfo: TCloudResponseInfo): TArray<string>;
  end;

  /// <summary>A storage object as returned by a get bucket request.</summary>
  /// <remarks>If a VersionId is specified then this instance represents a version of the object. You can
  ///          use the value of IsLatest to determine if this is the latest version of the object. Also,
  ///          you can check the value of IsDeleted to see if a DeleteMarker is present for the object.
  ///
  ///          If the object is deleted, its size and ETag will not be populated.
  /// </remarks>
  TAmazonObjectResult = record
    /// <summary>The name of the object within the bucket</summary>
    Name: string;
    /// <summary>Date and time the object was last modified.</summary>
    LastModified: string;
    /// <summary>The ETag (MD5 hash) of the object's content.</summary>
    ETag: string;
    /// <summary>The size of the object content, in bytes</summary>
    Size: Int64;
    /// <summary>The ID of the owner of the object</summary>
    OwnerID: string;
    /// <summary>Display name for the owner of the object</summary>
    OwnerDisplayName: string;
    /// <summary>The version ID of the object, if populated.</summary>
    VersionId: string;
    /// <summary>True if the object is the latest version, false otherwise.</summary>
    IsLatest: Boolean;
    /// <summary>True if the object has a delete marker on its latest version, false otherwise.</summary>
    IsDeleted: Boolean;
    /// <summary>The StorageClass value (STANDARD or REDUCED_REDUNDANCY) of the object.</summary>
    StorageClass: string;

    /// <summary>Creates a new instance of TAmazonObjectResult, setting its name.</summary>
    /// <param name="Name">The name of the object</param>
    /// <returns>The new TAmazonObjectResult instance with its name set</returns>
    class function Create(const Name: string): TAmazonObjectResult; static;
  end;

  /// <summary>A storage bucket as returned by a get bucket request.</summary>
  TAmazonBucketResult = class
  private
    FName: string;
    FIsTruncated: Boolean;
    FObjects: TList<TAmazonObjectResult>;
    FPrefixes: TStrings;
    FMarker: string;
    FVersionIdMarker: string;
    FRequestPrefix: string;
    FRequestDelimiter: string;
    FRequestMaxKeys: Integer;
  public
    /// <summary>Creates a new instance of TAmazonBucketResult, setting its name.</summary>
    /// <param name="AName">The name of the bucket</param>
    constructor Create(const AName: string); virtual;
    /// <summary>Frees the resources and destroys the instance.</summary>
    destructor Destroy; override;

    /// <summary>The name of the bucket</summary>
    property Name: string read FName;
    /// <summary>Whether or not all of the objects were returned with the request.</summary>
    property IsTruncated: Boolean read FIsTruncated write FIsTruncated;
    /// <summary>List of objects in the bucket</summary>
    property Objects: TLisT<TAmazonObjectResult> read FObjects;
    /// <summary>The list of prefixes</summary>
    property Prefixes: TStrings read FPrefixes;
    /// <summary>If the results are truncated, this will specify the next object to get.</summary>
    /// <remarks>Use this in a new request to continue populated from where the previous request left off.
    ///          If the request is a version request, use this as the 'key-marker' value instead of 'marker'.
    /// </remarks>
    property Marker: string read FMarker write FMarker;
    /// <summary>If the version results are truncated, this will specify the next object to get.</summary>
    /// <remarks>Use this in a new version request to continue populated from where the previous request left off,
    ///          specifying the specific file version. This corresponds to the 'version-id-marker' parameter.
    /// </remarks>
    property VersionIdMarker: string read FVersionIdMarker write FVersionIdMarker;
    /// <summary>The prefix value used in the request</summary>
    property RequestPrefix: string read FRequestPrefix write FRequestPrefix;
    /// <summary>The delimiter value used in the request</summary>
    property RequestDelimiter: string read FRequestDelimiter write FRequestDelimiter;
    /// <summary>The MaxKeys value used in the request.</summary>
    property RequestMaxKeys: Integer read FRequestMaxKeys write FRequestMaxKeys;
  end;

  /// <summary>Representation of a specific ACL Grant, specifying the Grantee and permission.</summary>
  TAmazonGrant = record
    /// <summary>URI for identifying the Grantee</summary>
    GranteeURI: string;
    /// <summary>ID for identifying the Grantee</summary>
    GranteeID: string;
    /// <summary>Display Name for the Grantee</summary>
    GranteeDisplayName: string;
    /// <summary>Email address for the Grantee</summary>
    GranteeEmailAddress: string;
    /// <summary>The permission being granted to the given Grantee</summary>
    Permission: TAmazonGrantPermission;

    /// <summary>Returns the permission enum for the given string</summary>
    /// <remarks>Returns amgpUnknown if the string isn't one of the expected values.</remarks>
    /// <param name="PermissionString">The string to parse.</param>
    /// <returns>The appropriate permission instance, or amgpUnknown</returns>
    class function GetPermission(const PermissionString: string): TAmazonGrantPermission; static;

    /// <summary>Creates a new instance of TAmazonGrant</summary>
    /// <param name="Permission">The permission, in string format.</param>
    /// <returns>The new TAmazonGrant instance.</returns>
    class function Create(const Permission: string): TAmazonGrant; overload; static;
    /// <summary>Creates a new instance of TAmazonGrant</summary>
    /// <param name="Permission">The permission</param>
    /// <returns>The new TAmazonGrant instance.</returns>
    class function Create(Permission: TAmazonGrantPermission): TAmazonGrant; overload; static;

    /// <summary>Returns the permission in string format.</summary>
    /// <returns>The permission in string format.</returns>
    function PermissionString: string;
    /// <summary>Specifies if the Grantee applies to all users.</summary>
    /// <returns>True if the grantee is all users, false otherwise</returns>
    function IsAllUsers: Boolean;
    /// <summary>Specifies if the Grantee applies to all authenticated users.</summary>
    /// <returns>True if the grantee is all authenticated users, false otherwise</returns>
    function IsAllAuthenticatedUsers: Boolean;
    /// <summary>Specifies if the Grantee applies to the log delivery group.</summary>
    /// <returns>True if the grantee is the log delivery group, false otherwise</returns>
    function IsLogDelivery: Boolean;
    /// <summary>Returns the grantee type based on information stored in this instance</summary>
    /// <returns>The grantee type based on the grantee fields, or agtUnknown</returns>
    function GranteeType: TAmazonGranteeType;
    /// <summary>Returns the grantee type based on information stored in this instance</summary>
    /// <returns>The grantee type (in string format) based on the grantee fields, or empty string</returns>
    function GranteeTypeString: string;
  end;

  /// <summary>Bucket logging information, including target bucket, log prefix and permissions.</summary>
  TAmazonBucketLoggingInfo = class
  const
    LogXMLPrefix = '<?xml version="1.0"?><BucketLoggingStatus xmlns="http://doc.s3.amazonaws.com/2006-03-01">';
    LogXMLSuffix = '</BucketLoggingStatus>';
  private
    FTargetBucket: string;
    FTargetPrefix: string;
    FLoggingEnabled: Boolean;
    FGrants: TList<TAmazonGrant>;
  public
    /// <summary>Creates a new instance of TAmazonBucketLoggingInfo with logging enabled.</summary>
    /// <param name="TargetBucket">The name of the bucket to store the log in.</param>
    /// <param name="TargetPrefix">The log file name prefix.</param>
    constructor Create(const TargetBucket, TargetPrefix: string); overload; virtual;
    /// <summary>Creates a new instance of TAmazonBucketLoggingInfo with logging disabled.</summary>
    constructor Create; overload; virtual;
    /// <summary>Frees the resources and destroys the instance.</summary>
    destructor Destroy; override;

    /// <summary>Returns the instance in XML representation.</summary>
    /// <returns>The instance in XML representation.</returns>
    function AsXML: string;
    /// <summary>Returns the XML to use when disabling logging.</summary>
    /// <returns>The XML to use when disabling logging</returns>
    class function GetDisableXML: string;

    /// <summary>The name of the bucket to store the log in.</summary>
    property Targetbucket: string read FTargetBucket;
    /// <summary>The log file name prefix.</summary>
    property TargetPrefix: string read FTargetPrefix;
    /// <summary>The optional list of logging permissions.</summary>
    property Grants: TList<TAmazonGrant> read FGrants;
    /// <summary>True if logging is enabled, false otherwise</summary>
    property IsLoggingEnabled: Boolean read FLoggingEnabled;
  end;

  /// <summary>A topic for Amazon notification</summary>
  /// <remarks>The Topic field will reference a SNS (Simple Notification Service) topic, to send notifications to.
  ///          Currently, the s3:ReducedRedundancyLostObject event is the only event supported by Amazon S3.
  /// </remarks>
  TAmazonNotificationEvent = record
    /// <summary>The SNS topic to send notifications to.</summary>
    Topic: string;
    /// <summary>The event to notify on.</summary>
    Event: string;

    /// <summary>Creates a new instance of TAmazonNotificationEvent</summary>
    /// <param name="Topic">The SNS topic to send notifications to.</param>
    /// <param name="Event">The event to notify on.</param>
    /// <returns>The new instance of TAmazonNotificationEvent</returns>
    class function Create(const Topic, Event: string): TAmazonNotificationEvent; static;
  end;

  /// <summary>Information about a single item in a list of active multipart uploads.</summary>
  TAmazonMultipartUploadItem = record
    /// <summary>The item's Key (file name)</summary>
    Key: string;
    /// <summary>Unique identifier for a multipart upload.</summary>
    UploadId: string;
    /// <summary>The ID (AWS account or IAM User) of the user who initiated the multipart upload with this ID.
    /// </summary>
    InitiatorId: string;
    /// <summary>The display name of the user who initiated the multipart upload with this ID.</summary>
    InitiatorDisplayName: string;
    /// <summary>The Owner's ID.</summary>
    OwnerId: string;
    /// <summary>The Owner's display name.</summary>
    OwnerDisplayName: string;
    /// <summary>False if the storage class is STANDARD, True if it is REDUCED_REDUNDANCY</summary>
    IsReducedRedundancyStorage: Boolean;
    /// <summary>Date and time when the multipart upload was initiated.</summary>
    DateInitiated: string;

    /// <summary>Creates a new instance of TAmazonMultipartUploadItem</summary>
    /// <param name="AKey">A value to set as Key for the item.</param>
    constructor Create(const AKey: string);
  end;

  /// <summary>Result of a request of all active multipart uploads</summary>
  TAmazonMultipartUploadsResult = class
  private
    FBucket: string;
    FKeyMarker: string;
    FUploadIdMarker: string;
    FNextKeyMarker: string;
    FNextUploadIdMarker: string;
    FMaxUploads: Integer;
    FIsTruncated: Boolean;
    FUploadItems: TList<TAmazonMultipartUploadItem>;
  public
    /// <summary>Creates a new instance of TAmazonMultipartUploadsResult</summary>
    /// <param name="BucketName">The name of the bucket this result is for.</param>
    constructor Create(const BucketName: string); virtual;
    /// <summary>Frees the resources and destroys the instance.</summary>
    destructor Destroy; override;

    /// <summary>The name of the bucket this result is for.</summary>
    property Bucket: string read FBucket;
    /// <summary>The optional key-marker passed in with the request, at or after which the listing began.</summary>
    property KeyMarker: string read FKeyMarker write FKeyMarker;
    /// <summary>The optional upload-id-marker after which listing began.</summary>
    property UploadIdMarker: string read FUploadIdMarker write FUploadIdMarker;
    /// <summary>Continuation token for key-marker if the result is truncated.</summary>
    property NextKeyMarker: string read FNextKeyMarker write FNextKeyMarker;
    /// <summary>Continuation token for upload-id-marker if the result is truncated.</summary>
    property NextUploadIdMarker: string read FNextUploadIdMarker write FNextUploadIdMarker;
    /// <summary>The maximum number of items to return before truncating.</summary>
    property MaxUploads: Integer read FMaxUploads write FMaxUploads;
    /// <summary>True if there are more items after these which were left out because of the MaxUploads value.
    /// </summary>
    property IsTruncated: Boolean read FIsTruncated write FIsTruncated;
    /// <summary>The list of active multipart upload items.</summary>
    property UploadItems: TList<TAmazonMultipartUploadItem> read FUploadItems;
  end;

  /// <summary>An access control policy, containing owner information and a list of grants.</summary>
  TAmazonAccessControlPolicy = class
  private
    FOwnerId: string;
    FOwnerDisplayName: string;
    FGrants: TList<TAmazonGrant>;
  public
    /// <summary>Creates a new instance of TAmazonAccessControlPolicy</summary>
    /// <param name="OwnerId">The Policy owner's ID</param>
    /// <param name="OwnerDisplayName">The Policy owner's display name</param>
    /// <param name="Grants">The list of grants or nil to create an empty list</param>
    constructor Create(const OwnerId, OwnerDisplayName: string; Grants: TList<TAmazonGrant>); virtual;
    /// <summary>Frees the resources and destroys the instance.</summary>
    destructor Destroy; override;
    /// <summary>Returns the XML representation of this instance.</summary>
    function AsXML: string;

    /// <summary>The Policy owner's ID</summary>
    property OwnerId: string read FOwnerId;
    /// <summary>The Policy owner's display name</summary>
    property OwnerDisplayName: string read FOwnerDisplayName;
    /// <summary>The list of grants.</summary>
    property Grants: TList<TAmazonGrant> read FGrants;
  end;

  /// <summary>Record of optional conditional restrictions.</summary>
  /// <remarks>These can be used, for example, when retrieving an object. They provide a way
  ///          to specify under which conditions the action should happen or not happen.
  ///          When doing a copy, these apply to the source object.
  /// </remarks>
  TAmazonActionConditional = record
    /// <summary>A DateTime value. Specify this conditional header to perform the action
    ///          only if the object has been modified since the specified date/time.
    /// </summary>
    IfModifiedSince: string;
    /// <summary>A DateTime value. Specify this conditional header to perform the action
    ///          only if the object has not been modified since the specified date/time.
    /// </summary>
    IfUnmodifiedSince: string;
    /// <summary>Specify an ETag value to perform the action only if the object's ETag value
    ///          matches the value specified.
    /// </summary>
    IfMatch: string;
    /// <summary>Specify an ETag value to perform the action only if the object's ETag value
    ///          does not match the value specified.
    /// </summary>
    IfNoneMatch: string;

    /// <summary>Creates a new instance of TAmazonActionConditional</summary>
    class function Create: TAmazonActionConditional; static;

    /// <summary>Populates the given header list with the key/value pair of any field with an assigned value.
    /// </summary>
    /// <remarks>The keys used will be the header names, as required by Amazon requests. Different header
    ///          names will be used if ForCopy is set to True. For example, if it is false, one header will
    ///          be 'If-Modified-Since'. But if it is true, that header will instead be 'x-amz-copy-source-if-modified-since'
    /// </remarks>
    /// <param name="Headers">The headers list to populate</param>
    /// <param name="ForCopy">True to set copy (source) headers, false to set regular headers.</param>
    procedure PopulateHeaders(Headers: TStrings; ForCopy: Boolean = False);
  end;

  /// <summary>Optional inputs for a GetObject request.</summary>
  /// <remarks>The response fields corresponse to 'response-' headers which can be set to specify
  ///          the value you want to have returned by the response for their corresponding headers.
  /// </remarks>
  TAmazonGetObjectOptionals = record
    /// <summary>Sets the response-content-type header to the specified value.</summary>
    ResponseContentType: string;
    /// <summary>Sets the response-content-language header to the specified value.</summary>
    ResponseContentLanguage: string;
    /// <summary>Sets the response-expires header to the specified value.</summary>
    ResponseExpires: string;
    /// <summary>Sets the reponse-cache-control header to the specified value.</summary>
    ResponseCacheControl: string;
    /// <summary>Sets the response-content-disposition header to the specified value.</summary>
    ResponseContentDisposition: string;
    /// <summary>Sets the response-content-encoding header to the specified value.</summary>
    ResponseContentEncoding: string;
    /// <summary>Conditional for object retrieval.</summary>
    Condition: TAmazonActionConditional;
    /// <summary>Set when retrieving a range of bytes instead of a whole object.</summary>
    RangeStartByte: int64;
    /// <summary>Set when retrieving a range of bytes instead of a whole object.</summary>
    RangeEndByte: int64;

    /// <summary>Creates a new instance of TAmazonGetObjectOptionals</summary>
    class function Create: TAmazonGetObjectOptionals; static;

    /// <summary>Populates the given header list with the key/value pair of any field with an assigned value.
    /// </summary>
    /// <remarks>This also calls into TAmazonActionConditional.PopulateHeaders for the specified Condition.
    /// </remarks>
    /// <param name="Headers">The headers list to populate</param>
    procedure PopulateHeaders(Headers: TStrings);
  end;

  /// <summary>Optional header values for a Copy Object Request.</summary>
  TAmazonCopyObjectOptionals = class
  private
    FCopyMetadata: Boolean;
    FMetadata: TStrings;
    FACL: TAmazonACLType;
    FUseReducedRedundancy: Boolean;
  public
    /// <summary>Conditional for object retrieval.</summary>
    Condition: TAmazonActionConditional;

    /// <summary>Creates a new instance of TAmazonCopyObjectOptionals</summary>
    constructor Create; virtual;
    /// <summary>Frees the resources and destroys the instance.</summary>
    destructor Destroy; override;
    /// <summary>Populates the given header list with the key/value pair of any field with an assigned value.
    /// </summary>
    /// <remarks>This also calls into TAmazonActionConditional.PopulateHeaders for the specified Condition.
    /// </remarks>
    /// <param name="Headers">The headers list to populate</param>
    procedure PopulateHeaders(Headers: TStrings);

    /// <summary>True to copy the source object's metadata to the target object. If false, then the target
    ///          object will have its metadata set based on the content of the Metadata list stored here.
    ///</summary>
    property CopyMetadata: Boolean read FCopyMetadata write FCopyMetadata;
    /// <summary>True to use reduced redundancy for the target object, false to use standard redundancy.</summary>
    property UseReducedRedundancy: Boolean read FUseReducedRedundancy write FUseReducedRedundancy;
    /// <summary>The target object's ACL to set.</summary>
    property ACL: TAmazonACLType read FACL write FACL;
    /// <summary>Metadata to set onto the target object, if 'CopyMetadata' is False.</summary>
    property Metadata: TStrings read FMetadata;
  end;

  /// <summary>Stores Part information for a single part of a multipart upload.</summary>
  /// <remarks>This information will be required to commit the part when completing the multipart upload.
  /// </remarks>
  TAmazonMultipartPart = record
    /// <summary>The part's number in the multipart upload.</summary>
    PartNumber: Integer;
    /// <summary>The parts ETag as returned by the server when the part was uploaded.</summary>
    ETag: string;
    /// <summary>The date the part was last modified.</summary>
    LastModified: string;
    /// <summary>The current size of the part</summary>
    Size: Int64;

    /// <summary>Creates a new instance of TAmazonMultipartPart</summary>
    /// <param name="APartNumber">The part number to set</param>
    /// <param name="AETag">The ETag value to set</param>
    constructor Create(APartNumber: Integer; AETag: string);

    /// <summary>Returns the xml representation of this part.</summary>
    function AsXML: string;
  end;

  /// <summary>Result item for a ListParts request.</summary>
  TAmazonListPartsResult = class
  private
    FBucket: string;
    FObjectName: string;
    FUploadId: string;
    FInitiatorId: string;
    FInitiatorDisplayName: string;
    FOwnerId: string;
    FOwnerDisplayName: string;
    FIsReducedRedundancyStorage: Boolean;
    FPartNumberMarker: Integer;
    FNextPartNumberMarker: Integer;
    FMaxParts: Integer;
    FIsTruncated: Boolean;
    FParts: TList<TAmazonMultipartPart>;
  public
    /// <summary>Creates a new instance of TAmazonListPartsResult.</summary>
    /// <param name="BucketName">The bucket this result is for.</param>
    /// <param name="ObjectName">The object (key) that this result is for.</param>
    /// <param name="UploadId">The multipart upload ID this result represents.</param>
    constructor Create(const BucketName, ObjectName, UploadId: string); virtual;
    /// <summary>Frees the required headers list and destroys the instance</summary>
    destructor Destroy; override;

    /// <summary>The name of the bucket this result is for.</summary>
    property Bucket: string read FBucket;
    /// <summary>The name of the object (key) that this result is for.</summary>
    property ObjectName: string read FObjectName;
    /// <summary>The multipart upload ID this result represents.</summary>
    property UploadId: string read FUploadId write FUploadId;
    /// <summary>The unique ID of the initiator of the multipart upload.</summary>
    /// <remarks>This will be the same as the owner if an AWS account was used. For IAM users the
    ///          value will be the user's ARN.
    /// </remarks>
    property InitiatorId: string read FInitiatorId write FInitiatorId;
    /// <summary>The display name of the initiator.</summary>
    property InitiatorDisplayName: string read FInitiatorDisplayName write FInitiatorDisplayName;
    /// <summary>The AWS Id of the owner of the multipart upload.</summary>
    property OwnerId: string read FOwnerId write FOwnerId;
    /// <summary>The display name of the owner of the multipart upload.</summary>
    property OwnerDisplayName: string read FOwnerDisplayName write FOwnerDisplayName;
    /// <summary>True if the storage type is REDUCED_REDUNDANCY, false if it is STANDARD.</summary>
    property IsReducedRedundancyStorage: Boolean read FIsReducedRedundancyStorage write FIsReducedRedundancyStorage;
    /// <summary>Part number after which listing begins.</summary>
    property PartNumberMarker: Integer read FPartNumberMarker write FPartNumberMarker;
    /// <summary>Continuation token for when result is truncated.</summary>
    /// <remarks>Use this as the value of PartNumberMarker in the next call to continue population.</remarks>
    property NextPartNumberMarker: Integer read FNextPartNumberMarker write FNextPartNumberMarker;
    /// <summary>The maximum number of parts that were allowed for the request.</summary>
    property MaxParts: Integer read FMaxParts write FMaxParts;
    /// <summary>True if more parts exist which weren't returned, false if these were the last parts.</summary>
    property IsTruncated: Boolean read FIsTruncated write FIsTruncated;
    /// <summary>The list of parts for the multipart upload.</summary>
    property Parts: TList<TAmazonMultipartPart> read FParts;
  end;

  /// <summary>Implementation of TAmazonService for managing an Amazon Simple Storage Service (S3) account.</summary>
  TAmazonStorageService = class(TAmazonService)
  private
    function InitHeaders(const BucketName: string; BucketRegion: TAmazonRegion): TStringList;
    procedure AddAndValidateHeaders(const defaultHeaders, customHeaders: TStrings);
    function PopulateResultItem(ObjectNode: IXMLNode; out ResultItem: TAmazonObjectResult): Boolean;
    procedure PopulateGrants(GrantsNode: IXMLNode; Grants: TList<TAmazonGrant>);
    function GetBucketInternal(const XML: string; ResponseInfo: TCloudResponseInfo): TAmazonBucketResult;
    function GetBucketXMLInternal(const BucketName: string; OptionalParams: TStrings;
      VersionInfo: Boolean; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
    function GetNotificationXML(Events: TList<TAmazonNotificationEvent>): string;
    function DeleteObjectInternal(const BucketName, ObjectName, VersionId: string;
      ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
    function GetObjectInternal(const BucketName, ObjectName, VersionId: string;
      OptionalParams: TAmazonGetObjectOptionals; ResponseInfo: TCloudResponseInfo;
      ObjectStream: TStream; BucketRegion: TAmazonRegion): Boolean;
    /// <summary>Determines S3 region name based on the endpoint string.</summary>
    function GetRegionFromEndpoint(const Endpoint: string): string;
    function BuildObjectURL(const BucketName, ObjectName: string; ARegion: TAmazonRegion): string;
  protected
    /// <summary>The lazy-loaded list of required header names.</summary>
    FRequiredHeaderNames: TStrings;

    /// <summary>URL Encodes the param name and value.</summary>
    /// <remarks>Skips encoding if not for URL.</remarks>
    /// <param name="ForURL">True if the parameter is for a URL, false if it is for a signature.</param>
    /// <param name="ParamName">Name of the parameter</param>
    /// <param name="ParamValue">Value of the parameter</param>
    procedure URLEncodeQueryParams(const ForURL: Boolean; var ParamName, ParamValue: string); override;
    /// <summary>Returns the authentication instance to use for the given connection info.</summary>
    /// <returns>The authentication instance to use for the given connection info.</returns>
    function CreateAuthInstance(const ConnectionInfo: TAmazonConnectionInfo): TCloudAuthentication; override;
    /// <summary>Builds the StringToSign value, based on the given information.</summary>
    /// <param name="HTTPVerb">The HTTP verb (eg: GET, POST) of the request type.</param>
    /// <param name="Headers">The list of headers in the request, or nil</param>
    /// <param name="QueryParameters">The list of query parameters for the request, or nil</param>
    /// <param name="QueryPrefix">The string to prefix the query parameter string with.</param>
    /// <param name="URL">The URL of the request.</param>
    /// <returns>The StringToSign, which will be encoded and used for authentication.</returns>
    function BuildStringToSign(const HTTPVerb: string; Headers, QueryParameters: TStringList;
                               const QueryPrefix, URL: string): string; override;
    /// <summary>Handles the StringToSign after it is created.</summary>
    /// <remarks>This modifies the provided URL or the content stream, adding a 'Signature' query parameter.
    /// </remarks>
    /// <param name="HTTPVerb">The HTTP verb (eg: GET, POST) of the request.</param>
    /// <param name="Headers">The header name/value pairs</param>
    /// <param name="QueryParameters">The query parameter name/value pairs</param>
    /// <param name="StringToSign">The StringToSign for the request</param>
    /// <param name="URL">The URL of the request</param>
    /// <param name="Request">The request object</param>
    /// <param name="Content">The content stream of the request.</param>
    procedure PrepareRequestSignature(const HTTPVerb: string;
                                      const Headers, QueryParameters: TStringList;
                                      const StringToSign: string;
                                      var URL: string; Request: TCloudHTTP; var Content: TStream); override;
    /// <summary>Builds the StringToSign value's header part</summary>
    /// <remarks>This will include both the required and optional headers, and end with a newline character.
    /// </remarks>
    /// <param name="Headers">The list of headers in the request, or nil</param>
    /// <returns>The headers portion of the StringToSign</returns>
    function BuildStringToSignHeaders(Headers: TStringList): string; override;
    /// <summary>Returns the list of required header names</summary>
    /// <remarks>Implementation of abstract declaration in parent class.
    ///    Lazy-loads and returns FRequiredHeaderNames. Sets InstanceOwner to false,
    ///    since this class instance will manage the memory for the object.
    /// </remarks>
    /// <param name="InstanceOwner">Returns false, specifying the caller doesn't own the list.</param>
    /// <returns>The list of required hear names. No values.</returns>
    function GetRequiredHeaderNames(out InstanceOwner: Boolean): TStrings; override;
    /// <summary>Returns the header name prefix for Amazon services, for headers to be included
    ///     as name/value pairs in the StringToSign in authentication.
    /// </summary>
    /// <returns>The header prefix (x-amz-)</returns>
    function GetCanonicalizedHeaderPrefix: string; override;
    /// <summary>Returns the current time, formatted properly as a string.</summary>
    /// <returns>The current time, formatted properly as a string</returns>
    function CurrentTime: string; override;
    /// <summary>Populates the given ResponseInfo with error information, if any.</summary>
    /// <remarks>If the given ResponseInfo is non-null, and the ResultString holds an XML error message,
    ///          then this procedure will parse the error XML and populate the ResponseInfo's message
    ///          with the error message.
    /// </remarks>
    /// <param name="ResponseInfo">The optional response info to populate, or nil</param>
    /// <param name="ResultString">The request's response string to parse for an error message.</param>
    procedure ParseResponseError(const ResponseInfo: TCloudResponseInfo; const ResultString: string); override;
    /// <summary>Sorts the given list of Headers.</summary>
    /// <remarks>Extend this if you wish to modify how the list is sorted.</remarks>
    /// <param name="Headers">List of headers to sort.</param>
    procedure SortHeaders(const Headers: TStringList); override;
    function BuildQueryParameterString(const QueryPrefix: string; QueryParameters: TStringList;
                                       DoSort: Boolean = False; ForURL: Boolean = True): string; override;
  public
    /// <summary>Creates a new instance of TAmazonStorageService</summary>
    /// <remarks>This class does not own the ConnectionInfo instance.</remarks>
    // / <param name="ConnectionInfo">The Amazon service connection info</param>
    constructor Create(const ConnectionInfo: TAmazonConnectionInfo);
    /// <summary>Frees the required headers list and destroys the instance</summary>
    destructor Destroy; override;

    /// <summary>Returns the string representation of the given region.</summary>
    /// <param name="Region">The region</param>
    /// <returns>The string representation of the given region.</returns>
    class function GetRegionString(Region: TAmazonRegion): string; static;
    /// <summary>Returns the region for the given string representation.</summary>
    /// <param name="Region">The region in string form</param>
    /// <returns>The region for the given string representation.</returns>
    class function GetRegionFromString(const Region: string): TAmazonRegion; static;
    /// <summary>Lists the buckets owned by the current AWS account.</summary>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The XML representation of all the account's buckets.</returns>
    function ListBucketsXML(const ResponseInfo: TCloudResponseInfo = nil): string;
    /// <summary>Lists the buckets owned by the current AWS account.</summary>
    /// <remarks>The list returned are key/value pairs, where the keys are the bucket names,
    ///          and the values are the creation dates for each bucket. The date is in the
    ///          format: 2011-01-21T10:30:57.000Z ('yyyy-mm-ddThh:nn:ss.zzzZ')
    ///          Note that when parsing the date you may need to escape the 'T' and 'Z'.
    /// </remarks>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The list of all the account's buckets.</returns>
    function ListBuckets(const ResponseInfo: TCloudResponseInfo = nil): TStrings;
    /// <summary>Creates a new bucket with the given name on the S3 service.</summary>
    /// <remarks>Bucket names must be unique to the S3 service. That means if someone else has already used a
    ///          given bucket name with their account, you cannot create a bucket with the same name.
    ///
    ///          Bucket names have some restrictions:
    ///           They must start with a number or letter.
    ///           They can contain periods, underscores and dashes, numbers and lowercase letters.
    ///           They must be between 3 and 255 characters (although shouldn't be longer than 63 characters.)
    ///           They must not be formatted like an IP address (e.g., 192.168.0.1)
    ///
    ///          Furthermore, if you specify a Region when creating the bucket, you must also follow these rules:
    ///           The name can't contain underscores.
    ///           The name must be between 3 and 63 characters long.
    ///           The name can't end in a dash
    ///           The name cannot contain two adjacent periods
    ///           The name cannot contain a dash next to a period. (e.g., 'my.-bucket')
    ///
    ///          You can choose to set the Bucket's access control list and/or the region with this call.
    ///          You can choose a Region to reduce costs or to optimize latency.
    ///          For example, if you are in Europe, you will probably want to create buckets in the EU Region.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to create</param>
    /// <param name="BucketACL">The ACL value to use in the bucket creation</param>
    /// <param name="BucketRegion">The region to create the bucket in</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>True if the creation was successful, false otherwise.</returns>
    function CreateBucket(const BucketName: string; BucketACL: TAmazonACLType = amzbaPrivate;
                          BucketRegion: TAmazonRegion = amzrNotSpecified;
                          ResponseInfo: TCloudResponseInfo = nil): Boolean;
    /// <summary>Deletes the given Bucket.</summary>
    /// <param name="BucketName">The name of the bucket to delete</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket to delete</param>
    /// <returns>True if the deletion was successful, false otherwise.</returns>
    function DeleteBucket(const BucketName: string;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Deletes the policy on the given Bucket.</summary>
    /// <param name="BucketName">The name of the bucket to delete the policy for</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket to delete</param>
    /// <returns>True if the deletion was successful, false otherwise.</returns>
    function DeleteBucketPolicy(const BucketName: string; ResponseInfo: TCloudResponseInfo = nil;
                               BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Returns some or all of the objects of a given bucket.</summary>
    /// <remarks>The optional parameters allow for filtering the results as well as creating a virtual
    ///          directory structure. The supported parameters include:
    ///           delimiter: commonly set to '/' this sets the character to denote a directory
    ///           prefix: Limits the response to object names that begin with the specified prefix
    ///           marker: continuation token, specifying the name of the object to begin population at
    ///           max-keys: (integer) the max number of objects to return.
    ///
    ///          If you want to traverse the objects in a directory structure, then sent the delimiter to
    ///          a character to be used as a path separator, such as a slash character ('/'). The results
    ///          you get back will contain any objects under the 'root directory' and will also contain a
    ///          list of 'prefixes' which are the names of the subdirectories. To traverse the subdirectories,
    ///          set the absolute path of the subdirectory (the prefix value) as the 'prefix' in the next call
    ///          leaving the 'delimiter' as a slash.
    ///
    ///          When more than the maximum number of objects to return exists, 'Truncated' will be set to true.
    ///          To get more objects, use the name of the last object you got as the 'marker' value. That object
    ///          will be populated again in the next call, but none that came before it will.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the objects for</param>
    /// <param name="OptionalParams">Optional parameters for filtering the results. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the bucket's objects and additional information.</returns>
    function GetBucketXML(const BucketName: string; OptionalParams: TStrings;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns some or all of the objects of a given bucket.</summary>
    /// <remarks>For information on the Optional parameters, see remarks on GetBucketXML.
    ///
    ///          When more than the maximum number of objects to return exists, 'Truncated' will be set to true.
    ///          To get more objects, use the name of the last object you got as the 'marker' value. That object
    ///          will be populated again in the next call, but none that came before it will. For convenience,
    ///          this marker value will be placed in the ResponseInfo header 'marker' is a ResponseInfo instance
    ///          is provided and the list of bucket objects is truncated.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the objects for</param>
    /// <param name="OptionalParams">Optional parameters for filtering the results. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The bucket's objects and additional information.</returns>
    function GetBucket(const BucketName: string; OptionalParams: TStrings;
                       ResponseInfo: TCloudResponseInfo = nil;
                       BucketRegion: TAmazonRegion = amzrNotSpecified): TAmazonBucketResult;
    /// <summary>Returns the given bucket's ACL</summary>
    /// <remarks>To get the ACL of the bucket, you must have READ_ACP access to the bucket.
    ///          If READ_ACP permission is set for anonymous users, you can return the bucket's ACL
    ///          without using an authorization header.
    ///
    ///          The possible permissions are:
    ///            FULL_CONTROL
    ///            WRITE
    ///            WRITE_ACP - allow writing the ACL of the bucket
    ///            READ
    ///            READ_ACP - allow reading the ACL of the bucket
    ///
    ///         Users assigned multiple permissions will appear multiple times in the Grant list.
    ///
    ///         All users are granted a permission when the Grantee has a URI of:
    ///          http://acs.amazonaws.com/groups/global/AllUsers.
    ///         All authenticated users are granted a permission when the Grantee has a URI of:
    ///          http://acs.amazonaws.com/groups/global/AuthenticatedUsers.
    ///         The Log delivery group is granted permission when the Grantee has a URI of:
    ///          http://acs.amazonaws.com/groups/global/LogDelivery
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the access control list for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the bucket's ACL</returns>
    function GetBucketACLXML(const BucketName: string;
                             ResponseInfo: TCloudResponseInfo = nil;
                             BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the given bucket's ACL</summary>
    /// <remarks>Users assigned multiple permissions will appear multiple times in the Grant list.
    ///          For more information, see remarks on GetBucketACLXML;
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the access control list for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The bucket's ACL</returns>
    function GetBucketACL(const BucketName: string;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): TList<TAmazonGrant>;
    /// <summary>Returns the given bucket's policies</summary>
    /// <remarks>This returns a string which, if the request is successful, is a JSON representation of
    ///          the policies. See the Amazon S3 documentation for more information on the format.
    ///
    ///          If no policy exists for the given bucket, then the response will be in XML, and will be an error
    ///          message explaining that that the bucket policy doesn't exist. The response code will be 404.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the policies for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The JSON String representation of the bucket's policies</returns>
    function GetBucketPolicyJSON(const BucketName: string;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the given bucket's policies</summary>
    /// <remarks>If the request is successful this returns a JSON representation of
    ///          the policies. See the Amazon S3 documentation for more information on the format.
    ///
    ///          If no policy exists for the given bucket, then the response will be nil and
    ///          the response code will be 404.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the policies for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The JSON String representation of the bucket's policies</returns>
    function GetBucketPolicy(const BucketName: string;
                             ResponseInfo: TCloudResponseInfo = nil;
                             BucketRegion: TAmazonRegion = amzrNotSpecified): TJSONObject;
    /// <summary>Returns the given bucket's location</summary>
    /// <remarks>The location will be one of:
    ///          'EU' | 'us-west-1' | 'ap-southeast-1' | '' (empty string - US Classic Region)
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the location for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The XML representation of the bucket's location</returns>
    function GetBucketLocationXML(const BucketName: string;
                                  ResponseInfo: TCloudResponseInfo = nil): string;
    /// <summary>Returns the given bucket's location</summary>
    /// <remarks>Returns amzrNotSpecified if the request fails.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the location for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <returns>The bucket's region, or empty string for US Classic</returns>
    function GetBucketLocation(const BucketName: string;
                               ResponseInfo: TCloudResponseInfo = nil): TAmazonRegion;
    /// <summary>Returns the given bucket's logging information</summary>
    /// <remarks>This returns the logging status for the bucket as well as the permissions users have
    ///          to view and modify the status.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the logging information for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the bucket's logging information</returns>
    function GetBucketLoggingXML(const BucketName: string;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the given bucket's logging information</summary>
    /// <remarks>This returns the logging status for the bucket as well as the permissions users have
    ///          to view and modify the status.
    ///
    ///          Returns nil if the request fails. Returns a TAmazonBucketLoggingInfo with IsLoggingEnabled
    ///          returning False if logging is disabled on the bucket.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the logging information for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The bucket's logging information</returns>
    function GetBucketLogging(const BucketName: string;
                              ResponseInfo: TCloudResponseInfo = nil;
                              BucketRegion: TAmazonRegion = amzrNotSpecified): TAmazonBucketLoggingInfo;
    /// <summary>Returns the given bucket's notification configuration</summary>
    /// <remarks>Currently, the s3:ReducedRedundancyLostObject event is the only event supported by Amazon S3.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the notification configuration for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The optional region for the notification config</param>
    /// <returns>The XML representation of the bucket's notification configuration</returns>
    function GetBucketNotificationXML(const BucketName: string;
                                      ResponseInfo: TCloudResponseInfo = nil;
                                      BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the given bucket's notification configuration</summary>
    /// <remarks>If the request fails nil will be returned.
    ///          Currently, the s3:ReducedRedundancyLostObject event is the only event supported by Amazon S3.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the notification configuration for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The optional region for the notification config</param>
    /// <returns>The bucket's notification configuration</returns>
    function GetBucketNotification(const BucketName: string;
                                   ResponseInfo: TCloudResponseInfo = nil;
                                   BucketRegion: TAmazonRegion = amzrNotSpecified): TList<TAmazonNotificationEvent>;
    /// <summary>Returns some or all of the objects of a given bucket, returning all versions of each object.</summary>
    /// <remarks>The optional parameters include all optional parameters supported by the GetBucket command,
    ///          except that 'marker' should be called 'key-marker'. Also, 'version-id-marker' is also supported,
    ///          which can be used as a continuation token for a specific file version to continue from.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the objects/versions for</param>
    /// <param name="OptionalParams">Optional parameters for filtering the results. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the bucket's objects/versions and additional information.</returns>
    function GetBucketObjectVersionsXML(const BucketName: string; OptionalParams: TStrings;
                                        ResponseInfo: TCloudResponseInfo = nil;
                                        BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns some or all of the objects of a given bucket.</summary>
    /// <remarks>See remarks on GetBucketObjectVersionsXML for more information.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the objects/versions for</param>
    /// <param name="OptionalParams">Optional parameters for filtering the results. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The bucket's objects/versions and additional information.</returns>
    function GetBucketObjectVersions(const BucketName: string; OptionalParams: TStrings;
                                     ResponseInfo: TCloudResponseInfo = nil;
                                     BucketRegion: TAmazonRegion = amzrNotSpecified): TAmazonBucketResult;
    /// <summary>Returns the user who pays for the given bucket's access.</summary>
    /// <remarks>The options are either the current requester (requires AWS authentication) or the bucket owner.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the payer information for</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the bucket's payer information.</returns>
    function GetRequestPaymentXML(const BucketName: string;
                                  ResponseInfo: TCloudResponseInfo = nil;
                                  BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the user who pays for the given bucket's access.</summary>
    /// <remarks>The options are either the current requester (requires AWS authentication) or the bucket owner.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the payer information for</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The bucket's payer, or ampUnknown if the request fails.</returns>
    function GetRequestPayment(const BucketName: string;
                               ResponseInfo: TCloudResponseInfo = nil;
                               BucketRegion: TAmazonRegion = amzrNotSpecified): TAmazonPayer;
    /// <summary>Returns the versioning configuration for the specified bucket.</summary>
    /// <remarks>The status is 'Enabled' if the given bucket has versioning turned on. Otherwise,
    ///          it is 'Suspended' if versioning has ever been turned on or not specified at all
    ///          if versioning has never been enabled for the specified bucket.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the versioning state for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the versioning configuration.</returns>
    function GetBucketVersioningXML(const BucketName: string;
                                    ResponseInfo: TCloudResponseInfo = nil;
                                    BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the state of versioning for the specified bucket.</summary>
    /// <remarks>Returns true if versioning is enabled for the given bucket. If false is returned
    ///          than either versioning is suspended, or has never been enabled.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the versioning state for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if versioning is enabled, false otherwise.</returns>
    function GetBucketVersioning(const BucketName: string;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Returns the state of MFA (Multi-Factor-Authentication) Delete for the specified bucket.</summary>
    /// <remarks>Returns true if MFA Delete is enabled for the given bucket, false otherwise.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the MFA Delete state for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if MFA is enabled, false otherwise or if the request fails.</returns>
    function GetBucketMFADelete(const BucketName: string;
                                ResponseInfo: TCloudResponseInfo = nil;
                                BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Returns the lifecycle configuration information set on the bucket.</summary>
    /// <remarks>
    ///   To use this operation, you must have permission to perform the s3:GetLifecycleConfiguration action.
    ///   The bucket owner has this permission, by default. The bucket owner can grant this permission to others.
    /// </remarks>
    /// <param name="ABucketName">The name of the bucket to get the lifecycle.</param>
    /// <param name="AResponseInfo">The optional class for storing response info into.</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the stored lifecycle.</returns>
    function GetBucketLifecycleXML(const ABucketName: string;
                                   AResponseInfo: TCloudResponseInfo = nil;
                                   BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns a list of the current active Multipart Uploads.</summary>
    /// <remarks>This lists in-progress multipart uploads and all of their parts.
    ///      The call returns, at most, 1000 result items. The supported optional parameters include:
    ///       delimiter: used to group keys or traverse a virtual directory structure (e.g., '/').
    ///       prefix: Limits the response to object names that begin with the specified prefix
    ///       max-uploads: integer between 1 and 1000. Maximum number of items to return.
    ///       key-marker: Says which file to begin population from. If upload-id-marker isn't specified then
    ///                   population begins from the next file after this file name. Otherwise, population
    ///                   begins at the next upload part if one exists, or the next file.
    ///       upload-id-marker: specifies the multipart upload item to continue population from.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the list of active multipart uploads for.</param>
    /// <param name="OptionalParams">The optional request parameters. See Remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the active multipart upload list.</returns>
    function ListMultipartUploadsXML(const BucketName: string;
                                     const OptionalParams: TStrings;
                                     ResponseInfo: TCloudResponseInfo = nil;
                                     BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns a list of the current active Multipart Uploads.</summary>
    /// <remarks>This lists in-progress multipart uploads and all of their parts.
    ///          For information on the OptionalParams, see remarks on ListMultipartUploadsXML.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to get the list of active multipart uploads for.</param>
    /// <param name="OptionalParams">The optional request parameters. See Remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The ative multipart uploads result, or nil if the request fails.</returns>
    function ListMultipartUploads(const BucketName: string;
                                  const OptionalParams: TStrings;
                                  ResponseInfo: TCloudResponseInfo = nil;
                                  BucketRegion: TAmazonRegion = amzrNotSpecified): TAmazonMultipartUploadsResult;
    /// <summary>Sets the ACL for the given bucket.</summary>
    /// <remarks>The given ACP holds the owner information as well as the ACL.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to set the ACL for.</param>
    /// <param name="ACP">The access control policy containing owner info and the ACL.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketACL(const BucketName: string; ACP: TAmazonAccessControlPolicy;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Sets the Policy for the given bucket.</summary>
    /// <remarks>For information on the Policy JSON format, see the Amazon S3 documentation.
    ///          http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTBucketPUTpolicy.html
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to set the policy for.</param>
    /// <param name="Policy">The policy, formatted as a JSON Object.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketPolicy(const BucketName: string; Policy: TJSONObject;
                             ResponseInfo: TCloudResponseInfo = nil;
                             BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Sets the logging state as well as any Grant information.</summary>
    /// <remarks>If LoggingInfo is nil, logging will be suspended for the given bucket.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to set the logging state for.</param>
    /// <param name="LoggingInfo">The logging info to set</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketLogging(const BucketName: string; LoggingInfo: TAmazonBucketLoggingInfo;
                              ResponseInfo: TCloudResponseInfo = nil;
                              BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Sets the notification events for the given bucket.</summary>
    /// <remarks>If Events is nil or an empty list, then notifications will be disabled for the bucket.
    ///          Note that currently only one event type is supported: s3:ReducedRedundancyLostObject
    ///          See the documentation on TAmazonNotificationEvent for more information.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to set the notification events for.</param>
    /// <param name="Events">The notification events to set</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The optional region for the notification config</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketNotification(const BucketName: string; Events: TList<TAmazonNotificationEvent>;
                                   ResponseInfo: TCloudResponseInfo = nil;
                                   BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Sets who pays for bucket requests.</summary>
    /// <remarks>If anything other than BucketOwner or Requester is passed as the Payer, the request will fail.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to set the Payer for.</param>
    /// <param name="Payer">The user who pays for bucket activity (BucketOwner, Requester)</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketRequestPayment(const BucketName: string; Payer: TAmazonPayer;
                                     ResponseInfo: TCloudResponseInfo = nil;
                                     BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Enables or disables bucket versioning and MFA Delete.</summary>
    /// <remarks>To enable MFA (Multi-Factor-Authentication) Delete, the MFA published properties on the
    ///          Amazon Connection must be set. To enable the ability to use MFA and obtain the
    ///          serial key and token, log into your Amazon account and find the appropriate service.
    ///
    ///          Requests that with MFA (x-amz-mfa) must use HTTPS.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to set the versioning for.</param>
    /// <param name="Enabled">True to enable versioning, false to disable it.</param>
    /// <param name="MFADelete">True to Enable MFA delete, false to disable it.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketVersioning(const BucketName: string; Enabled: Boolean; MFADelete: Boolean = False;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Creates a new lifecycle configuration for the bucket or replaces an existing lifecycle configuration.</summary>
    /// <remarks>For this operation, a user must get the s3:PutLifecycleConfiguration permission.</remarks>
    /// <param name="BucketName">The name of the bucket to set the lifecycle.</param>
    /// <param name="LifeCycle">The lifecycle configuration to set.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetBucketLifecycle(const BucketName: string; const LifeCycle: TAmazonLifeCycleConfiguration;
                                ResponseInfo: TCloudResponseInfo = nil;
                                BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Deletes the specified object from the given bucket.</summary>
    /// <remarks>Use this call when versioning is disabled on the bucket.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to delete the object from.</param>
    /// <param name="ObjectName">The name of the object to delete</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function DeleteObject(const BucketName, ObjectName: string;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Deletes the specified object's version from the given bucket.</summary>
    /// <remarks>You must be the bucket owner to make this call. If the specified version is a delete marker
    ///          and you have provided a ResponseInfo instance, then a 'x-amz-marker' header will be added
    ///          with a value of 'true'.
    ///
    ///          If MFA Delete is enabled then this call will need to be made over HTTPS and values
    ///          must be set on the connection for the MFA Serial Number and MFA Authentication Code.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to delete the object version from.</param>
    /// <param name="ObjectName">The name of the object to delete a version of</param>
    /// <param name="VersionId">Id of the version to delete from the specified object.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function DeleteObjectVersion(const BucketName, ObjectName, VersionId: string;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Deletes the lifecycle configuration from the specified bucket.</summary>
    /// <remarks>
    ///   To use this operation, you must have permission to perform the s3:PutLifecycleConfiguration action.
    ///   By default, the bucket owner has this permission and the bucket owner can grant this permission to others.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket to delete the lifecycle.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function DeleteBucketLifecycle(const BucketName: string;
                                   ResponseInfo: TCloudResponseInfo = nil;
                                   BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Writes the stream for the given object, or nil.</summary>
    /// <remarks>You can use the OptionalParams instance to control the request.
    ///       The returned stream is nil if the request failed. If the request fails on a 404 (File Not Found)
    ///       error, then the requested object may have been deleted. If you provide a ResponseInfo instance,
    ///       then you can check if the object was deleted by verifying there is a 'x-amz-delete-marker'
    ///       response header, and its value is set to 'true'.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get</param>
    /// <param name="OptionalParams">The optional parameters/headers to use in the request.</param>
    /// <param name="ObjectStream">The stream to write to. Must not be nil.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The Object's stream or nil.</returns>
    function GetObject(const BucketName, ObjectName: string; OptionalParams: TAmazonGetObjectOptionals;
                       ObjectStream: TStream; ResponseInfo: TCloudResponseInfo = nil;
                       BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>Writes the stream for the given object, or nil.</summary>
    /// <remarks>If the request fails on a 404 (File Not Found) error, then the requested object may have
    ///          been deleted. If you provide a ResponseInfo instance, then you can check if the object was
    ///          deleted by verifying there is a 'x-amz-delete-marker' response header, and its value
    ///          is set to 'true'.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get</param>
    /// <param name="ObjectStream">The stream to write to. Must not be nil.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The Object's stream or nil.</returns>
    function GetObject(const BucketName, ObjectName: string;
                       ObjectStream: TStream; ResponseInfo: TCloudResponseInfo = nil;
                       BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>Writes the stream for the given object version, or nil.</summary>
    /// <remarks>See GetObject for more information.</remarks>
    /// <param name="BucketName"></param>
    /// <param name="ObjectName"></param>
    /// <param name="VersionId"></param>
    /// <param name="OptionalParams">The optional parameters/headers to use in the request.</param>
    /// <param name="ObjectStream">The stream to write to. Must not be nil.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The Object's stream or nil.</returns>
    function GetObjectVersion(const BucketName, ObjectName, VersionId: string;
                              OptionalParams: TAmazonGetObjectOptionals;
                              ObjectStream: TStream; ResponseInfo: TCloudResponseInfo = nil;
                              BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>Writes the stream for the given object version, or nil.</summary>
    /// <remarks>See GetObject for more information.</remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get a version of</param>
    /// <param name="VersionId">The Id of the version to get.</param>
    /// <param name="ObjectStream">The stream to write to. Must not be nil.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The Object's stream or nil.</returns>
    function GetObjectVersion(const BucketName, ObjectName, VersionId: string;
                              ObjectStream: TStream; ResponseInfo: TCloudResponseInfo = nil;
                              BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>This returns the XML representation of the specified Object's ACL</summary>
    /// <remarks>To use this operation, you must have READ_ACP access to the object.</remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get the ACL for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the Object's Access Control Policy</returns>
    function GetObjectACLXML(const BucketName, ObjectName: string;
                             ResponseInfo: TCloudResponseInfo = nil;
                             BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Returns the given object's ACL</summary>
    /// <remarks>For more information, see remarks on GetObjectACLXML.</remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get the ACL for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The object's ACL grant list</returns>
    function GetObjectACL(const BucketName, ObjectName: string;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): TList<TAmazonGrant>;
    /// <summary>Writes the stream for the given object's torrent, or nil.</summary>
    /// <remarks>You can get torrent only for objects that are less than 5 GB in size.</remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get</param>
    /// <param name="ObjectStream">The stream to write to. Must not be nil.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The Object's stream or nil.</returns>
    function GetObjectTorrent(const BucketName, ObjectName: string; ObjectStream: TStream;
                              ResponseInfo: TCloudResponseInfo = nil;
                              BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>This returns the metadata for the specified object.</summary>
    /// <remarks>An empty list will be returned if no metadata was included on the object.
    ///          The Response* fields of the OptionalParams instance are not used in this call.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get metadata for.</param>
    /// <param name="OptionalParams">The optional parameters/headers to use in the request.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The metadata key/value pairs, or nil if the request fails.</returns>
    function GetObjectMetadata(const BucketName, ObjectName: string; OptionalParams: TAmazonGetObjectOptionals;
                               ResponseInfo: TCloudResponseInfo = nil;
                               BucketRegion: TAmazonRegion = amzrNotSpecified): TStrings; overload;
    /// <summary>This returns the metadata for the specified object.</summary>
    /// <remarks>An empty list will be returned if no metadata was included on the object.</remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get metadata for.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The metadata key/value pairs, or nil if the request fails.</returns>
    function GetObjectMetadata(const BucketName, ObjectName: string;
                               ResponseInfo: TCloudResponseInfo = nil;
                               BucketRegion: TAmazonRegion = amzrNotSpecified): TStrings; overload;

    /// <summary>This returns the properties and metadata for the specified object.</summary>
    /// <remarks>The Response* fields of the OptionalParams instance are not used in this call.
    ///          Empty lists will be returned if no metadata was included on the object.
    ///          The Response* fields of the OptionalParams instance are not used in this call.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get metadata for.</param>
    /// <param name="OptionalParams">The optional parameters/headers to use in the request.</param>
    /// <param name="Properties">The object's properties</param>
    /// <param name="Metadata">The object's metadata</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if the request was successful, false otherwise.</returns>
    function GetObjectProperties(const BucketName, ObjectName: string;
                                 OptionalParams: TAmazonGetObjectOptionals;
                                 out Properties, Metadata: TStrings;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>This returns the properties and metadata for the specified object.</summary>
    /// <remarks>Empty lists will be returned if no metadata was included on the object.
    ///          The Response* fields of the OptionalParams instance are not used in this call.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to get metadata for.</param>
    /// <param name="Properties">The object's properties</param>
    /// <param name="Metadata">The object's metadata</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if the request was successful, false otherwise.</returns>
    function GetObjectProperties(const BucketName, ObjectName: string;
                                 out Properties, Metadata: TStrings;
                                 ResponseInfo: TCloudResponseInfo = nil;
                                 BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>Uploads the given object, optionally setting metadata on it.</summary>
    /// <remarks>Several optional headers can be set to the request. To see a full list, view the Amazon API:
    ///          http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTObjectPUT.html
    ///          Some include: Content-MD5, Content-Type, x-amz-storage-class and several more.
    ///
    ///          If you provide a ResponseInfo instance and versioning is enabled, then a successful request
    ///          will result in a 'x-amz-version-id' header being populated, which is the uploaded object's
    ///          version.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name to use for the object being uploaded.</param>
    /// <param name="Content">The Object's content, in bytes.</param>
    /// <param name="ReducedRedundancy">True to use REDUCED_REDUNDANCY as the object's storage class.</param>
    /// <param name="Metadata">The optional metadata to set on the object, or nil.</param>
    /// <param name="Headers">Optional request headers to use. See remarks.</param>
    /// <param name="ACL">Optional ACL to apply to the object. If unspecified, will default to private.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if the request was successful, false otherwise.</returns>
    function UploadObject(const BucketName, ObjectName: string; Content: TArray<Byte>; ReducedRedundancy: Boolean = false;
                          Metadata: TStrings = nil;
                          Headers: TStrings = nil; ACL: TAmazonACLType = amzbaPrivate;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Sets the ACL for the given object.</summary>
    /// <remarks>The given ACP holds the owner information as well as the ACL.
    ///
    ///          Several optional headers can be set to the request. To see a full list, view the Amazon API:
    ///          http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTObjectPUTacl.html
    ///          Some include: Content-MD5, Content-Type, x-amz-storage-class and several more.
    ///
    ///          If you provide a ResponseInfo instance and versioning is enabled, then a successful request
    ///          will result in a 'x-amz-version-id' header being populated, which is the updated object's
    ///          version.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to set the ACL for.</param>
    /// <param name="ACP">The access control policy containing owner info and the ACL.</param>
    /// <param name="Headers">Optional request headers to use. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetObjectACL(const BucketName, ObjectName: string; ACP: TAmazonAccessControlPolicy;
                          Headers: TStrings = nil; ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>Sets the ACL for the given object.</summary>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The name of the object to set the ACL for.</param>
    /// <param name="ACL">The ACL to apply to the object. If unspecified, will default to private.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetObjectACL(const BucketName, ObjectName: string; ACL: TAmazonACLType;
                          ResponseInfo: TCloudResponseInfo = nil;
                          BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean; overload;
    /// <summary>Copies the specified source object to the given target object.</summary>
    /// <remarks>The OptionalParams instance can be set to provide more control over the request.
    ///          If you provide a ResponseInfo instance, then you can check the value of the
    ///          'x-amz-version-id' header to get the VersionId of the resulting (target) object if
    ///          versioning is enabled. If versioning is enabled then this copy will copy the most
    ///          recent soruce object. The 'x-amz-copy-source-version-id' result header will specify
    ///          the VersionId of the source object that was copied.
    ///          See the comments on TAmazonCopyObjectOptionals for more information.
    ///
    ///          You can change the storage class of an existing object by copying it to the same name
    ///          in the same bucket. To do that, you use the following request optional parameter:
    ///             x-amz-storage-class set to STANDARD or REDUCED_REDUNDANCY
    /// </remarks>
    /// <param name="DestinationBucket">The bucket the object will be copied into.</param>
    /// <param name="DestinationObjectName">The name of the resulting object after the copy.</param>
    /// <param name="SourceBucket">The bucket the object being copied is in.</param>
    /// <param name="SourceObjectName">The name of the object being copied.</param>
    /// <param name="OptionalParams">Optional parameters to refine the request. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function CopyObject(const DestinationBucket, DestinationObjectName: string;
                        const SourceBucket, SourceObjectName: string;
                        OptionalParams: TAmazonCopyObjectOptionals = nil;
                        ResponseInfo: TCloudResponseInfo = nil;
                        BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Sets the metadata on the given object.</summary>
    /// <remarks>This performs a copy object, with the source and destination the same.
    ///          Any previous metadata on the object will be lost.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The object to set the metadata for</param>
    /// <param name="Metadata">The metadata to set on the object</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function SetObjectMetadata(const BucketName, ObjectName: string; Metadata: TStrings;
                               ResponseInfo: TCloudResponseInfo = nil;
                               BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Copies the specified source object's version to the given target object.</summary>
    /// <remarks>See the comments on CopyObject for more information.
    /// </remarks>
    /// <param name="DestinationBucket">The bucket the object will be copied into.</param>
    /// <param name="DestinationObjectName">The name of the resulting object after the copy.</param>
    /// <param name="SourceBucket">The bucket the object being copied is in.</param>
    /// <param name="SourceObjectName">The name of the object being copied.</param>
    /// <param name="SourceVersionId">The Version of the object to copy</param>
    /// <param name="OptionalParams">Optional parameters to refine the request. See remarks.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function CopyObjectVersion(const DestinationBucket, DestinationObjectName: string;
                               const SourceBucket, SourceObjectName, SourceVersionId: string;
                               OptionalParams: TAmazonCopyObjectOptionals = nil;
                               ResponseInfo: TCloudResponseInfo = nil;
                               BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Start a new multipart upload.</summary>
    /// <remarks>The XML returned contains the UploadId. This is required for future calls to 'UploadPart'
    ///          or for stopping/cancelling the multipart upload.
    ///
    ///          There are several supported optional parameters. For a list of them and their functionality,
    ///          go to the Amazon documentation:
    ///
    ///          http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?mpUploadInitiate.html
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object will be in.</param>
    /// <param name="ObjectName">The name of the object this multipart upload will create.</param>
    /// <param name="Metadata">The metadata to set on the resulting object, or nil.</param>
    /// <param name="Headers">Optional headers to set. See remarks.</param>
    /// <param name="ACL">Optional ACL to set on the resulting object.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>XML containing the UploadId to use for subsequent calls.</returns>
    function InitiateMultipartUploadXML(const BucketName, ObjectName: string; Metadata: TStrings = nil;
                                        Headers: TStrings = nil;
                                        ACL: TAmazonACLType = amzbaPrivate;
                                        ResponseInfo: TCloudResponseInfo = nil;
                                        BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Start a new multipart upload.</summary>
    /// <remarks>See comments on InitiateMultipartUploadXML for more information.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the object will be in.</param>
    /// <param name="ObjectName">The name of the object this multipart upload will create.</param>
    /// <param name="Metadata">The metadata to set on the resulting object, or nil.</param>
    /// <param name="Headers">Optional headers to set. See remarks.</param>
    /// <param name="ACL">Optional ACL to set on the resulting object.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The UploadId to use for subsequent calls.</returns>
    function InitiateMultipartUpload(const BucketName, ObjectName: string; Metadata: TStrings = nil;
                                     Headers: TStrings = nil;
                                     ACL: TAmazonACLType = amzbaPrivate;
                                     ResponseInfo: TCloudResponseInfo = nil;
                                     BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Aborts a previously initiated multipart upload.</summary>
    /// <remarks>All storage consumed by previously uplaoded parts for this multipart upload will be freed.
    ///          However, if there are any in-progress part uploads for this UploadId when you abort it,
    ///          then the part may be uploaded successfully and you would then be required to
    ///          abort the UploadId again to free any additional parts.
    /// </remarks>
    /// <param name="BucketName">The bucket the multipart upload object was to be stored.</param>
    /// <param name="ObjectName">The name of the object that would have resulted from the multipart upload.</param>
    /// <param name="UploadId">The UploadId originally returned when the multipart upload was initiated.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function AbortMultipartUpload(const BucketName, ObjectName, UploadId: string;
                                  ResponseInfo: TCloudResponseInfo = nil;
                                  BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Uploads a part to an initiated multipart upload.</summary>
    /// <remarks>All parts except the last part must be at least 5 MB in size.
    ///          Part numbers can be any number from 1 to 10,000, inclusive. If you specify a part number that
    ///          already had been uploaded, the content will be replaced by this content.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the multipart upload's object is for.</param>
    /// <param name="ObjectName">The name of the multipart upload's object.</param>
    /// <param name="UploadId">The multipart upload's unique Id.</param>
    /// <param name="PartNumber">The part number to assign to this content.</param>
    /// <param name="Content">The content to upload.</param>
    /// <param name="Part">The part result (ETag and Number) if the request was successful.</param>
    /// <param name="ContentMD5">The optional MD5 of the content being sent, for integrity checking.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>True if successful, false otherwise.</returns>
    function UploadPart(const BucketName, ObjectName, UploadId: string; PartNumber: Integer; Content: TArray<Byte>;
                        out Part: TAmazonMultipartPart;
                        const ContentMD5: string = '';
                        ResponseInfo: TCloudResponseInfo = nil;
                        BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Completes the given multipart upload, committing the specified parts.</summary>
    /// <param name="BucketName">The name of the bucket the object is in.</param>
    /// <param name="ObjectName">The object the multipart upload is for.</param>
    /// <param name="UploadId">The multipart upload's unique Id.</param>
    /// <param name="Parts">The list of parts to build the resulting object from.</param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>true if successful, false otherwise.</returns>
    function CompleteMultipartUpload(const BucketName, ObjectName, UploadId: string;
                                     Parts: TList<TAmazonMultipartPart>;
                                     ResponseInfo: TCloudResponseInfo = nil;
                                     BucketRegion: TAmazonRegion = amzrNotSpecified): Boolean;
    /// <summary>Lists the currently uploaded parts for multipart upload with the given ID.</summary>
    /// <remarks>MaxParts can be set to a number from 2 to 1000. Set it to 0 to use the server default value.
    ///          PartNumberMarker is the continuation token returned from a previous call, in the XML element
    ///          with the same name.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the multipart upload is for.</param>
    /// <param name="ObjectName">The name of the object the multipart upload is for.</param>
    /// <param name="UploadId">The UploadId identifying the multipart upload.</param>
    /// <param name="MaxParts">The maximum number of parts to return, or 0 for server default.</param>
    /// <param name="PartNumberMarker">The part number to continue population from,
    ///                                or 0 to start from the beginning.
    /// </param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The XML representation of the multipart upload parts.</returns>
    function ListMultipartUploadPartsXML(const BucketName, ObjectName, UploadId: string;
                                         MaxParts: Integer = 0; PartNumberMarker: Integer = 0;
                                         ResponseInfo: TCloudResponseInfo = nil;
                                         BucketRegion: TAmazonRegion = amzrNotSpecified): string;
    /// <summary>Lists the currently uploaded parts for multipart upload with the given ID.</summary>
    /// <remarks>MaxParts can be set to a number from 2 to 1000. Set it to 0 to use the server default value.
    ///          PartNumberMarker is the continuation token returned from a previous call, in the property
    ///          with the same name.
    /// </remarks>
    /// <param name="BucketName">The name of the bucket the multipart upload is for.</param>
    /// <param name="ObjectName">The name of the object the multipart upload is for.</param>
    /// <param name="UploadId">The UploadId identifying the multipart upload.</param>
    /// <param name="MaxParts">The maximum number of parts to return, or 0 for server default.</param>
    /// <param name="PartNumberMarker">The part number to continue population from,
    ///                                or 0 to start from the beginning.
    /// </param>
    /// <param name="ResponseInfo">The optional class for storing response info into</param>
    /// <param name="BucketRegion">The region of the bucket</param>
    /// <returns>The list of multipart upload parts and additional metadata, or nil if the request fails.
    /// </returns>
    function ListMultipartUploadParts(const BucketName, ObjectName, UploadId: string;
                                      MaxParts: Integer = 0; PartNumberMarker: Integer = 0;
                                      ResponseInfo: TCloudResponseInfo = nil;
                                      BucketRegion: TAmazonRegion = amzrNotSpecified): TAmazonListPartsResult;

    /// <summary>Determines S3 Endpoint name based on the region key.</summary>
    function GetEndpointFromRegion(ARegion: TAmazonRegion): string;
  end;

const
  /// <summary>Set as the datatype for a column to force replacement of any previous data for that column
  /// </summary>
  TABLE_ROW_DATATYPE_REPLACE = 'replace';
  /// <summary>Set as the datatype for a column to prevent replacement of any previous data for that column</summary>
  TABLE_ROW_DATATYPE_DO_NOT_REPLACE = 'noreplace';
  /// <summary>Group URI for AllUsers Grantee</summary>
  ALL_USERS_GROUP = 'http://acs.amazonaws.com/groups/global/AllUsers';
  /// <summary>Group URI for AllAuthenticatedUsers Grantee</summary>
  ALL_AUTHENTICATED_USERS_GROUP = 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers';
  /// <summary>Group URI for LogDelivery Grantee</summary>
  LOG_DELIVERY_GROUP = 'http://acs.amazonaws.com/groups/s3/LogDelivery';

implementation

uses
  System.Hash, System.NetConsts, System.Net.HTTPClient, System.TypInfo, System.DateUtils,
  Xml.XMLDoc, System.StrUtils, System.NetEncoding, System.Net.URLClient
{$IFDEF MACOS}
  , Macapi.CoreFoundation
{$ENDIF MACOS}
  ;

const
  NODE_QUEUES = 'ListQueuesResult';
  NODE_QUEUE = 'QueueUrl';
  NODE_ERRORS = 'Errors';
  NODE_ERROR = 'Error';
  NODE_ERROR_MESSAGE = 'Message';
  NODE_ERROR_CODE = 'Code';
  NODE_REQUEST_ID = 'RequestId';
  NODE_RESPONSE_METADATA = 'ResponseMetadata';
  NODE_QUEUE_CREATE_RESULT = 'CreateQueueResult';
  NODE_QUEUE_ATTRIBS_RESULT = 'GetQueueAttributesResult';
  NODE_ATTRIBUTES = 'Attribute';
  NODE_NAME = 'Name';
  NODE_VALUE = 'Value';
  NODE_QUEUE_MESSAGE_RESULT = 'SendMessageResult';
  NODE_QUEUE_MESSAGE_ID = 'MessageId';
  NODE_QUEUE_MESSAGE_RECEIVE_RESULT = 'ReceiveMessageResult';
  NODE_QUEUE_MESSAGE_MD5 = 'MD5OfBody';
  NODE_QUEUE_MESSAGE_POPRECEIPT = 'ReceiptHandle';
  NODE_QUEUE_MESSAGE_BODY = 'Body';
  NODE_QUEUE_MESSAGE = 'Message';
  NODE_BATCH_QUEUE_MESSAGE_RESULT = 'SendMessageBatchResult';
  NODE_BATCH_QUEUE_MESSAGE_RESULT_ENTRY = 'SendMessageBatchResultEntry';
  NODE_DEAD_LETTER_SOURCE_QUEUES = 'ListDeadLetterSourceQueuesResult';
  CLASS_REDUCED_REDUNDANCY = 'REDUCED_REDUNDANCY';

  AmazonGranteeTypeStr: array[TAmazonGranteeType] of string =
    ('CanonicalUser', 'CustomerByEmail', 'Group', 'Unknown');
  AmazonGrantPermissionStr: array[TAmazonGrantPermission] of string =
    ('FULL_CONTROL', 'WRITE', 'WRITE_ACP', 'READ', 'READ_ACP', 'UNKNOWN');

procedure AddS3MetadataHeaders(Headers, Metadata: TStrings);
var
  I, Count: Integer;
  MetaName: string;
begin
  //add the specified metadata into the headers, prefixing each
  //metadata header name with 'x-ms-meta-' if it wasn't already.
  if (MetaData <> nil) and (Headers <> nil) then
  begin
    Count := MetaData.Count;
    for I := 0 to Count - 1 do
    begin
      MetaName := MetaData.Names[I];
      if not AnsiStartsText('x-amz-meta-', MetaName) then
        MetaName := 'x-amz-meta-' + MetaName;
      Headers.Values[MetaName] := MetaData.ValueFromIndex[I];
    end;
  end;
end;

function GetACLTypeString(BucketACL: TAmazonACLType): string;
begin
  case BucketACL of
    amzbaPrivate: Result := 'private';
    amzbaPublicRead: Result := 'public-read';
    amzbaPublicReadWrite: Result := 'public-read-write';
    amzbaAuthenticatedRead: Result := 'authenticated-read';
    amzbaBucketOwnerRead: Result := 'bucket-owner-read';
    amzbaBucketOwnerFullControl: Result := 'bucket-owner-full-control';
    amzbaAWSExecRead: Result := 'aws-exec-read';
    amzbaLogDeliveryWrite: Result := 'log-delivery-write';
  else
    Result := 'private';
  end;
end;

function CaseSensitiveNameCompare(List: TStringList; Index1, Index2: Integer): Integer;
begin
  if List <> nil then
    //CompareStr is used here because Amazon sorts strings based on ASCII order,
    //while AnsiCompareStr does not. (lower-case vs. upper-case)
    Result := CompareStr(List.Names[Index1], List.Names[Index2])
  else
    Result := 0;
end;

function CaseSensitiveHyphenCompare(List: TStringList; Index1, Index2: Integer): Integer;
begin
  if List <> nil then
    //case sensitive stringSort is needed to sort with hyphen (-) precedence
    Result := string.Compare(List.Strings[Index1], List.Strings[Index2], [coStringSort])
  else
    Result := 0;
end;

{ TAmazonAuthentication }

function TAmazonAuthentication.BuildAuthorizationString(const StringToSign: string): string;
begin
  if FAuthInHeader then
    Result := inherited BuildAuthorizationString(StringToSign)
  else
    Result := TNetEncoding.Base64.EncodeBytesToString(SignString(FSHAKey,StringToSign));
end;

constructor TAmazonAuthentication.Create(const ConnectionInfo: TCloudConnectionInfo; AuthInHeader: Boolean);
begin
  inherited Create(ConnectionInfo, AuthorizationType); {do not localize}
  FAuthInHeader := AuthInHeader;
end;

{ TAmazonAWS4Authentication }

procedure TAmazonAWS4Authentication.AssignKey(const AccountKey: string);
begin
  if AccountKey = '' then
    raise Exception.Create('AccountKey is not specified');
  FSHAKey := TEncoding.Default.GetBytes('AWS4'+AccountKey);
end;

function TAmazonAWS4Authentication.BuildAuthorizationString(const StringToSign,
  DateISO, Region, ServiceName, SignedStrHeaders: string): string;

  function GetSignatureKey(const datestamp, region, serviceName: string): TBytes;
  begin
    Result := SignString(FSHAKey, datestamp); //'20130524'
    Result := SignString(Result, region);
    Result := SignString(Result, serviceName);
    Result := SignString(Result, 'aws4_request');
  end;

var
  Signature, Credentials, SignedHeaders: string;
  SigningKey : TBytes;
begin
  SigningKey := GetSignatureKey(DateISO, Region, ServiceName);
  Credentials   := 'Credential='+FConnectionInfo.AccountName + '/'+ DateISO + '/'+Region+ '/' + ServiceName + '/aws4_request'+',';
  SignedHeaders := 'SignedHeaders='+SignedStrHeaders + ',';
  Signature     := 'Signature='+THash.DigestAsString(SignString(SigningKey, StringToSign));
  Result :=  GetAuthorizationType +' '+ Credentials + SignedHeaders + Signature;
end;

function TAmazonAWS4Authentication.BuildAuthorizationString(const StringToSign,
  DateISO, Region, SignedStrHeaders: string): string;
begin
  Result := BuildAuthorizationString(StringToSign, DateISO, Region, 's3', SignedStrHeaders);

end;

constructor TAmazonAWS4Authentication.Create(const ConnectionInfo: TCloudConnectionInfo; AuthInHeader: Boolean);
begin
  inherited Create(ConnectionInfo, AuthorizationType); {do not localize}
  FAuthInHeader := AuthInHeader;
end;

{ TAmazonSHA1Authentication }

constructor TAmazonSHA1Authentication.Create(const ConnectionInfo: TCloudConnectionInfo);
begin
  inherited Create(ConnectionInfo, AuthorizationType); {do not localize}
end;

{ TAmazonConnectionInfo }

constructor TAmazonConnectionInfo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ConsistentRead := True;
  FStorageEndpoint := DefaultStorageEndpoint;
  FTableEndpoint := DefaultTableEndpoint;
  FQueueEndpoint := DefaultQueueEndpoint;
  FRegion := DefaultRegion;
  UseDefaultEndpoints := True;
end;

procedure TAmazonConnectionInfo.SetStorageEndpoint(const AValue: string);
begin
  FStorageEndpoint := AValue;
  if AValue <> DefaultStorageEndpoint then
    UseDefaultEndpoints := False;
end;

procedure TAmazonConnectionInfo.SetQueueEndpoint(const AValue: string);
begin
  FQueueEndpoint := AValue;
  if AValue <> DefaultQueueEndpoint then
    UseDefaultEndpoints := False;
end;

procedure TAmazonConnectionInfo.SetTableEndpoint(const AValue: string);
begin
  FTableEndpoint := AValue;
  if AValue <> DefaultTableEndpoint then
    UseDefaultEndpoints := False;
end;

procedure TAmazonConnectionInfo.SetRegion(const AValue: TAmazonRegion);
begin
  FRegion := AValue;
  if AValue <> DefaultRegion then
    UseDefaultEndpoints := False;
end;

function TAmazonConnectionInfo.GetStorageEndpoint: string;
begin
  if UseDefaultEndpoints then
    Result := DefaultStorageEndpoint
  else
    Result := FStorageEndpoint;
end;

function TAmazonConnectionInfo.GetQueueEndpoint: string;
begin
  if UseDefaultEndpoints then
    Result := DefaultQueueEndpoint
  else
    Result := FQueueEndpoint;
end;

function TAmazonConnectionInfo.GetTableEndpoint: string;
begin
  if UseDefaultEndpoints then
    Result := DefaultTableEndpoint
  else
    Result := FTableEndpoint;
end;

function TAmazonConnectionInfo.GetRegion: TAmazonRegion;
begin
  if UseDefaultEndpoints then
    Result := DefaultRegion
  else
    Result := FRegion;
end;

//note: endpoints and regions may change in the future
class function TAmazonConnectionInfo.GetRegionFromString(const Region: string): TAmazonRegion;
begin
  if Region.Equals('EU') then
    Result := amzrEUWest1
  else if Region.Equals('eu-west-1') then
    Result := amzrEUWest1
  else if Region.Equals('eu-west-2') then
    Result := amzrEUWest2
  else if Region.Equals('eu-west-3') then
    Result := amzrEUWest3
  else if Region.Equals('eu-central-1') then
    Result := amzrEUCentral1
  else if Region.Equals('us-east-1') then
    Result := amzrUSEast1
  else if Region.Equals('us-west-1') then
    Result := amzrUSWest1
  else if Region.Equals( 'us-west-2') then
    Result := amzrUSWest2
  else if Region.Equals('ap-southeast-1') then
    Result := amzrAPSoutheast1
  else if Region.Equals('ap-southeast-2') then
    Result := amzrAPSoutheast2
  else if Region.Equals('ap-northeast-1') then
    Result := amzrAPNortheast1
  else if Region.Equals('ap-northeast-2') then
    Result := amzrAPNortheast2
  else if Region.Equals('ap-northeast-3') then
    Result := amzrAPNortheast3
  else if Region.Equals('sa-east-1') then
    Result := amzrSAEast1
  else if Region.Equals('cn-north-1') then
    Result := amzrCNNorth1
  else if Region.Equals('cn-northwest-1') then
    Result := amzrCNNorthwest1
  else
    Result := amzrUSEast1;
end;

//note: endpoints and regions may change in the future
class function TAmazonConnectionInfo.GetRegionString(Region: TAmazonRegion): string;
begin
  case Region of
    amzrEU: Result := 'eu-west-1'; // deprecate
    amzrEUWest1: Result := 'eu-west-1';
    amzrEUWest2: Result := 'eu-west-2';
    amzrEUWest3: Result := 'eu-west-3';
    amzrEUCentral1: Result := 'eu-central-1';
    amzrUSEast1: Result := 'us-east-1';
    amzrUSWest1: Result := 'us-west-1';
    amzrUSWest2: Result := 'us-west-2';
    amzrAPSoutheast1: Result := 'ap-southeast-1';
    amzrAPSoutheast2: Result := 'ap-southeast-2';
    amzrAPNortheast1: Result := 'ap-northeast-1';
    amzrAPNortheast2: Result := 'ap-northeast-2';
    amzrAPNortheast3: Result := 'ap-northeast-3';
    amzrSAEast1: Result := 'sa-east-1';
    amzrUSClassic: Result := 'us-east-1';  // deprecate
    amzrNotSpecified: Result := 'us-east-1'; // deprecate
    amzrCNNorth1: Result := 'cn-north-1';
    amzrCNNorthwest1: Result := 'cn-northwest-1';
  else
    Result := 'us-east-1';
  end;
end;

function TAmazonConnectionInfo.GetVirtualHost(const AHost, ARegionHost: string;
  ARegion: TAmazonRegion): string;
var
  LRegion: TAmazonRegion;
begin
  LRegion := ARegion;
  if LRegion = amzrNotSpecified then
    LRegion := Region;
  if LRegion = amzrNotSpecified then
    LRegion := DefaultRegion;
  // https://docs.aws.amazon.com/general/latest/gr/rande.html
  if LRegion <> DefaultRegion then
    Result := Format(ARegionHost, [GetRegionString(LRegion)])
  else
    Result := AHost;
end;

function TAmazonConnectionInfo.GetServiceURL(const AHost: string): string;
begin
  Result := Format('%s://%s', [Protocol, AHost]);
end;

function TAmazonConnectionInfo.GetServiceURL(const AHost, ARegionHost: string; ARegion: TAmazonRegion): string;
begin
  Result := GetServiceURL(GetVirtualHost(AHost, ARegionHost, ARegion));
end;

function TAmazonConnectionInfo.GetQueueURL: string;
begin
  Result := GetServiceURL(QueueEndpoint, RegionQueueEndpoint, amzrNotSpecified);
end;

function TAmazonConnectionInfo.GetTableURL: string;
begin
  Result := GetServiceURL(TableEndpoint, RegionTableEndpoint, amzrNotSpecified);
end;

function TAmazonConnectionInfo.StorageVirtualHost(const ABucketName: string; ARegion: TAmazonRegion): string;
begin
  Result := GetVirtualHost(StorageEndpoint, RegionStorageEndpoint, ARegion);
  if ABucketName <> EmptyStr then
    Result := Format('%s.%s', [ABucketName, Result]);
end;

function TAmazonConnectionInfo.StorageURL(const ABucketName: string; ARegion: TAmazonRegion): string;
begin
  Result := GetServiceURL(StorageVirtualHost(ABucketName, ARegion));
end;

{ TAmazonRowConditional }

class function TAmazonRowConditional.Create(const ColumnName, ColumnValue: string;
                                            const ColumnExists: Boolean): TAmazonRowConditional;
var
  Inst: TAmazonRowConditional;
begin
  Inst.ColumnName := ColumnName;
  Inst.ColumnValue := ColumnValue;
  Inst.ColumnExists := ColumnExists;

  Result := Inst;
end;

{ TAmazonService }

constructor TAmazonService.Create(const ConnectionInfo: TAmazonConnectionInfo);
begin
  inherited Create(ConnectionInfo, CreateAuthInstance(ConnectionInfo));

  FUseCanonicalizedHeaders := False;
  FUseCanonicalizedResource := True;
  FUseResourcePath := True;

  //The QueryPrefix (HTTPRequestURI) is on a different line than the query parameters in the StringToSign,
  //but has no start character. So set empty string here.
  FQueryStartChar := #0;
end;

function TAmazonService.CurrentTime: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now),
                           TFormatSettings.Create('en-US'));
end;

destructor TAmazonService.Destroy;
begin
  inherited;
end;

function TAmazonService.GetCanonicalizedHeaderPrefix: string;
begin
  Result := EmptyStr;
end;

function TAmazonService.GetConnectionInfo: TAmazonConnectionInfo;
begin
  Result := TAmazonConnectionInfo(ConnectionInfo);
end;

function TAmazonService.GetRequiredHeaderNames(out InstanceOwner: Boolean): TStrings;
begin
  InstanceOwner := False;
  Result := nil;
end;

procedure TAmazonService.SortHeaders(const Headers: TStringList);
begin
  if (Headers <> nil) then
  begin
    Headers.CustomSort(CaseSensitiveNameCompare);
  end;
end;

function TAmazonService.URLEncodeValue(const Value: string): string;
begin
  //Amazon services expect these characters to be encoded
  Result := URLEncode(Value, ['=', ':', '/', '+', '(', ')', '/', '!', '"', '$', '@', '&', ',', '''', '?', ';']);
end;

function TAmazonService.ISODateTime_noSeparators: string;
begin
  Result := DateToISO8601(TTimeZone.Local.ToUniversalTime(Now),True);
  Result := StringReplace(Result,'-','',[rfReplaceAll]);
  Result := StringReplace(Result,'+','',[rfReplaceAll]);
  Result := StringReplace(Result,':','',[rfReplaceAll]);
  Result := LeftStr(Result,Pos('.',Result)-1)+'Z';
end;

{ TAmazonQueuePermission }

class function TAmazonQueuePermission.Create(const AccountId: string; Action: TAmazonQueueActions): TAmazonQueuePermission;
var
  Inst: TAmazonQueuePermission;
begin
  Inst.AccountId := AccountId;
  Inst.Action := Action;
  Result := Inst;
end;

function TAmazonQueuePermission.GetAction: string;
begin
  case Action of
    aqacAll : Exit('*');
    aqacSendMessage : Exit('SendMessage');
    aqacReceiveMessage : Exit('ReceiveMessage');
    aqacDeleteMessage : Exit('DeleteMessage');
    aqacChangeMessageVisibility : Exit('ChangeMessageVisibility');
    aqacGetQueueAttributes : Exit('GetQueueAttributes');
  end;
end;

{ TAmazonBatchRow }

class function TAmazonBatchRow.Create(const RowId: string; Row: TCloudTableRow;
                                      ReplaceAll: Boolean): TAmazonBatchRow;
var
  Inst: TAmazonBatchRow;
begin
  Inst.RowId := RowId;
  Inst.Row := Row;
  Inst.ReplaceAll := ReplaceAll;
  Result := Inst;
end;

{ TAmazonQueueService }

function TAmazonQueueService.GetQueueAttributeName(const Attribute: TAmazonQueueAttribute): string;
begin
  case Attribute of
    aqaAll:                                   Exit('All');
    aqaApproximateNumberOfMessages:           Exit('ApproximateNumberOfMessages');
    aqaApproximateNumberOfMessagesNotVisible: Exit('ApproximateNumberOfMessagesNotVisible');
    aqaVisibilityTimeout:                     Exit('VisibilityTimeout');
    aqaCreatedTimestamp:                      Exit('CreatedTimestamp');
    aqaLastModifiedTimestamp:                 Exit('LastModifiedTimestamp');
    aqaPolicy:                                Exit('Policy');
    aqaMaximumMessageSize:                    Exit('MaximumMessageSize');
    aqaMessageRetentionPeriod:                Exit('MessageRetentionPeriod');
    aqaQueueArn:                              Exit('QueueArn');
    aqaApproximateNumberOfMessagesDelayed:    Exit('ApproximateNumberOfMessagesDelayed');
    aqaDelaySeconds:                          Exit('DelaySeconds');
    aqaReceiveMessageWaitTimeSeconds:         Exit('ReceiveMessageWaitTimeSeconds');
    aqaRedrivePolicy:                         Exit('RedrivePolicy');
  end;
end;

function TAmazonQueueService.GetQueueAttributeFromName(const AAttributeName: string): TAmazonQueueAttribute;
begin
  if AAttributeName.Equals('All') then Exit(TAmazonQueueAttribute.aqaAll);
  if AAttributeName.Equals('ApproximateNumberOfMessages') then Exit(TAmazonQueueAttribute.aqaApproximateNumberOfMessages);
  if AAttributeName.Equals('ApproximateNumberOfMessagesNotVisible') then Exit(TAmazonQueueAttribute.aqaApproximateNumberOfMessagesNotVisible);
  if AAttributeName.Equals('VisibilityTimeout') then Exit(TAmazonQueueAttribute.aqaVisibilityTimeout);
  if AAttributeName.Equals('CreatedTimestamp') then Exit(TAmazonQueueAttribute.aqaCreatedTimestamp);
  if AAttributeName.Equals('LastModifiedTimestamp') then Exit(TAmazonQueueAttribute.aqaLastModifiedTimestamp);
  if AAttributeName.Equals('Policy') then Exit(TAmazonQueueAttribute.aqaPolicy);
  if AAttributeName.Equals('MaximumMessageSize') then Exit(TAmazonQueueAttribute.aqaMaximumMessageSize);
  if AAttributeName.Equals('MessageRetentionPeriod') then Exit(TAmazonQueueAttribute.aqaMessageRetentionPeriod);
  if AAttributeName.Equals('QueueArn') then Exit(TAmazonQueueAttribute.aqaQueueArn);
  if AAttributeName.Equals('ApproximateNumberOfMessagesDelayed') then Exit(TAmazonQueueAttribute.aqaApproximateNumberOfMessagesDelayed);
  if AAttributeName.Equals('DelaySeconds') then Exit(TAmazonQueueAttribute.aqaDelaySeconds);
  if AAttributeName.Equals('ReceiveMessageWaitTimeSeconds') then Exit(TAmazonQueueAttribute.aqaReceiveMessageWaitTimeSeconds);
  if AAttributeName.Equals('RedrivePolicy') then Exit(TAmazonQueueAttribute.aqaRedrivePolicy);
  Exit(TAmazonQueueAttribute.aqaAll);
end;

function TAmazonQueueService.ListQueuesXML(OptionalParams: TStrings;
                                           ResponseInfo: TCloudResponseInfo): string;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('ListQueues');

  if OptionalParams <> nil then
    QueryParams.AddStrings(OptionalParams);

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.QueueURL, QueryParams, ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonQueueService.ListQueues(OptionalParams: TStrings; ResponseInfo: TCloudResponseInfo): TList<TCloudQueue>;
var
  xml: string;
  xmlDoc: IXMLDocument;
  QueuesXMLNode: IXMLNode;
  QueueNode: IXMLNode;
begin
  xml := ListQueuesXML(OptionalParams, ResponseInfo);

  if XML = EmptyStr then
    Exit(nil);

  Result := TList<TCloudQueue>.Create;

  xmlDoc := TXMLDocument.Create(nil);
  xmlDoc.LoadFromXML(XML);

  QueuesXMLNode := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_QUEUES);

  if (QueuesXMLNode <> nil) and (QueuesXMLNode.HasChildNodes) then
  begin
    QueueNode := QueuesXMLNode.ChildNodes.FindNode(NODE_QUEUE);

    while (QueueNode <> nil) do
    begin
      if QueueNode.NodeName = NODE_QUEUE then
      begin
        //the Queue node ('QueueUrl') has only a text value, which is the Queue URL
        Result.Add(TCloudQueue.Create(QueueNode.Text));
      end;
      QueueNode := QueueNode.NextSibling;
    end;
  end;
end;

function TAmazonQueueService.CreateQueue(const QueueName: string; const DefaultVisibilityTimeout: Integer;
                                         ResponseInfo: TCloudResponseInfo): Boolean;
var
  URL: string;
begin
  Result := CreateQueue(QueueName, URL, DefaultVisibilityTimeout, ResponseInfo);
end;

function TAmazonQueueService.CreateQueue(const QueueName: string; out QueueURL: string;
                                         const DefaultVisibilityTimeout: Integer;
                                         ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, QueueNode: IXMLNode;
begin
  QueryParams := BuildQueryParameters('CreateQueue');

  QueryParams.Values['QueueName'] := QueueName;

  if DefaultVisibilityTimeout > -1 then
  begin
    QueryParams.Values['Attribute.1.Name'] := 'VisibilityTimeout';
    QueryParams.Values['Attribute.1.Value'] := IntToStr(DefaultVisibilityTimeout);
  end;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.QueueURL, QueryParams, ResponseInfo, xml);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
    FreeAndNil(Response);

    if Result and (xml <> EmptyStr) then
    begin
      //Parse XML and get QueueURL value
      xmlDoc := TXMLDocument.Create(nil);
      xmlDoc.LoadFromXML(XML);

      ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_QUEUE_CREATE_RESULT);

      if (ResultNode <> nil) and (ResultNode.HasChildNodes) then
      begin
        QueueNode := ResultNode.ChildNodes.FindNode(NODE_QUEUE);
        if (QueueNode <> nil) and (QueueNode.IsTextElement) then
          QueueURL := QueueNode.Text;
      end;
    end;
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonQueueService.CreateQueue(const QueueName: string; out QueueURL: string;
                                         Attributes: array of TQueueAttributePair;
                                         ResponseInfo: TCloudResponseInfo = nil): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  attribute: TQueueAttributePair;
  nattr: Integer;
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, QueueNode: IXMLNode;
begin
  QueryParams := BuildQueryParameters('CreateQueue');

  QueryParams.Values['QueueName'] := QueueName;

  for nAttr := 0 to Length(Attributes)-1 do
  begin
    attribute := Attributes[nAttr];

    QueryParams.Values[Format('Attribute.%d.Name',[nAttr+1])] := GetQueueAttributeName(attribute.key);
    QueryParams.Values[Format('Attribute.%d.Value',[nAttr+1])] := attribute.Value;
  end;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.QueueURL, QueryParams, ResponseInfo, xml);
    Result := (Response <> nil) and (Response.ResponseCode = 200);

    if Result and (xml <> EmptyStr) then
    begin
      //Parse XML and get QueueURL value
      xmlDoc := TXMLDocument.Create(nil);
      xmlDoc.LoadFromXML(XML);

      ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_QUEUE_CREATE_RESULT);

      if (ResultNode <> nil) and (ResultNode.HasChildNodes) then
      begin
        QueueNode := ResultNode.ChildNodes.FindNode(NODE_QUEUE);
        if (QueueNode <> nil) and (QueueNode.IsTextElement) then
          QueueURL := QueueNode.Text;
      end;
    end;
  finally
    Response.Free;
    QueryParams.Free;
  end;
end;

function TAmazonQueueService.DeleteMessage(const QueueURL, PopReceipt: string;
                                           ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('DeleteMessage');

  QueryParams.Values['ReceiptHandle'] := PopReceipt;

  Response := nil;
  try
    Response := IssueRequest(QueueURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonQueueService.DeleteMessageBatch(const AQueueURL: string; const APopReceiptList: TArray<string>;
  const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LPopReceipt: string;
  I: Integer;
begin
  LQueryParams := BuildQueryParameters('DeleteMessageBatch');

  I := 1;
  for LPopReceipt in APopReceiptList do
  begin
    LQueryParams.Values['DeleteMessageBatchRequestEntry.' + I.ToString + '.Id'] := 'delete_msg_' + i.ToString;
    LQueryParams.Values['DeleteMessageBatchRequestEntry.' + I.ToString + '.ReceiptHandle'] := LPopReceipt;
    inc(I);
  end;

  LResponse := nil;
  try
    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.DeleteQueue(const QueueURL: string; ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('DeleteQueue');

  Response := nil;
  try
    Response := IssueRequest(QueueURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonQueueService.GetQueuePropertiesXML(const QueueURL: string;
                                                   Attributes: array of TAmazonQueueAttribute;
                                                   ResponseInfo: TCloudResponseInfo): string;
begin
  Result := GetQueueAttributesXML(QueueURL, Attributes, ResponseInfo);
end;

function TAmazonQueueService.GetQueueAttributesXML(const AQueueURL: string; AAttributes: array of TAmazonQueueAttribute;
  const AResponseInfo: TCloudResponseInfo): string;
var
  LQueryParams: TStringList;
  LIndex: Integer;
  LAttr: TAmazonQueueAttribute;
  LResponse: TCloudHTTP;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('GetQueueAttributes');
    if Length(AAttributes) = 0 then
      LQueryParams.Values['AttributeName'] := 'All'
    else
    begin
      LIndex := 1;
      for LAttr in AAttributes do
      begin
        LQueryParams.Values['AttributeName.' + LIndex.ToString] := GetQueueAttributeName(LAttr);
        Inc(LIndex);
      end;
    end;

    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo, Result);
  finally
    LQueryParams.Free;
    LResponse.Free;
  end;
end;

function TAmazonQueueService.GetServiceHost: string;
begin
  Result := GetConnectionInfo.QueueEndpoint;
end;

function TAmazonQueueService.GetServiceVersion: string;
begin
  Result := '2012-11-05';
end;

function TAmazonQueueService.GetQueuePropertiesXML(const QueueURL: string; Attribute: TAmazonQueueAttribute;
                                                   ResponseInfo: TCloudResponseInfo): string;
begin
  Result := GetQueueAttributesXML(QueueURL, [Attribute], ResponseInfo);
end;

function TAmazonQueueService.GetQueueProperties(const QueueURL: string; Attribute: TAmazonQueueAttribute;
                                                ResponseInfo: TCloudResponseInfo): TStrings;
var
  LXML: string;
  LAttrs: TQueueAttributePairs;
  LAttr: TQueueAttributePair;
begin
  Result := nil;
  LAttrs := GetQueueAttributes(QueueURL, [Attribute], LXML, ResponseInfo);

  if Length(LAttrs) > 0 then
  begin
    Result := TStringList.Create;
    for LAttr in LAttrs do
      Result.Values[GetQueueAttributeName(LAttr.Key)] := LAttr.Value;
  end;
end;

function TAmazonQueueService.GetQueueProperties(const QueueURL: string;
                                                Attributes: array of TAmazonQueueAttribute;
                                                ResponseInfo: TCloudResponseInfo): TStrings;
var
  LXML: string;
  LAttrs: TQueueAttributePairs;
  LAttr: TQueueAttributePair;
begin
  Result := nil;
  LAttrs := GetQueueAttributes(QueueURL, Attributes, LXML, ResponseInfo);

  if Length(LAttrs) > 0 then
  begin
    Result := TStringList.Create;
    for LAttr in LAttrs do
      Result.Values[GetQueueAttributeName(LAttr.Key)] := LAttr.Value;
  end;
end;

function TAmazonQueueService.GetQueueAttributes(const AQueueURL: string; AAttributes: array of TAmazonQueueAttribute;
  out AResponseXML: string; const AResponseInfo: TCloudResponseInfo): TQueueAttributePairs;
var
  LXMLDoc: IXMLDocument;
  LRootNode, LQueueAttrsNode, LAttrNode, LAux: IXMLNode;
  LNodeName: string;
begin
  AResponseXML := GetQueueAttributesXML(AQueueURL, AAttributes, AResponseInfo);

  if not AResponseXML.IsEmpty then
  begin
    LXMLDoc := TXMLDocument.Create(nil);
    LXMLDoc.LoadFromXML(AResponseXML);
    LRootNode := LXMLDoc.DocumentElement;

    if LRootNode.HasChildNodes then
    begin
      LQueueAttrsNode := LRootNode.ChildNodes.FindNode(NODE_QUEUE_ATTRIBS_RESULT);
      if (LQueueAttrsNode <> nil) and LQueueAttrsNode.HasChildNodes then
      begin
        LAttrNode := GetFirstMatchingChildNode(LQueueAttrsNode, NODE_ATTRIBUTES);
        while LAttrNode <> nil do
        begin
          LAux := LAttrNode.ChildNodes.FindNode(NODE_NAME);
          if (LAux <> nil) and LAux.IsTextElement then
          begin
            LNodeName := LAux.Text;
            LAux := LAttrNode.ChildNodes.FindNode(NODE_VALUE);
            if (LAux <> nil) and LAux.IsTextElement then
              Result := Result + [TQueueAttributePair.Create(GetQueueAttributeFromName(LNodeName), LAux.Text)];
          end;
          LAttrNode := LAttrNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonQueueService.SetQueueProperty(const QueueURL, Key, Value: string;
                                                ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := SetQueueAttributes(QueueURL, [TQueueAttributePair.Create(GetQueueAttributeFromName(Key), Value)],
    ResponseInfo);
end;

function TAmazonQueueService.SetQueueAttributes(const AQueueURL: string; AAttributes: array of TQueueAttributePair;
  const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LAttribute: TQueueAttributePair;
  LIndex: Integer;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('SetQueueAttributes');

    LIndex := 1;
    for LAttribute in AAttributes do
    begin
      LQueryParams.Values['Attribute.' + LIndex.ToString + '.Name' ] := GetQueueAttributeName(LAttribute.Key);
      LQueryParams.Values['Attribute.' + LIndex.ToString + '.Value'] := LAttribute.Value;
      Inc(LIndex);
    end;

    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.AddQueuePermissions(const QueueURL, PermissionsLabel: string;
                                                 Permissions: array of TAmazonQueuePermission;
                                                 ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := AddPermission(QueueURL, PermissionsLabel, Permissions, ResponseInfo);
end;

function TAmazonQueueService.AddPermission(const AQueueURL, APermissionsLabel: string;
  APermissions: array of TAmazonQueuePermission; const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LIndex: Integer;
  LPermission: TAmazonQueuePermission;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('AddPermission');
    LQueryParams.Values['Label'] := APermissionsLabel;

    LIndex := 1;
    for LPermission in APermissions do
    begin
      LQueryParams.Values['AWSAccountId.' + LIndex.ToString] := LPermission.AccountId;
      LQueryParams.Values['ActionName.' + LIndex.ToString] := LPermission.GetAction;
      Inc(LIndex);
    end;

    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.RemoveQueuePermissions(const QueueURL, PermissionsLabel: string;
                                                    ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := RemovePermission(QueueURL, PermissionsLabel, ResponseInfo);
end;

function TAmazonQueueService.RemovePermission(const AQueueURL: string; const APermissionsLabel: string;
  const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('RemovePermission');
    LQueryParams.Values['Label'] := APermissionsLabel;

    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.PurgeQueue(const AQueueURL: string; const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LQueryParams: TStringList;
  LResponse: TCloudHTTP;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('PurgeQueue');
    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LQueryParams.Free;
    LResponse.Free;
  end;
end;

function TAmazonQueueService.AddMessage(const QueueURL, MessageText: string;
                                        ResponseInfo: TCloudResponseInfo): Boolean;
var
  MsgId: string;
begin
  Result := SendMessage(QueueURL, MessageText, MsgId, ResponseInfo);
end;

function TAmazonQueueService.AddMessage(const QueueURL, MessageText: string; out MessageId: string;
                                        ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := SendMessage(QueueURL, MessageText, MessageId, ResponseInfo);
end;

function TAmazonQueueService.SendMessage(const AQueueURL: string; const AMessageText: string; out AMessageId: string;
 const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LXML: string;
  LXMLDoc: IXMLDocument;
  LRootNode, LResultNode, LIdNode: IXMLNode;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('SendMessage');
    LQueryParams.Values['MessageBody'] := AMessageText;

    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo, LXML);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);

    //parse the XML to get the MessageId
    if Result and not LXML.IsEmpty then
    begin
      LXMLDoc := TXMLDocument.Create(nil);
      LXMLDoc.LoadFromXML(LXML);
      LRootNode := LXMLDoc.DocumentElement;

      if (LRootNode <> nil) and (LRootNode.HasChildNodes) then
      begin
        LResultNode := LRootNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_RESULT);
        if (LResultNode <> nil) and (LResultNode.HasChildNodes) then
        begin
          LIdNode := LResultNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_ID);
          if (LIdNode <> nil) and LIdNode.IsTextElement then
            AMessageId := LIdNode.Text;
        end;
      end;
    end;
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.SendMessageBatch(const AQueueURL: string; AMessageList: TArray<string>;
  const AResponseInfo: TCloudResponseInfo): TArray<string>;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LMessage: string;
  LXML: string;
  LXMLDoc: IXMLDocument;
  LRootNode, LBatchResult, LBatchEntry, LIdNode: IXMLNode;
  I: Integer;
  LResult: Boolean;
begin
  LQueryParams := BuildQueryParameters('SendMessageBatch');

  I := 1;
  for LMessage in AMessageList do
  begin
    LQueryParams.Values['SendMessageBatchRequestEntry.' + I.ToString + '.Id'] := 'msg' + I.ToString;
    LQueryParams.Values['SendMessageBatchRequestEntry.' + I.ToString + '.MessageBody'] := LMessage;
    Inc(I);
  end;

  LResponse := nil;
  try
    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo, LXML);
    LResult := (LResponse <> nil) and (LResponse.ResponseCode = 200);

    //parse the XML to get the MessageId
    if LResult and not LXML.IsEmpty then
    begin
      LXMLDoc := TXMLDocument.Create(nil);
      LXMLDoc.LoadFromXML(LXML);
      LRootNode := LXMLDoc.DocumentElement;

      if (LRootNode <> nil) and (LRootNode.HasChildNodes) then
      begin
        LBatchResult := LRootNode.ChildNodes.FindNode(NODE_BATCH_QUEUE_MESSAGE_RESULT);
        LBatchEntry := LBatchResult.ChildNodes.FindNode(NODE_BATCH_QUEUE_MESSAGE_RESULT_ENTRY);

        while (LBatchEntry <> nil) do
        begin
          LIdNode := LBatchEntry.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_ID);
          if (LIdNode <> nil) and LIdNode.IsTextElement then
            Result := Result + [LIdNode.Text];
          LBatchEntry := LBatchEntry.NextSibling;
        end;
      end;
    end;
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.GetMessagesXML(const QueueURL: string; NumOfMessages, VisibilityTimeout: Integer;
                                            ResponseInfo: TCloudResponseInfo): string;
begin
  Result := ReceiveMessageXML(QueueURL, NumOfMessages, VisibilityTimeout, ResponseInfo);
end;

function TAmazonQueueService.ReceiveMessageXML(const AQueueURL: string; ANumOfMessages, AVisibilityTimeout: Integer;
  const AResponseInfo: TCloudResponseInfo): string;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
begin
  LResponse := nil;
  LQueryParams := nil;
  try
    LQueryParams := BuildQueryParameters('ReceiveMessage');
    //get all attributes associated with the message
    LQueryParams.Values['AttributeName'] := 'All';

    if ANumOfMessages > 0 then
      LQueryParams.Values['MaxNumberOfMessages'] := IntToStr(ANumOfMessages);

    if AVisibilityTimeout > -1 then
      LQueryParams.Values['VisibilityTimeout'] := IntToStr(AVisibilityTimeout);

    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo, Result);
  finally
    LQueryParams.Free;
    LResponse.Free;
  end;
end;

function TAmazonQueueService.GetMaxMessageReturnCount: Integer;
begin
  Result := 10;
end;

function TAmazonQueueService.IsUniqueMessageId(const AMessageId: string;
  const AMessageList: array of TCloudQueueMessageItem): Boolean;
var
  LItem: TCloudQueueMessageItem;
begin
  if AMessageId.IsEmpty then
    Exit(False);

  Result := True;
  //MessageId is not valid if the given list already contains it
  for LItem in AMessageList do
    if LItem.MessageId.Equals(AMessageId) then
      Exit(False);
end;

function TAmazonQueueService.GetMessages(const QueueURL: string; NumOfMessages, VisibilityTimeout: Integer;
                                         ResponseInfo: TCloudResponseInfo): TList<TCloudQueueMessage>;
var
  LXML: string;
  LMessages: TArray<TCloudQueueMessageItem>;
  LMessage: TCloudQueueMessageItem;
begin
  Result := TList<TCloudQueueMessage>.Create;
  LMessages := ReceiveMessage(QueueURL, NumOfMessages, VisibilityTimeout, LXML, ResponseInfo);

  if Length(LMessages) > 0 then
    for LMessage in LMessages do
      Result.Add(TCloudQueueMessage.CreateFromRecord(LMessage));
end;

function TAmazonQueueService.ReceiveMessage(const AQueueURL: string; ANumOfMessages: Integer; AVisibilityTimeout: Integer;
  out AResponseXML: string; const AResponseInfo: TCloudResponseInfo): TArray<TCloudQueueMessageItem>;
var
  LXMLDoc: IXMLDocument;
  LRootNode, LResultNode, LMessageNode, LItemNode, LAttrNode: IXMLNode;
  LMessageId: string;
  LItem: TCloudQueueMessageItem;
begin
  SetLength(Result, 0);
  AResponseXML := ReceiveMessageXML(AQueueURL, ANumOfMessages, AVisibilityTimeout, AResponseInfo);
  if not AResponseXML.IsEmpty then
  begin
    LXMLDoc := TXMLDocument.Create(nil);
    LXMLDoc.LoadFromXML(AResponseXML);
    LRootNode := LXMLDoc.DocumentElement;

    if LRootNode.HasChildNodes then
    begin
      LResultNode := LRootNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_RECEIVE_RESULT);
      if (LResultNode <> nil) and LResultNode.HasChildNodes then
      begin
        LMessageNode := GetFirstMatchingChildNode(LResultNode, NODE_QUEUE_MESSAGE);

        while LMessageNode <> nil do
        begin
          //Get the MessageId, then if that is siccessful, populate the message body
          //all other attributes are optional
          LItemNode := LMessageNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_ID);
          if (LItemNode <> nil) and LItemNode.IsTextElement then
          begin
            LMessageId := LItemNode.Text;
            if IsUniqueMessageId(LMessageId, Result) then
            begin
              LItemNode := LMessageNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_BODY);

              if (LItemNode <> nil) and LItemNode.IsTextElement then
              begin
                //populate optional attributes and pop receipt
                LItem.MessageId := LMessageID;
                LItem.MessageText := LItemNode.Text;
                //populate the pop receipt (called ReceiptHandle in Amazon)
                //only do this if VisibilityTimeout was set to something greater than zero.
                if AVisibilityTimeout > 0 then
                begin
                  LItemNode := LMessageNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_POPRECEIPT);
                  if (LItemNode <> nil) and LItemNode.IsTextElement then
                    LItem.PopReceipt := LItemNode.Text;
                end;

                LItemNode := LMessageNode.ChildNodes.FindNode(NODE_QUEUE_MESSAGE_MD5);
                if (LItemNode <> nil) and LItemNode.IsTextElement then
                begin
//                  LProp.Key := 'MD5OfBody';
//                  LProp.Value := LItemNode.Text;
                  LItem.Properties := LItem.Properties + [TPair<string, string>.Create('MD5OfBody', LItemNode.Text)]; //LProp
                end;

                //populate the other attributes
                LAttrNode := GetFirstMatchingChildNode(LMessageNode, NODE_ATTRIBUTES);

                while LAttrNode <> nil do
                begin
                  if LAttrNode.NodeName.Equals(NODE_ATTRIBUTES) then
                    LItem.Properties := LItem.Properties +
                      [TPair<string, string>.Create(
                        LAttrNode.ChildNodes.FindNode('Name').Text,
                        LAttrNode.ChildNodes.FindNode('Value').Text)
                      ];
                  LAttrNode := LAttrNode.NextSibling;
                end;
                Result := Result + [LItem];
              end;
            end;
          end;
          LMessageNode := LMessageNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonQueueService.PeekMessages(const QueueURL: string; NumOfMessages: Integer;
                                          ResponseInfo: TCloudResponseInfo): TList<TCloudQueueMessage>;
var
  LMessages: TArray<TCloudQueueMessageItem>;
  LMessage: TCloudQueueMessageItem;
  LResponseXML: string;
begin
  Result := nil;
  //Set VisibilityTimeout to 0, so that messages are instantly visible to other callers.
  LMessages := ReceiveMessage(QueueURL, NumOfMessages, 0, LResponseXML, ResponseInfo);

  if Length(LMessages) > 0 then
  begin
    Result := TList<TCloudQueueMessage>.Create;
    for LMessage in LMessages do
      Result.Add(TCloudQueueMessage.CreateFromRecord(LMessage));
  end;
end;

function TAmazonQueueService.ChangeMessageVisibility(const QueueURL, PopReceipt: string;
  const VisibilityTimeout: Integer; ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('ChangeMessageVisibility');

  QueryParams.Values['ReceiptHandle'] := PopReceipt;
  QueryParams.Values['VisibilityTimeout'] := IntToStr(VisibilityTimeout);

  Response := nil;
  try
    Response := IssueRequest(QueueURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonQueueService.ChangeMessageVisibilityBatch(const AQueueURL: string;
  AMessageInfoList: TArray<TPair<string, integer>>; const AResponseInfo: TCloudResponseInfo): Boolean;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LAmazonQueueInfo: TPair<string, Integer>;
  I: Integer;
begin
  LQueryParams := BuildQueryParameters('ChangeMessageVisibilityBatch');

  I := 1;
  for LAmazonQueueInfo in AMessageInfoList do
  begin
    LQueryParams.Values['ChangeMessageVisibilityBatchRequestEntry.' + I.ToString + '.Id'] := 'change_visibility_msg_' + i.ToString;
    LQueryParams.Values['ChangeMessageVisibilityBatchRequestEntry.' + I.ToString + '.ReceiptHandle'] := LAmazonQueueInfo.Key;
    LQueryParams.Values['ChangeMessageVisibilityBatchRequestEntry.' + I.ToString + '.VisibilityTimeout'] := LAmazonQueueInfo.Value.ToString;
    inc(I);
  end;

  LResponse := nil;
  try
    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

function TAmazonQueueService.ListDeadLetterSourceQueues(const AQueueURL: string; const AResponseInfo: TCloudResponseInfo): TArray<string>;
var
  LResponse: TCloudHTTP;
  LQueryParams: TStringList;
  LXML: string;
  LXMLDoc: IXMLDocument;
  LDeadLetterQueuesNode, LQueuesNode, LQueueURL: IXMLNode;
  LResult: Boolean;
begin
  LQueryParams := BuildQueryParameters('ListDeadLetterSourceQueues');

  LResponse := nil;
  try
    LResponse := IssueRequest(AQueueURL, LQueryParams, AResponseInfo, LXML);
    LResult := (LResponse <> nil) and (LResponse.ResponseCode = 200);

    if LResult and not LXML.IsEmpty then
    begin
      //Parse XML and get QueueURL value
      LXMLDoc := TXMLDocument.Create(nil);
      LXMLDoc.LoadFromXML(LXML);

      LDeadLetterQueuesNode := LXMLDoc.DocumentElement;
      LQueuesNode := LDeadLetterQueuesNode.ChildNodes.FindNode(NODE_DEAD_LETTER_SOURCE_QUEUES);
      if (LQueuesNode <> nil) and LQueuesNode.HasChildNodes then
      begin
        LQueueURL := LQueuesNode.ChildNodes.FindNode(NODE_QUEUE);
        while LQueueURL <> nil do
        begin
          if (LQueueURL <> nil) and LQueueURL.IsTextElement then
            Result := Result + [LQueueURL.Text];
          LQueueURL := LQueueURL.NextSibling;
        end;
      end;
    end;
  finally
    LResponse.Free;
    LQueryParams.Free;
  end;
end;

{ TAmazonObjectResult }

class function TAmazonObjectResult.Create(const Name: string): TAmazonObjectResult;
var
  Inst: TAmazonObjectResult;
begin
  Inst.Name := Name;
  Result := Inst;
  Inst.IsLatest := True;
  Inst.IsDeleted := False;
end;

{ TAmazonBasicService }

function TAmazonBasicService.BuildQueryParameters(const Action: string): TStringList;
begin
  Result := TStringList.Create;

  Result.Values['Action'] := Action;
  Result.Values['AWSAccessKeyId'] := ConnectionInfo.AccountName;
  Result.Values['SignatureMethod'] := 'HmacSHA256';
  Result.Values['SignatureVersion'] := '2';
  Result.Values['Version'] := GetServiceVersion;
  Result.Values['Timestamp'] := CurrentTime;
end;

function TAmazonBasicService.BuildStringToSignResourcePath(const URL: string): string;
begin
  Result := TURI.Create(URL).Host + #10 + inherited BuildStringToSignResourcePath(URL);
end;

function TAmazonBasicService.CreateAuthInstance(const ConnectionInfo: TAmazonConnectionInfo): TCloudAuthentication;
begin
  Result := TAmazonAuthentication.Create(ConnectionInfo, False); //authentication isn't put in header
end;

function TAmazonBasicService.IssueRequest(URL: string; QueryParams: TStringList; ResponseInfo: TCloudResponseInfo;
                                          out ResultString: string; RequestStream: TStream): TCloudHTTP;
var
  DoAsPost: Boolean;
  ContentStream: TStream;
begin
  ContentStream := RequestStream;
  DoAsPost := RequestStream <> nil;

  try
    if DoAsPost then
      Result := IssuePostRequest(URL, nil, QueryParams, EmptyStr, ResponseInfo, ContentStream, ResultString)
    else
      Result := IssueGetRequest(URL, nil, QueryParams, EmptyStr, ResponseInfo, ResultString);
  finally
    ParseResponseError(ResponseInfo, ResultString);
  end;
end;

function TAmazonBasicService.IssueRequest(URL: string; QueryParams: TStringList; ResponseInfo: TCloudResponseInfo;
                                          RequestStream: TStream): TCloudHTTP;
var
  OutStr: string;
begin
  Result := IssueRequest(URL, QueryParams, ResponseInfo, OutStr, RequestStream);
end;

procedure TAmazonBasicService.ParseResponseError(const ResponseInfo: TCloudResponseInfo; const ResultString: string);
var
  xmlDoc: IXMLDocument;
  Aux, ErrorNode, MessageNode: IXMLNode;
  ErrorCode, ErrorMsg: string;
  IsErrors: Boolean;
begin
  //If the ResponseInfo instance exists (to be populated) and the passed in string is Error XML, then
  //continue, otherwise exit doing nothing.
  if (ResponseInfo = nil) or (ResultString = EmptyStr) then
    Exit;

  xmlDoc := TXMLDocument.Create(nil);
  xmlDoc.LoadFromXML(ResultString);

  IsErrors := AnsiPos(Format('<%s>', [NODE_ERRORS]), ResultString) > 0;

  //Parse the error and update the ResponseInfo StatusMessage
  if IsErrors or (AnsiPos('<ErrorResponse', ResultString) > 0) then
  begin
    //Amazon has different formats for returning errors as XML
    if IsErrors then
    begin
      ErrorNode := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_ERRORS);
      ErrorNode := ErrorNode.ChildNodes.FindNode(NODE_ERROR);
    end
    else
      ErrorNode := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_ERROR);

    if (ErrorNode <> nil) and (ErrorNode.HasChildNodes) then
    begin
      MessageNode := ErrorNode.ChildNodes.FindNode(NODE_ERROR_MESSAGE);

      if (MessageNode <> nil) then
        ErrorMsg := MessageNode.Text;

      if ErrorMsg <> EmptyStr then
      begin
        //Populate the error code
        Aux := ErrorNode.ChildNodes.FindNode(NODE_ERROR_CODE);
        if (Aux <> nil) then
          ErrorCode := Aux.Text;
        ResponseInfo.StatusMessage := Format('%s - %s (%s)', [ResponseInfo.StatusMessage, ErrorMsg, ErrorCode]);
      end;
    end;

    //populate the RequestId, which is structured differently than if this is not an error response
    Aux := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_REQUEST_ID);
    if (Aux <> nil) and (Aux.IsTextElement) then
      ResponseInfo.Headers.Values[NODE_REQUEST_ID] := Aux.Text;
  end
  //Otherwise, it isn't an error, but try to pase the RequestId anyway.
  else
  begin
    Aux := xmlDoc.DocumentElement.ChildNodes.FindNode(NODE_RESPONSE_METADATA);
    if Aux <> nil then
    begin
      Aux := Aux.ChildNodes.FindNode(NODE_REQUEST_ID);
      if Aux <> nil then
        ResponseInfo.Headers.Values[NODE_REQUEST_ID] := Aux.Text;
    end;
  end;
end;

procedure TAmazonBasicService.PrepareRequestSignature(const HTTPVerb: string;
                                                      const Headers, QueryParameters: TStringList;
                                                      const StringToSign: string;
                                                      var URL: string; Request: TCloudHTTP;
                                                      var Content: TStream);
var
  AuthorizationString, QueryString: string;
begin
  if FAuthenticator <> nil then
  begin
    AuthorizationString := FAuthenticator.BuildAuthorizationString(StringToSign);

    QueryParameters.Values['Signature'] := AuthorizationString;

    //If this is a GET request, or the content stream is currently in use by actual request data,
    // then the parameters are in the URL, so add Signature to the URL
    if (HTTPVerb = 'GET') or (Content <> nil) then
      URL := BuildQueryParameterString(URL, QueryParameters, False, True)
    //Otherwise, this is a POST and the parameters should all be put in the content of the request
    else
    begin
      Request.Client.ContentType := 'application/x-www-form-urlencoded; charset=utf-8';

      //Skip the first character, because it is the query prefix character (?) which isn't used
      //when the query string is in the body of the request.
      QueryString := BuildQueryParameterString(EmptyStr, QueryParameters, False, True).Substring(1);
      Content := TStringStream.Create(QueryString);
    end;
  end;
end;

procedure TAmazonBasicService.SortQueryParameters(const QueryParameters: TStringList; ForURL: Boolean);
begin
  if (QueryParameters <> nil) and (not ForURL) then
  begin
    QueryParameters.CustomSort(CaseSensitiveNameCompare);
  end;
end;

{ TAmazonTableService }

function TAmazonTableService.GetServiceHost: string;
begin
  Result := GetConnectionInfo.TableEndpoint;
end;

function TAmazonTableService.GetServiceVersion: string;
begin
  Result := '2009-04-15';
end;

function TAmazonTableService.GetTableMetadataXML(const TableName: string;
                                                 ResponseInfo: TCloudResponseInfo): string;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('DomainMetadata');

  QueryParams.Values['DomainName'] := TableName;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.InsertRow(const TableName, RowId: string; Row: TCloudTableRow;
                                       Conditionals: TList<TAmazonRowConditional>; ReplaceAll: Boolean;
                                       ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  Item: TCloudTableColumn;
  Conditional: TAmazonRowConditional;
  Index: Integer;
begin
  QueryParams := BuildQueryParameters('PutAttributes');

  QueryParams.Values['DomainName'] := TableName;
  QueryParams.Values['ItemName'] := RowId;

  if (Row <> nil) and (Row.Columns <> nil) then
  begin
    Index := 0;
    for Item in Row.Columns do
    begin
      QueryParams.Values[Format('Attribute.%d.Name', [Index])] := Item.Name;
      QueryParams.Values[Format('Attribute.%d.Value', [Index])] := Item.Value;
      if (ReplaceAll and (not AnsiSameText(Item.DataType, TABLE_ROW_DATATYPE_DO_NOT_REPLACE))) or
         ((not ReplaceAll) and AnsiSameText(Item.DataType, TABLE_ROW_DATATYPE_REPLACE)) then
        QueryParams.Values[Format('Attribute.%d.Replace', [Index])] := 'true';
      Inc(Index);
    end;
  end;

  if Conditionals <> nil then
  begin
    Index := 0;
    for Conditional In Conditionals do
    begin
      QueryParams.Values[Format('Expected.%d.Name', [Index])] := Conditional.ColumnName;
      if not Conditional.ColumnExists then
        QueryParams.Values[Format('Expected.%d.Exists', [Index])] := BoolToStr(False)
      else
        QueryParams.Values[Format('Expected.%d.Value', [Index])] := Conditional.ColumnValue;
      Inc(Index);
    end;
  end;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.InsertRows(const TableName: string; Rows: TList<TAmazonBatchRow>;
                                        ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  Item: TCloudTableColumn;
  BatchRow: TAmazonBatchRow;
  Row: TCloudTableRow;
  ItemIndex, AttributeIndex: Integer;
begin
  QueryParams := BuildQueryParameters('BatchPutAttributes');

  QueryParams.Values['DomainName'] := TableName;

  if Rows <> nil then
  begin
    ItemIndex := 0;

    for BatchRow in Rows do
    begin
      AttributeIndex := 0;

      QueryParams.Values[Format('Item.%d.ItemName', [ItemIndex])] := BatchRow.RowId;
      Row := BatchRow.Row;

      if (Row <> nil) and (Row.Columns <> nil) then
      begin
        for Item in Row.Columns do
        begin
          QueryParams.Values[Format('Item.%d.Attribute.%d.Name', [ItemIndex, AttributeIndex])] := Item.Name;
          QueryParams.Values[Format('Item.%d.Attribute.%d.Value', [ItemIndex, AttributeIndex])] := Item.Value;
          if (BatchRow.ReplaceAll and (not AnsiSameText(Item.DataType, TABLE_ROW_DATATYPE_DO_NOT_REPLACE))) or
             ((not BatchRow.ReplaceAll) and AnsiSameText(Item.DataType, TABLE_ROW_DATATYPE_REPLACE)) then
            QueryParams.Values[Format('Item.%d.Attribute.%d.Replace', [ItemIndex, AttributeIndex])] := 'true';
          Inc(AttributeIndex);
        end;
      end;
      Inc(ItemIndex);
    end;
  end;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.GetTableMetadata(const TableName: string;
                                              ResponseInfo: TCloudResponseInfo): TStrings;
var
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, ItemNode: IXMLNode;
begin
  xml := GetTableMetadataXML(TableName, ResponseInfo);

  Result := nil;

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(Result);
    end;

    Result := TStringList.Create;

    ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode('DomainMetadataResult');
    if (ResultNode <> nil) and ResultNode.HasChildNodes then
    begin
      ItemNode := ResultNode.ChildNodes.First;

      while (ItemNode <> nil) do
      begin
        try
          if ItemNode.IsTextElement then
            Result.Values[ItemNode.NodeName] := ItemNode.Text;
        finally
          ItemNode := ItemNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonTableService.CreateTable(const TableName: string; ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('CreateDomain');

  QueryParams.Values['DomainName'] := TableName;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.DeleteTable(const TableName: string; ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('DeleteDomain');

  QueryParams.Values['DomainName'] := TableName;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.QueryTablesXML(const ContinuationToken: string; const MaxNumberOfTables: Integer;
                                            ResponseInfo: TCloudResponseInfo): string;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
begin
  QueryParams := BuildQueryParameters('ListDomains');

  if MaxNumberOfTables > 0 then
    QueryParams.Values['MaxNumberOfDomains'] := IntToStr(MaxNumberOfTables);

  if ContinuationToken <> EmptyStr then
    QueryParams.Values['NextToken'] := ContinuationToken;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.QueryTables(const ContinuationToken: string; const MaxNumberOfTables: Integer;
                                         ResponseInfo: TCloudResponseInfo): TStrings;
var
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, TableNode: IXMLNode;
begin
  xml := QueryTablesXML(ContinuationToken, MaxNumberOfTables, ResponseInfo);

  Result := nil;

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(Result);
    end;

    Result := TStringList.Create;

    ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode('ListDomainsResult');
    if (ResultNode <> nil) and ResultNode.HasChildNodes then
    begin
      TableNode := ResultNode.ChildNodes.First;

      while (TableNode <> nil) do
      begin
        try
          if AnsiSameText(TableNode.NodeName, 'DomainName') then
          begin
            if TableNode.IsTextElement then
               Result.Add(TableNode.Text);
          end
          else if (ResponseInfo <> nil) and AnsiSameText(TableNode.NodeName, 'NextToken') then
            ResponseInfo.Headers.Values['NextToken'] := TableNode.Text;
        finally
          TableNode := TableNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonTableService.SelectRowsXML(const SelectStatement: string; ResponseInfo: TCloudResponseInfo;
                                           const NextToken: string): string;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  xmlDoc: IXMLDocument;
  ResultNode, NextTokenNode: IXMLNode;
begin
  QueryParams := BuildQueryParameters('Select');

  if GetConnectionInfo.ConsistentRead then
    QueryParams.Values['ConsistentRead'] := 'true';

  QueryParams.Values['SelectExpression'] := SelectStatement;

  //Specify the NextToken, if one exists. This will start reading from the previous value
  //of MaxNumberOfItems, plus one. (or if 0, then from the server default.)
  if NextToken <> EmptyStr then
    QueryParams.Values['NextToken'] := NextToken;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo, Result);

    //populate the NextToken header value in the ResponseInfo, from the XML
    if (ResponseInfo <> nil) and (ResponseInfo.StatusCode = 200) and (Result <> EmptyStr) then
    begin
      xmlDoc := TXMLDocument.Create(nil);

      try
        xmlDoc.LoadFromXML(Result);
      except
        Exit(Result);
      end;

      ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode('SelectResult');
      if (ResultNode <> nil) and (ResultNode.HasChildNodes) then
      begin
        NextTokenNode := GetFirstMatchingChildNode(ResultNode, 'NextToken');
        if (NextTokenNode <> nil) and NextTokenNode.IsTextElement then
          ResponseInfo.Headers.Values['NextToken'] := NextTokenNode.Text;
      end;
    end;
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.GetRowsXML(const TableName: string; MaxNumberOfItems: Integer;
                                        ItemIdOnly: Boolean; ResponseInfo: TCloudResponseInfo;
                                        const NextToken: string): string;
var
  SelectStatement, ToSelect, LimitBy: string;
begin
  //Get all columns or just the item names
  if ItemIdOnly then
    ToSelect := 'itemName()'
  else
    ToSelect := '*';

  //optionally limit the number of returned rows
  if MaxNumberOfItems > 0 then
    LimitBy := Format(' limit %d', [MaxNumberOfItems]);

  //Set the select expression to use, specifying the columns to get and how many rows to return
  SelectStatement := Format('select %s from %s%s', [ToSelect, TableName, LimitBy]);

  Result := SelectRowsXML(SelectStatement, ResponseInfo, NextToken);
end;

function TAmazonTableService.GetRowIDs(const TableName: string; MaxNumberOfItems: Integer;
                                       ResponseInfo: TCloudResponseInfo; const NextToken: string): TStrings;
var
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, ItemNode, NameNode: IXMLNode;
begin
  Result := nil;
  xml := GetRowsXML(TableName, MaxNumberOfItems, True, ResponseInfo, NextToken);
  if (xml <> EmptyStr) then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(Result);
    end;

    ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode('SelectResult');
    if (ResultNode <> nil) and ResultNode.HasChildNodes then
    begin
      Result := TStringList.Create;

      ItemNode := ResultNode.ChildNodes.First;

      while (ItemNode <> nil) do
      begin
        try
          if AnsiSameText(ItemNode.NodeName, 'Item') then
          begin
            NameNode := ItemNode.ChildNodes.FindNode('Name');
            if (NameNode <> nil) and NameNode.IsTextElement then
              Result.Add(NameNode.Text);
          end;
        finally
          ItemNode := ItemNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonTableService.GetRows(const TableName: string; MaxNumberOfItems: Integer;
                                     ResponseInfo: TCloudResponseInfo;
                                     const NextToken: string): TList<TCloudTableRow>;
var
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, ItemNode, ColumnNode, NameNode, ValueNode: IXMLNode;
  Row: TCloudTableRow;
begin
  Result := nil;
  xml := GetRowsXML(TableName, MaxNumberOfItems, False, ResponseInfo, NextToken);

  if (xml <> EmptyStr) then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(Result);
    end;

    ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode('SelectResult');
    if (ResultNode <> nil) and ResultNode.HasChildNodes then
    begin
      Result := TList<TCloudTableRow>.Create;

      ItemNode := ResultNode.ChildNodes.First;

      while (ItemNode <> nil) do
      begin
        try
          if AnsiSameText(ItemNode.NodeName, 'Item') then
          begin
            ColumnNode := ItemNode.ChildNodes.FindNode('Name');
            if (ColumnNode <> nil) and ColumnNode.IsTextElement then
            begin
              //Amazon doesn't support column datatype info
              Row := TCloudTableRow.Create(False);
              Result.Add(Row);

              Row.SetColumn('itemName()', ColumnNode.Text);

              ColumnNode := ItemNode.ChildNodes.First;
              while (ColumnNode <> nil) do
              begin
                try
                  if AnsiSameText(ColumnNode.NodeName, 'Attribute') and ColumnNode.HasChildNodes then
                  begin
                    NameNode := ColumnNode.ChildNodes.FindNode('Name');
                    ValueNode := ColumnNode.ChildNodes.FindNode('Value');

                    if (NameNode <> nil) and (ValueNode <> nil) and
                        NameNode.IsTextElement and ValueNode.IsTextElement then
                      Row.SetColumn(NameNode.Text, ValueNode.Text, EmptyStr, False); //don't replace, may have multiple values
                  end;
                finally
                  ColumnNode := ColumnNode.NextSibling;
                end;
              end;
            end;
          end;
        finally
          ItemNode := ItemNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonTableService.DeleteColumns(const TableName, RowId: string; const Columns: TStrings;
                                           Conditionals: TList<TAmazonRowConditional>;
                                           ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  Conditional: TAmazonRowConditional;
  Index, I, Count: Integer;
  Val, ColName, ColVal: string;
begin
  QueryParams := BuildQueryParameters('DeleteAttributes');

  QueryParams.Values['DomainName'] := TableName;
  QueryParams.Values['ItemName'] := RowId;

  if Columns <> nil then
  begin
    Index := 0;
    Count := Columns.Count;

    //iterate over each specified column
    //each item in the list can be either just a column name,
    //or a delimited pair of the column name and the column value
    for I := 0 to Count - 1 do
    begin
      ColName := EmptyStr;
      ColVal := EmptyStr;

      Val := Columns[I];
      if AnsiPos(Columns.Delimiter, Val) > 0 then
      begin
        ColName := Columns.Names[I];
        ColVal := Columns.ValueFromIndex[I];
      end
      else
        ColName := Val;

      //don't allow a call to delete the itemName() column.
      if not AnsiSameText('itemName()', ColName) then
      begin
        QueryParams.Values[Format('Attribute.%d.Name', [Index])] := ColName;
        if ColVal <> EmptyStr then
          QueryParams.Values[Format('Attribute.%d.Value', [Index])] := ColVal;
      end;
      Inc(Index);
    end;
  end;

  if Conditionals <> nil then
  begin
    Index := 0;
    for Conditional In Conditionals do
    begin
      QueryParams.Values[Format('Expected.%d.Name', [Index])] := Conditional.ColumnName;
      if not Conditional.ColumnExists then
        QueryParams.Values[Format('Expected.%d.Exists', [Index])] := BoolToStr(False)
      else
        QueryParams.Values[Format('Expected.%d.Value', [Index])] := Conditional.ColumnValue;
      Inc(Index);
    end;
  end;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonTableService.DeleteColumns(const TableName, RowId: string; const Columns: TStrings;
                                           ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := DeleteColumns(TableName, RowId, Columns, nil, ResponseInfo);
end;

function TAmazonTableService.DeleteRow(const TableName, RowId: string;
                                       Conditionals: TList<TAmazonRowConditional>;
                                       ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := DeleteColumns(TableName, RowId, nil, Conditionals, ResponseInfo);
end;

function TAmazonTableService.DeleteRow(const TableName, RowId: string;
                                       ResponseInfo: TCloudResponseInfo): Boolean;
begin
  Result := DeleteColumns(TableName, RowId, nil, nil, ResponseInfo);
end;

function TAmazonTableService.BatchDeleteColumns(const TableName: string; BatchColumns: TList<TCloudTableRow>;
                                                ResponseInfo: TCloudResponseInfo): Boolean;
var
  Response: TCloudHTTP;
  QueryParams: TStringList;
  ItemIndex, ColIndex, I, Count: Integer;
  ColName, ColVal: string;
  Row: TCloudTableRow;
begin
  QueryParams := BuildQueryParameters('BatchDeleteAttributes');

  QueryParams.Values['DomainName'] := TableName;

  if BatchColumns <> nil then
  begin
    ItemIndex := 0;
    for Row In BatchColumns do
    begin
      ColIndex := 0;
      Count := Row.Columns.Count;

      //iterate over each specified column and add query parameters for deleting it
      for I := 0 to Count - 1 do
      begin
        ColName := Row.Columns[I].Name;
        ColVal := Row.Columns[I].Value;

        if AnsiSameText('itemName()', ColName) then
        begin
           QueryParams.Values[Format('Item.%d.ItemName', [ItemIndex])] := ColVal;
        end
        else
        begin
          QueryParams.Values[Format('Item.%d.Attribute.%d.Name', [ItemIndex, ColIndex])] := ColName;
          if ColVal <> EmptyStr then
            QueryParams.Values[Format('Item.%d.Attribute.%d.Value', [ItemIndex, ColIndex])] := ColVal;
        end;

        Inc(ColIndex);
      end;
      Inc(ItemIndex);
    end;
  end;

  Response := nil;
  try
    Response := IssueRequest(GetConnectionInfo.TableURL, QueryParams, ResponseInfo);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
  end;
end;

{ TAmazonBucketResult }

constructor TAmazonBucketResult.Create(const AName: string);
begin
  FName := AName;
  FObjects := TList<TAmazonObjectResult>.Create;
  FPrefixes := TStringList.Create;
end;

destructor TAmazonBucketResult.Destroy;
begin
  FreeAndNil(FObjects);
  FreeAndNil(FPrefixes);
  inherited;
end;

{ TAmazonGrant }

class function TAmazonGrant.Create(Permission: TAmazonGrantPermission): TAmazonGrant;
begin
  Result.Permission := Permission;
end;

class function TAmazonGrant.Create(const Permission: string): TAmazonGrant;
begin
  Result.Permission := GetPermission(Permission);
end;

class function TAmazonGrant.GetPermission(const PermissionString: string): TAmazonGrantPermission;
begin
  if PermissionString.ToUpper.Equals('FULL_CONTROL') then
    Exit(amgpFullControl);
  if PermissionString.ToUpper.Equals('WRITE') then
    Exit(amgpWrite);
  if PermissionString.ToUpper.Equals('WRITE_ACP') then
    Exit(amgpWriteACP);
  if PermissionString.ToUpper.Equals('READ') then
    Exit(amgpRead);
  if PermissionString.ToUpper.Equals('READ_ACP') then
    Exit(amgpReadACP);

  Result := amgpUnknown;
end;

function TAmazonGrant.GranteeType: TAmazonGranteeType;
begin
  Result := agtUnknown;

  if GranteeURI <> EmptyStr then
    Exit(agtGroup);

  if GranteeEmailAddress <> EmptyStr then
    Exit(agtCustomerByEmail);

  if GranteeID <> EmptyStr then
    Exit(agtCanonicalUser);
end;

function TAmazonGrant.GranteeTypeString: string;
begin
  Result := AmazonGranteeTypeStr[GranteeType];
end;

function TAmazonGrant.PermissionString: string;
begin
  Result := AmazonGrantPermissionStr[Permission];
end;

function TAmazonGrant.IsAllAuthenticatedUsers: Boolean;
begin
  Result := AnsiSameText(GranteeURI, ALL_AUTHENTICATED_USERS_GROUP);
end;

function TAmazonGrant.IsAllUsers: Boolean;
begin
  Result := AnsiSameText(GranteeURI, ALL_USERS_GROUP);
end;

function TAmazonGrant.IsLogDelivery: Boolean;
begin
  Result := AnsiSameText(GranteeURI, LOG_DELIVERY_GROUP);
end;

{ TAmazonBucketLoggingInfo }

constructor TAmazonBucketLoggingInfo.Create(const TargetBucket, TargetPrefix: string);
begin
  FTargetBucket := TargetBucket;
  FTargetPrefix := TargetPrefix;
  FGrants := TList<TAmazonGrant>.Create;
  FLoggingEnabled := True;
end;

constructor TAmazonBucketLoggingInfo.Create;
begin
  FLoggingEnabled := False;
end;

destructor TAmazonBucketLoggingInfo.Destroy;
begin
  FreeAndNil(FGrants);
  inherited;
end;

class function TAmazonBucketLoggingInfo.GetDisableXML: string;
begin
  Result := LogXMLPrefix + LogXMLSuffix;
end;

function TAmazonBucketLoggingInfo.AsXML: string;
var
  sb: TStringBuilder;
  Grant: TAmazonGrant;
  TypeStr, GranteeStr: string;
begin
{$IF RTLVERSION > 32}
  sb := TStringBuilder.Create(256);
{$ELSE}
  sb := TStringBuilder.Create;
{$ENDIF}
  try
    sb.Append(LogXMLPrefix);

    //only add information under the root logging node if logging is enabled.
    if FLoggingEnabled then
    begin
      sb.Append('<LoggingEnabled><TargetBucket>');
      sb.Append(FTargetBucket);
      sb.Append('</TargetBucket><TargetPrefix>');
      sb.Append(FTargetPrefix);
      sb.Append('</TargetPrefix>');

      if FGrants.Count > 0 then
      begin
        sb.Append('<TargetGrants>');

        for Grant In FGrants do
        begin
          if Grant.GranteeEmailAddress <> EmptyStr then
          begin
            TypeStr := 'AmazonCustomerByEmail';
            GranteeStr := '<EmailAddress>' + Grant.GranteeEmailAddress + '</EmailAddress>';
          end
          else if Grant.GranteeURI <> EmptyStr then
          begin
            TypeStr := 'Group';
            GranteeStr := '<URI>' + Grant.GranteeURI + '</URI>';
          end
          else
          begin
            TypeStr := 'CanonicalUser';
            GranteeStr := '<ID>' + Grant.GranteeID + '</ID>';
            if Grant.GranteeDisplayName <> EmptyStr then
              GranteeStr := GranteeStr + '<DisplayName>' + Grant.GranteeDisplayName + '</DisplayName>';
          end;

          sb.Append('<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="');
          sb.Append(TypeStr);
          sb.Append('">');
          sb.Append(GranteeStr);
          sb.Append('</Grantee><Permission>');
          sb.Append(Grant.PermissionString);
          sb.Append('</Permission></Grant>');
        end;

        sb.Append('</TargetGrants>');
      end;

      sb.Append('</LoggingEnabled>');
    end;

    sb.Append(LogXMLSuffix);

  {$IF RTLVERSION > 32}
    Result := sb.ToString(True);
  {$ELSE}
    Result := sb.ToString;
  {$ENDIF}
  finally
    sb.Free;
  end;
end;

{ TAmazonNotificationTopic }

class function TAmazonNotificationEvent.Create(const Topic, Event: string): TAmazonNotificationEvent;
begin
  Result.Topic := Topic;
  Result.Event := Event;
end;

{ TAmazonMultipartUploadItem }

constructor TAmazonMultipartUploadItem.Create(const AKey: string);
begin
  Key := AKey;
end;

{ TAmazonMultipartUploadsResult }

constructor TAmazonMultipartUploadsResult.Create(const BucketName: string);
begin
  FBucket := BucketName;
  FUploadItems := TList<TAmazonMultipartUploadItem>.Create;
end;

destructor TAmazonMultipartUploadsResult.Destroy;
begin
  FreeAndNil(FUploadItems);
  inherited;
end;

{ TAmazonAccessControlPolicy }

constructor TAmazonAccessControlPolicy.Create(const OwnerId, OwnerDisplayName: string;
                                              Grants: TList<TAmazonGrant>);
begin
  FOwnerID := OwnerId;
  FOwnerDisplayName := OwnerDisplayName;
  if Grants <> nil then
    FGrants := Grants
  else
    FGrants := TList<TAmazonGrant>.Create;
end;

function TAmazonAccessControlPolicy.AsXML: string;
var
  sb: TStringBuilder;
  Grant: TAmazonGrant;
  GranteeType: TAmazonGranteeType;
begin
{$IF RTLVERSION > 32}
  sb := TStringBuilder.Create(256);
{$ELSE}
  sb := TStringBuilder.Create;
{$ENDIF}
  try
    sb.Append('<AccessControlPolicy><Owner><ID>');
    sb.Append(OwnerId);
    sb.Append('</ID><DisplayName>');
    sb.Append(OwnerDisplayName);
    sb.Append('</DisplayName></Owner><AccessControlList>');

    for Grant In Grants do
    begin
      GranteeType := Grant.GranteeType;
      if GranteeType <> agtUnknown then
      begin
        sb.Append('<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="');
        sb.Append(Grant.GranteeTypeString).Append('">');

        case GranteeType of
          agtCanonicalUser:
          begin
            sb.Append('<ID>').Append(Grant.GranteeID).Append('</ID><DisplayName>');
            sb.Append(Grant.GranteeDisplayName).Append('</DisplayName>');
          end;
          agtCustomerByEmail:
            sb.Append('<EmailAddress>').Append(Grant.GranteeEmailAddress).Append('</EmailAddress>');
          agtGroup:
            sb.Append('<URI>').Append(Grant.GranteeURI).Append('</URI>');
        end;

        sb.Append('</Grantee><Permission>').Append(Grant.PermissionString).Append('</Permission></Grant>');
      end;
    end;

    sb.Append('</AccessControlList></AccessControlPolicy>');
  {$IF RTLVERSION > 32}
    Result := sb.ToString(True);
  {$ELSE}
    Result := sb.ToString;
  {$ENDIF}
  finally
    sb.Free;
  end;
end;

destructor TAmazonAccessControlPolicy.Destroy;
begin
  FreeAndNil(FGrants);
  inherited;
end;

{ TAmazonActionConditional }

class function TAmazonActionConditional.Create: TAmazonActionConditional;
var
  Inst: TAmazonActionConditional;
begin
  Exit(Inst);
end;

procedure TAmazonActionConditional.PopulateHeaders(Headers: TStrings; ForCopy: Boolean);
begin
  if Headers <> nil then
  begin
    if not ForCopy then
    begin
      Headers.Values['If-Modified-Since'] := IfModifiedSince;
      Headers.Values['If-Unmodified-Since'] := IfUnmodifiedSince;
      Headers.Values['If-Match'] := IfMatch;
      Headers.Values['If-None-Match'] := IfNoneMatch;
    end
    else
    begin
      Headers.Values['x-amz-copy-source-if-modified-since'] := IfModifiedSince;
      Headers.Values['x-amz-copy-source-if-unmodified-since'] := IfUnmodifiedSince;
      Headers.Values['x-amz-copy-source-if-match'] := IfMatch;
      Headers.Values['x-amz-copy-source-if-none-match'] := IfNoneMatch;
    end;
  end;
end;

{ TAmazonGetObjectOptionals }

class function TAmazonGetObjectOptionals.Create: TAmazonGetObjectOptionals;
begin
  Result.RangeStartByte := 0;
  Result.RangeEndByte := 0;
end;

procedure TAmazonGetObjectOptionals.PopulateHeaders(Headers: TStrings);
begin
  if Headers <> nil then
  begin
    Condition.PopulateHeaders(Headers, False);

    if ResponseContentType <> EmptyStr then
      Headers.Values['response-content-type'] := ResponseContentType;

    if ResponseContentLanguage <> EmptyStr then
      Headers.Values['response-content-language'] := ResponseContentLanguage;

    if ResponseExpires <> EmptyStr then
      Headers.Values['response-expires'] := ResponseExpires;

    if ResponseCacheControl <> EmptyStr then
      Headers.Values['reponse-cache-control'] := ResponseCacheControl;

    if ResponseContentDisposition <> EmptyStr then
      Headers.Values['response-content-disposition'] := ResponseContentDisposition;

    if ResponseContentEncoding <> EmptyStr then
      Headers.Values['response-content-encoding'] := ResponseContentEncoding;

    if RangeEndByte > RangeStartByte then
      Headers.Values['Range'] := Format('bytes=%d-%d', [RangeStartByte, RangeEndByte]);
  end;
end;

{ TAmazonCopyObjectOptionals }

constructor TAmazonCopyObjectOptionals.Create;
begin
  FMetadata := TStringList.Create;
  ACL := amzbaPrivate;
  FUseReducedRedundancy := False;
  FCopyMetadata := False;
end;

destructor TAmazonCopyObjectOptionals.Destroy;
begin
  FreeAndNil(FMetadata);
  inherited;
end;

procedure TAmazonCopyObjectOptionals.PopulateHeaders(Headers: TStrings);
begin
  if Headers <> nil then
  begin
    Condition.PopulateHeaders(Headers, True);

    if FCopyMetadata then
      Headers.Values['x-amz-metadata-directive'] := 'COPY'
    else
    begin
      Headers.Values['x-amz-metadata-directive'] := 'REPLACE';
      AddS3MetadataHeaders(Headers, Metadata);
    end;

    Headers.Values['x-amz-acl'] := GetACLTypeString(FACL);

    if FUseReducedRedundancy then
      Headers.Values['x-amz-storage-class'] := CLASS_REDUCED_REDUNDANCY
    else
      Headers.Values['x-amz-storage-class'] := 'STANDARD';
  end;
end;

{ TAmazonMultipartPart }

constructor TAmazonMultipartPart.Create(APartNumber: Integer; AETag: string);
begin
  PartNumber := APartNumber;
  ETag := AETag;
  Size := 0;
end;

function TAmazonMultipartPart.AsXML: string;
begin
  Result := Format('<Part><PartNumber>%d</PartNumber><ETag>%s</ETag></Part>', [PartNumber, ETag]);
end;

{ TAmazonListPartsResult }

constructor TAmazonListPartsResult.Create(const BucketName, ObjectName, UploadId: string);
begin
  FBucket := BucketName;
  FObjectName := ObjectName;
  FUploadId := UploadId;
  FParts := TList<TAmazonMultipartPart>.Create;
end;

destructor TAmazonListPartsResult.Destroy;
begin
  FreeAndNil(FParts);
  inherited;
end;

{ TAmazonStorageService }

constructor TAmazonStorageService.Create(const ConnectionInfo: TAmazonConnectionInfo);
begin
  inherited Create(ConnectionInfo);

  FUseCanonicalizedHeaders := True;
  FUseResourcePath := True;

  //The QueryPrefix is on the same line for S3, so re-add the question mark
  FQueryStartChar := '?';
end;

procedure TAmazonStorageService.URLEncodeQueryParams(const ForURL: Boolean; var ParamName, ParamValue: string);
begin
  if ForURL then
    inherited;
end;

function TAmazonStorageService.BuildObjectURL(const BucketName, ObjectName: string;
  ARegion: TAmazonRegion): string;
begin
  Result := GetConnectionInfo.StorageURL(BucketName, ARegion) + '/' +
    TURLEncoding.URL.Encode(ObjectName, [Ord('#')], []);
end;

function TAmazonStorageService.CreateAuthInstance(const ConnectionInfo: TAmazonConnectionInfo): TCloudAuthentication;
begin
  Result := TAmazonAWS4Authentication.Create(ConnectionInfo, True); //S3 uses HMAC-SHA256
end;

function TAmazonStorageService.BuildStringToSignHeaders(Headers: TStringList): string;
var
  RequiredHeadersInstanceOwner: Boolean;
  RequiredHeaders: TStringList;
  I, ReqCount: Integer;
  Aux: string;
  lastParam, nextParam, ConHeadPrefix: string;
begin
  //AWS always has required headers
  RequiredHeaders := TStringList(GetRequiredHeaderNames(RequiredHeadersInstanceOwner));
  Assert(RequiredHeaders <> nil);
  Assert(Headers <> nil);
  //if (Headers = nil) then
   // Headers.AddStrings(RequiredHeaders);

  //AWS4 - content-type must be included in string to sign if found in headers
  if Headers.IndexOfName('content-type') > -1 then //Headers.Find('content-type',Index) then
    RequiredHeaders.Add('content-type');
  if Headers.IndexOfName('content-md5') > -1 then
    RequiredHeaders.Add('content-md5');
  RequiredHeaders.Sorted := True;
  RequiredHeaders.Duplicates := TDuplicates.dupIgnore;
  ConHeadPrefix := AnsiLowerCase(GetCanonicalizedHeaderPrefix);
  for I := 0 to Headers.Count - 1 do
  begin
    Aux := AnsiLowerCase(Headers.Names[I]);
    if AnsiStartsStr(ConHeadPrefix, Aux) then
      RequiredHeaders.Add(Aux);
  end;
  RequiredHeaders.Sorted := False;
  //custom sorting
  SortHeaders(RequiredHeaders);
  ReqCount := RequiredHeaders.Count;

   //AWS4 get value pairs (ordered + lowercase)
  if FUseCanonicalizedHeaders and (Headers <> nil) then
  begin
    for I := 0 to ReqCount - 1 do
    begin
      Aux := AnsiLowerCase(RequiredHeaders[I]);
      if Headers.IndexOfName(Aux) < 0 then
        raise Exception.Create('Missing Required Header: '+RequiredHeaders[I]);
      nextParam := Aux;
      if lastParam = EmptyStr then
      begin
        lastParam := nextParam;
        Result := Result + Format('%s:%s', [nextParam, Headers.Values[lastParam]]);
      end
      else
      begin
        lastParam := nextParam;
        Result := Result + Format(#10'%s:%s', [nextParam, Headers.Values[lastParam]]);
      end;
    end;
    if lastParam <> EmptyStr then
      Result := Result + #10'';
  end;

  // string of header names
  Result := Result + #10'';
  for I := 0 to ReqCount - 1 do
  begin
    Result := Result + Format('%s;', [RequiredHeaders[I]]);
  end;
  SetLength(Result,Length(Result)-1);

  if RequiredHeadersInstanceOwner then
    FreeAndNil(RequiredHeaders);
end;


//Expected format version 4 AWS
//<HTTPMethod>\n
//<CanonicalURI>\n
//<CanonicalQueryString>\n
//<CanonicalHeaders>\n
//<SignedHeaders>\n
//<HashedPayload>
function TAmazonStorageService.BuildStringToSign(const HTTPVerb: string; Headers, QueryParameters: TStringList;
                                         const QueryPrefix, URL: string): string;
var
  CanRequest, Scope, LdateISO, Ldate, Lregion : string;
  URLrec : TURI;
  LParams: TStringList;
  VPParam : TNameValuePair;
begin
  LParams := nil;
  try
    //Build the first part of the string to sign, including HTTPMethod
    CanRequest := BuildStringToSignPrefix(HTTPVerb);

    //find and encode the requests resource
    URLrec :=  TURI.Create(URL);

    //CanonicalURI URL encoded
    CanRequest := CanRequest + TNetEncoding.URL.EncodePath(URLrec.Path,
      [Ord('"'), Ord(''''), Ord(':'), Ord(';'), Ord('<'), Ord('='), Ord('>'),
      Ord('@'), Ord('['), Ord(']'), Ord('^'), Ord('`'), Ord('{'), Ord('}'),
      Ord('|'), Ord('/'), Ord('\'), Ord('?'), Ord('#'), Ord('&'), Ord('!'),
      Ord('$'), Ord('('), Ord(')'), Ord(',')]) + #10;

    //CanonicalQueryString encoded
    if not URLrec.Query.IsEmpty then
    begin
      if Length(URLrec.Params) = 1 then
        CanRequest := CanRequest + URLrec.Query + #10
      else
      begin
        LParams := TStringList.Create;
        for VPParam in URLrec.Params do
          LParams.Append(VPParam.Name+'='+VPParam.Value);
        CanRequest := CanRequest + BuildStringToSignResources('', LParams).Substring(1) + #10
      end;
    end
    else
      CanRequest := CanRequest + #10;

    //add sorted headers and header names in series for signedheader part
    CanRequest := CanRequest + BuildStringToSignHeaders(Headers) + #10;

    CanRequest := CanRequest + Headers.Values['x-amz-content-sha256'];
    LdateISO :=  Headers.Values['x-amz-date'];
    Ldate :=  Leftstr(LdateISO,8);
    Lregion := GetRegionFromEndpoint(Headers.Values['Host']);
    Scope :=  Ldate + '/'+Lregion+ '/s3' + '/aws4_request';

    Result := 'AWS4-HMAC-SHA256' + #10 + LdateISO + #10 + Scope + #10 + TCloudSHA256Authentication.GetHashSHA256Hex(CanRequest);
  finally
     LParams.Free;
  end;
end;

procedure TAmazonStorageService.PrepareRequestSignature(const HTTPVerb: string;
                                      const Headers, QueryParameters: TStringList;
                                      const StringToSign: string;
                                      var URL: string; Request: TCloudHTTP; var Content: TStream);

var
  AuthorizationString, SignStrHeaders, LdateISO, Lregion: string;
  RequiredHeadersInstanceOwner : Boolean;
  SignedHeaders: TStringList;
begin
  if FAuthenticator <> nil then
  begin
    SignedHeaders :=  TStringList(GetRequiredHeaderNames(RequiredHeadersInstanceOwner));
    SignedHeaders.Delimiter := ';';
    SignStrHeaders := SignedHeaders.DelimitedText;
    LdateISO :=  Leftstr(Headers.Values['x-amz-date'],8);
    Lregion := GetRegionFromEndpoint(Headers.Values['Host']);
    AuthorizationString := TAmazonAWS4Authentication(FAuthenticator).BuildAuthorizationString(StringToSign, LdateISO, Lregion, SignStrHeaders);
    Request.Client.CustomHeaders['Authorization'] :=  AuthorizationString;
    SignedHeaders.Clear;
    if RequiredHeadersInstanceOwner then
      FreeAndNil(SignedHeaders);
  end;
end;

function TAmazonStorageService.GetCanonicalizedHeaderPrefix: string;
begin
  Result := 'x-amz-';
end;

function TAmazonStorageService.GetNotificationXML(Events: TList<TAmazonNotificationEvent>): string;
var
  sb: TStringBuilder;
  Event: TAmazonNotificationEvent;
begin
  if (Events = nil) or (Events.Count = 0) then
    Exit('<NotificationConfiguration />');

{$IF RTLVERSION > 32}
  sb := TStringBuilder.Create(256);
{$ELSE}
  sb := TStringBuilder.Create;
{$ENDIF}
  try
    sb.Append('<NotificationConfiguration>');

    for Event In Events do
    begin
      sb.Append('<TopicConfiguration><Topic>');
      sb.Append(Event.Topic);
      sb.Append('</Topic><Event>');
      sb.Append(Event.Event);
      sb.Append('</Event></TopicConfiguration>');
    end;

    sb.Append('</NotificationConfiguration>');
  {$IF RTLVERSION > 32}
    Result := sb.ToString(True);
  {$ELSE}
    Result := sb.ToString;
  {$ENDIF}
  finally
    sb.Free;
  end;
end;

//note: endpoints and regions may change in the future
function TAmazonStorageService.GetRegionFromEndpoint(const Endpoint: string): string;
var
  LStartIdx: Integer;
begin
  if Endpoint.EndsWith('s3.amazonaws.com') or
     Endpoint.EndsWith('s3-external-1.amazonaws.com') then
    Exit('us-east-1')
  else if Endpoint.EndsWith('.amazonaws.com') then
  begin
    if EndPoint.StartsWith('s3.') or EndPoint.StartsWith('s3-') then
      LStartIdx := 3
    else
    begin
      LStartIdx := Pos('s3.', EndPoint);
      if LStartIdx = 0 then
        LStartIdx := Pos('s3-', EndPoint);
      Inc(LStartIdx, 2);
    end;
    Exit(EndPoint.Substring(LStartIdx, EndPoint.Length - LStartIdx - '.amazonaws.com'.Length))
  end
  else
    Exit('us-east-1');
end;

class function TAmazonStorageService.GetRegionFromString(const Region: string): TAmazonRegion;
begin
  Result := TAmazonConnectionInfo.GetRegionFromString(Region);
end;

class function TAmazonStorageService.GetRegionString(Region: TAmazonRegion): string;
begin
  Result := TAmazonConnectionInfo.GetRegionString(Region);
end;

//http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
//note: endpoints and regions may change in the future
function TAmazonStorageService.GetEndpointFromRegion(ARegion: TAmazonRegion): string;
begin
  Result := GetConnectionInfo.StorageVirtualHost('', ARegion);
end;

function TAmazonStorageService.GetRequiredHeaderNames(out InstanceOwner: Boolean): TStrings;
begin
  InstanceOwner := False;
  if (FRequiredHeaderNames = nil) or (FRequiredHeaderNames.Count = 0) then
  begin
    FRequiredHeaderNames.Free;
    FRequiredHeaderNames := TStringList.Create;
    FRequiredHeaderNames.Add('host');
    FRequiredHeaderNames.Add('x-amz-content-sha256');
    FRequiredHeaderNames.Add('x-amz-date');
  end;
  Result := FRequiredHeaderNames;
end;

procedure TAmazonStorageService.AddAndValidateHeaders(const defaultHeaders, customHeaders: TStrings);
var
  IsInstanceOwner: Boolean;
  RequiredHeaders: TStrings;
  I: Integer;
begin
  RequiredHeaders :=  GetRequiredHeaderNames(IsInstanceOwner);
  for I := 0 to customHeaders.Count - 1 do
  begin
    if not (RequiredHeaders.IndexOfName(customHeaders.Names[I]) > -1) then
       defaultHeaders.Append(customHeaders[I]);
  end;
  if IsInstanceOwner then
    FreeAndNil(RequiredHeaders);
end;

function TAmazonStorageService.InitHeaders(const BucketName: string; BucketRegion: TAmazonRegion): TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := false;
  Result.Duplicates := TDuplicates.dupIgnore;
  Result.Values['host'] := GetConnectionInfo.StorageVirtualHost(BucketName, BucketRegion);
  Result.Values['x-amz-content-sha256'] := 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'; //empty string
  Result.Values['x-amz-date'] := ISODateTime_noSeparators;
end;

procedure TAmazonStorageService.PopulateGrants(GrantsNode: IXMLNode; Grants: TList<TAmazonGrant>);
var
  GrantNode, GranteeNode, Aux: IXMLNode;
  PermissionStr, GranteeID, GranteeDisplayName: string;
  Grant: TAmazonGrant;
begin
  GrantNode := GrantsNode.ChildNodes.First;

  while GrantNode <> nil do
  begin
    GranteeDisplayName := EmptyStr;
    GranteeNode := GrantNode.ChildNodes.FindNode('Grantee');

    Aux := GrantNode.ChildNodes.FindNode('Permission');
    if (Aux <> nil) and Aux.IsTextElement then
    begin
      PermissionStr := Aux.Text;

      if (GranteeNode <> nil) and GranteeNode.HasChildNodes then
      begin
        Aux := GranteeNode.ChildNodes.FindNode('URI');
        if (Aux <> nil) and Aux.IsTextElement then
        begin
          Grant := TAmazonGrant.Create(PermissionStr);
          Grant.GranteeURI := Aux.Text;
          Grants.Add(Grant);
        end
        else
        begin
          Aux := GranteeNode.ChildNodes.FindNode('EmailAddress');
          if (Aux <> nil) and Aux.IsTextElement then
          begin
            Grant := TAmazonGrant.Create(PermissionStr);
            Grant.GranteeEmailAddress := Aux.Text;
            Grants.Add(Grant);
          end
          else
          begin
            Aux := GranteeNode.ChildNodes.FindNode('ID');
            if (Aux <> nil) and Aux.IsTextElement then
            begin
              GranteeID := Aux.Text;
              Aux := GranteeNode.ChildNodes.FindNode('DisplayName');
              if (Aux <> nil) and Aux.IsTextElement then
                GranteeDisplayName := Aux.Text;

              Grant := TAmazonGrant.Create(PermissionStr);
              Grant.GranteeID := GranteeID;
              Grant.GranteeDisplayName := GranteeDisplayName;
              Grants.Add(Grant);
            end;
          end;
        end;
      end;
    end;
    GrantNode := GrantNode.NextSibling;
  end;
end;

function TAmazonStorageService.PopulateResultItem(ObjectNode: IXMLNode;
                                                  out ResultItem: TAmazonObjectResult): Boolean;
var
  ItemNode, Aux: IXMLNode;
  NodeName: string;
begin
  Result := False;
  if (ObjectNode <> nil) and ObjectNode.HasChildNodes then
  begin
    ItemNode := ObjectNode.ChildNodes.First;

    while ItemNode <> nil do
    begin
      NodeName := ItemNode.NodeName;
      if AnsiSameText(NodeName, 'Key') then
        ResultItem.Name := ItemNode.Text
      else if AnsiSameText(NodeName, 'LastModified') then
        ResultItem.LastModified := ItemNode.Text
      else if AnsiSameText(NodeName, 'ETag') then
        ResultItem.ETag := ItemNode.Text
      else if AnsiSameText(NodeName, 'StorageClass') then
        ResultItem.StorageClass := ItemNode.Text
      else if AnsiSameText(NodeName, 'VersionId') then
        ResultItem.VersionId := ItemNode.Text
      else if AnsiSameText(NodeName, 'IsLatest') then
        ResultItem.IsLatest := AnsiSameText(ItemNode.Text, 'true')
      else if AnsiSameText(NodeName, 'Size') then
        ResultItem.Size := StrToInt64(ItemNode.Text)
      else if AnsiSameText(NodeName, 'Owner') then
      begin
        Aux := ItemNode.ChildNodes.FindNode('ID');
        if (Aux <> nil) and Aux.IsTextElement then
          ResultItem.OwnerID := Aux.Text;

        Aux := ItemNode.ChildNodes.FindNode('DisplayName');
        if (Aux <> nil) and Aux.IsTextElement then
          ResultItem.OwnerDisplayName := Aux.Text;
      end;

      ItemNode := ItemNode.NextSibling;
    end;

    Result := ResultItem.Name <> EmptyStr;
  end;
end;

procedure TAmazonStorageService.ParseResponseError(const ResponseInfo: TCloudResponseInfo;
                                                   const ResultString: string);
var
  xmlDoc: IXMLDocument;
  Aux, ErrorNode, MessageNode: IXMLNode;
  ErrorCode, ErrorMsg: string;
begin
  //If the ResponseInfo instance exists (to be populated) and the passed in string is Error XML, then
  //continue, otherwise exit doing nothing.
  if (ResponseInfo = nil) or (ResultString = EmptyStr) then
    Exit;

  if (AnsiPos('<Error', ResultString) > 0) then
  begin
    xmlDoc := TXMLDocument.Create(nil);
    try
      xmlDoc.LoadFromXML(ResultString);
    except
      //Response content isn't XML
      Exit;
    end;

    //Amazon has different formats for returning errors as XML
    ErrorNode := xmlDoc.DocumentElement;

    if (ErrorNode <> nil) and (ErrorNode.HasChildNodes) then
    begin
      MessageNode := ErrorNode.ChildNodes.FindNode(NODE_ERROR_MESSAGE);

      if (MessageNode <> nil) then
        ErrorMsg := MessageNode.Text;

      if ErrorMsg <> EmptyStr then
      begin
        //Populate the error code
        Aux := ErrorNode.ChildNodes.FindNode(NODE_ERROR_CODE);
        if (Aux <> nil) then
          ErrorCode := Aux.Text;
        ResponseInfo.StatusMessage := Format('%s - %s (%s)', [ResponseInfo.StatusMessage, ErrorMsg, ErrorCode]);
      end;
    end;
  end
end;

function TAmazonStorageService.CurrentTime: string;
begin
  Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"',
                           TTimeZone.Local.ToUniversalTime(Now),
                           TFormatSettings.Create('en-US'));
end;

destructor TAmazonStorageService.Destroy;
begin
  FreeAndNil(FRequiredHeaderNames);
  inherited;
end;

function TAmazonStorageService.CreateBucket(const BucketName: string; BucketACL: TAmazonACLType;
                                            BucketRegion: TAmazonRegion;
                                            ResponseInfo: TCloudResponseInfo): Boolean;
var
  BucketACLStr: string;
  RegionStr: string;
  url, virtualhost: string;
  contentStream: TStringStream;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  RespStr: string;
  ContentStr: string;
  ContentLength: Integer;
begin
  contentStream := nil;

  Headers := InitHeaders(BucketName, BucketRegion);
  BucketACLStr := GetACLTypeString(BucketACL);

  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/';
  virtualhost := GetConnectionInfo.StorageVirtualHost(BucketName, BucketRegion);
  RegionStr := GetRegionFromEndpoint(virtualhost);  //create bucket in same region as endpoint

  Headers.Values['host'] := virtualhost;

  //Optionally add in the ACL value
  if not BucketACLStr.IsEmpty then
    Headers.Values['x-amz-acl'] := BucketACLStr;

  if not RegionStr.Equals('us-east-1') then
  begin
    ContentStr := '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                    '<LocationConstraint>' + RegionStr + '</LocationConstraint>' +
                  '</CreateBucketConfiguration>';

    contentStream := TStringStream.Create;
    contentStream.WriteString(ContentStr);

    ContentLength := contentStream.Size;
    contentStream.position := 0;
  end
  else
    ContentLength := 0;

  if ContentLength > 0 then
     Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(ContentStr);

  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';

  QueryPrefix := '/' + BucketName + '/';

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, RespStr);
    ParseResponseError(ResponseInfo, RespStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(contentStream);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.ListBucketsXML(const ResponseInfo: TCloudResponseInfo): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL('', TAmazonConnectionInfo.DefaultRegion);
  Headers := InitHeaders('', TAmazonConnectionInfo.DefaultRegion);
  QueryPrefix := '/';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.ListBuckets(const ResponseInfo: TCloudResponseInfo): TStrings;
var
  xml: string;
  xmlDoc: IXMLDocument;
  ResultNode, BucketNode, Aux: IXMLNode;
  Name: string;
begin
  Result := nil;
  xml := ListBucketsXML(ResponseInfo);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(Result);
    end;

    ResultNode := xmlDoc.DocumentElement.ChildNodes.FindNode('Buckets');

    if ResultNode <> nil then
    begin
      Result := TStringList.Create;

      if not ResultNode.HasChildNodes then
        Exit(Result);

      BucketNode := ResultNode.ChildNodes.First;

      while BucketNode <> nil do
      begin
        if AnsiSameText(BucketNode.NodeName, 'Bucket') and BucketNode.HasChildNodes then
        begin
          Aux := BucketNode.ChildNodes.FindNode('Name');
          if (Aux <> nil) and Aux.IsTextElement then
          begin
            Name := Aux.Text;
            Aux := BucketNode.ChildNodes.FindNode('CreationDate');
            if (Aux <> nil) and Aux.IsTextElement then
            begin
              Result.Values[Name] := Aux.Text;
            end;
          end;
        end;
        BucketNode := BucketNode.NextSibling;
      end;
    end;
  end;
end;

function TAmazonStorageService.DeleteBucket(const BucketName: string; ResponseInfo: TCloudResponseInfo;
                                           BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  RespStr: string;
begin
  Response := nil;
  Headers := nil;
  try
    url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/';
    Headers := InitHeaders(BucketName, BucketRegion);
    QueryPrefix := '/' + BucketName + '/';

    Response := IssueDeleteRequest(url, Headers, nil, QueryPrefix, ResponseInfo, RespStr);
    ParseResponseError(ResponseInfo, RespStr);
    Result := (Response <> nil) and (Response.ResponseCode = 204);
  finally
    Response.Free;
    Headers.Free;
  end;
end;

function TAmazonStorageService.DeleteBucketPolicy(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  RespStr: string;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?policy=';
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := '/' + BucketName + '/?policy';

  Response := nil;
  try
    Response := IssueDeleteRequest(url, Headers, nil, QueryPrefix, ResponseInfo, RespStr);
    ParseResponseError(ResponseInfo, RespStr);
    Result := (Response <> nil) and (Response.ResponseCode = 204);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketXML(const BucketName: string; OptionalParams: TStrings;
                                            ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
begin
  Result := GetBucketXMLInternal(BucketName, OptionalParams, False, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.GetBucketXMLInternal(const BucketName: string; OptionalParams: TStrings;
  VersionInfo: Boolean; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryParams: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  QueryParams := nil;
  Response := nil;
  try
    url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/';
    Headers := InitHeaders(BucketName, BucketRegion);

    if VersionInfo then
    begin
      if QueryParams = nil then
        QueryParams := TStringList.Create;
      QueryParams.Values['versions'] := ' ';
    end;

    if (OptionalParams <> nil) and (OptionalParams.Count > 0) then
    begin
      if QueryParams = nil then
        QueryParams := TStringList.Create;
      QueryParams.AddStrings(OptionalParams);
    end;

    if QueryParams <> nil then
      url := BuildQueryParameterString(url, QueryParams, False, True);

    QueryPrefix := '/' + BucketName + '/';

    if VersionInfo then
      QueryPrefix := QueryPrefix + '?versions';

    Response := IssueGetRequest(url, Headers, QueryParams, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    QueryParams.Free;
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucket(const BucketName: string; OptionalParams: TStrings;
                                         ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TAmazonBucketResult;
var
  xml: string;
begin
  xml := GetBucketXML(BucketName, OptionalParams, ResponseInfo, BucketRegion);
  Result := GetBucketInternal(xml, ResponseInfo);
end;

function TAmazonStorageService.GetBucketInternal(const XML: string;
                                                 ResponseInfo: TCloudResponseInfo): TAmazonBucketResult;
var
  xmlDoc: IXMLDocument;
  RootNode, ItemNode, Aux: IXMLNode;
  NodeName: string;
  ResultItem: TAmazonObjectResult;
  IsVersionRequest: Boolean;
begin
  Result := nil;

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(nil);
    end;

    RootNode := xmlDoc.DocumentElement;

    IsVersionRequest := AnsiSameText(RootNode.NodeName, 'ListVersionsResult');

    //if it isn't a bucket content request or a version request, return nil
    if not (IsVersionRequest or AnsiSameText(RootNode.NodeName, 'ListBucketResult')) then
      Exit(nil);

    ItemNode := RootNode.ChildNodes.FindNode('Name');

    if (ItemNode = nil) or (not ItemNode.IsTextElement) then
      Exit(nil);

    Result := TAmazonBucketResult.Create(ItemNode.Text);

    ItemNode := RootNode.ChildNodes.First;

    while ItemNode <> nil do
    begin
      NodeName := ItemNode.NodeName;
      if AnsiSameText(NodeName, 'Prefix') then
        Result.RequestPrefix := ItemNode.Text
      else if AnsiSameText(NodeName, 'Delimiter') then
        Result.RequestDelimiter := ItemNode.Text
      else if (AnsiSameText(NodeName, 'Marker') or AnsiSameText(NodeName, 'KeyMarker') or
               AnsiSameText(NodeName, 'NextMarker')) and not ItemNode.Text.IsEmpty then
        Result.Marker := ItemNode.Text
      else if IsVersionRequest and AnsiSameText(NodeName, 'VersionIdMarker')  then
        Result.VersionIdMarker := ItemNode.Text
      else if AnsiSameText(NodeName, 'MaxKeys') then
        try
          Result.RequestMaxKeys := StrToInt(ItemNode.Text);
        except
        end
      else if AnsiSameText(NodeName, 'IsTruncated') then
        Result.IsTruncated := not AnsiSameText(ItemNode.Text, 'false')
      else if AnsiSameText(NodeName, 'Contents') or AnsiSameText(NodeName, 'Version') then
      begin
        if PopulateResultItem(ItemNode, ResultItem) then
          Result.Objects.Add(ResultItem);
      end
      else if AnsiSameText(NodeName, 'CommonPrefixes') then
      begin
        Aux := ItemNode.ChildNodes.First;

        while Aux <> nil do
        begin
          if AnsiSameText(Aux.NodeName, 'Prefix') and Aux.IsTextElement then
            Result.Prefixes.Add(Aux.Text);
          Aux := Aux.NextSibling;
        end;
      end;

      ItemNode := ItemNode.NextSibling;
    end;

    //populate the appropriate marker header values, depending on if it was a Content or Version population
    if Result.IsTruncated and (ResponseInfo <> nil) and (Result.Objects.Count > 1) then
    begin
      ResultItem := Result.Objects.Last;

      //If it was a version population, all objects will have a VersionId
      //and the marker parameters for a subsequent request will be different.
      if IsVersionRequest then
      begin
        ResponseInfo.Headers.Values['key-marker'] := ResultItem.Name;
        ResponseInfo.Headers.Values['version-id-marker'] := ResultItem.VersionId;
      end
      else
        ResponseInfo.Headers.Values['marker'] := ResultItem.Name;
    end;
  end;
end;

function TAmazonStorageService.GetBucketACLXML(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?acl=';
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := '/' + BucketName + '/?acl';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketACL(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TList<TAmazonGrant>;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, ListNode: IXMLNode;
begin
  Result := nil;
  xml := GetBucketACLXML(BucketName, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(nil);
    end;

    RootNode := xmlDoc.DocumentElement;

    if not AnsiSameText(RootNode.NodeName, 'AccessControlPolicy') then
      Exit(nil);

    Result := TList<TAmazonGrant>.Create;
    ListNode := RootNode.ChildNodes.FindNode('AccessControlList');

    if (ListNode = nil) then
      Exit(Result);

    PopulateGrants(ListNode, Result);
  end;
end;

function TAmazonStorageService.GetBucketPolicyJSON(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?policy=';
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := '/' + BucketName + '/?policy';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketPolicy(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TJSONObject;
var
  jsonString: string;
begin
  Result := nil;
  jsonString := GetBucketPolicyJSON(BucketName, ResponseInfo, BucketRegion);

  if AnsiStartsStr('{', jsonString) then
  begin
    try
      Result := TJSONObject(TJSONObject.ParseJSONValue(jsonString));
    except
      Result := nil;
    end;
  end;
end;

function TAmazonStorageService.GetBucketLocationXML(const BucketName: string;
  ResponseInfo: TCloudResponseInfo): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.GetServiceURL(GetConnectionInfo.DefaultStorageEndpoint) + '/'+ BucketName + '/?location=';
  Headers := InitHeaders(BucketName, TAmazonConnectionInfo.DefaultRegion);
  Headers.Values['host'] := GetConnectionInfo.DefaultStorageEndpoint;
  QueryPrefix := '/' + BucketName + '/?location';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketLocation(const BucketName: string;
  ResponseInfo: TCloudResponseInfo): TAmazonRegion;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode: IXMLNode;
begin
  Result := amzrNotSpecified;
  xml := GetBucketLocationXML(BucketName, ResponseInfo);

  if (ResponseInfo.StatusCode = 200) and not xml.IsEmpty then
  begin
    xmlDoc := TXMLDocument.Create(nil);
    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit;
    end;

    RootNode := xmlDoc.DocumentElement;
    if RootNode.NodeName.Equals('LocationConstraint') and RootNode.IsTextElement then
      Result := TAmazonConnectionInfo.GetRegionFromString(RootNode.Text);
  end;
end;

function TAmazonStorageService.GetBucketLoggingXML(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?logging=';

  Headers := InitHeaders(BucketName, BucketRegion);

  QueryPrefix := '/' + BucketName + '/?logging';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketLogging(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TAmazonBucketLoggingInfo;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, ItemNode, Aux: IXMLNode;
  TargetBucket: string;
begin
  Result := nil;

  xml := GetBucketLoggingXML(BucketName, ResponseInfo, BucketRegion);

  if xml = EmptyStr then
    Exit;

  xmlDoc := TXMLDocument.Create(nil);

  try
    xmlDoc.LoadFromXML(xml);
  except
    Exit;
  end;

  RootNode := xmlDoc.DocumentElement;

  if not AnsiSameText(RootNode.NodeName, 'BucketLoggingStatus') then
    Exit;

  try
    if RootNode.HasChildNodes then
    begin
      ItemNode := RootNode.ChildNodes.FindNode('LoggingEnabled');

      if (ItemNode <> nil) and ItemNode.HasChildNodes then
      begin
        Aux := ItemNode.ChildNodes.FindNode('TargetBucket');
        if (Aux <> nil) and Aux.IsTextElement then
        begin
          TargetBucket := Aux.Text;

          Aux := ItemNode.ChildNodes.FindNode('TargetPrefix');
          if (Aux <> nil) and Aux.IsTextElement then
          begin
            Result := TAmazonBucketLoggingInfo.Create(TargetBucket, Aux.Text);

            //Optionally populate Grant information
            Aux := ItemNode.ChildNodes.FindNode('TargetGrants');
            if (Aux <> nil) and Aux.HasChildNodes then
            begin
              PopulateGrants(Aux, Result.Grants);
            end;
          end;
        end;
      end;
    end;
  finally
    //If returning nil, then create a logging info instance with logging disabled
    if Result = nil then
      Result := TAmazonBucketLoggingInfo.Create;
  end;
end;

function TAmazonStorageService.GetBucketNotificationXML(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  Response := nil;
  try
    url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?notification=';
    Headers := InitHeaders(BucketName, BucketRegion);
    QueryPrefix := '/' + BucketName + '/?notification';

    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    Response.Free;
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketNotification(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TList<TAmazonNotificationEvent>;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, TopicNode, Aux: IXMLNode;
  TopicStr: string;
begin
  Result := nil;
  xml := GetBucketNotificationXML(BucketName, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit;
    end;

    RootNode := xmlDoc.DocumentElement;

    if AnsiSameText(RootNode.NodeName, 'NotificationConfiguration')  then
    begin
      Result := TList<TAmazonNotificationEvent>.Create;
      if RootNode.HasChildNodes then
      begin
        //Currently there will only be one TopicConfiguration node, but this will
        //allow for gracefully handling the case if/when more TopicConfigurations are allowed.
        TopicNode := RootNode.ChildNodes.First;

        while TopicNode <> nil do
        begin
          if AnsiSameText(TopicNode.NodeName, 'TopicConfiguration') and TopicNode.HasChildNodes then
          begin
            Aux := TopicNode.ChildNodes.FindNode('Topic');
            if (Aux <> nil) and Aux.IsTextElement then
            begin
              TopicStr := Aux.Text;
              Aux := TopicNode.ChildNodes.FindNode('Event');
              if (Aux <> nil) and Aux.IsTextElement then
              begin
                Result.Add(TAmazonNotificationEvent.Create(TopicStr, Aux.Text));
              end;
            end;
          end;
          TopicNode := TopicNode.NextSibling;
        end;
      end;
    end;
  end;
end;

function TAmazonStorageService.GetBucketObjectVersionsXML(const BucketName: string;
  OptionalParams: TStrings; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
begin
  Result := GetBucketXMLInternal(BucketName, OptionalParams, True, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.GetBucketObjectVersions(const BucketName: string;
  OptionalParams: TStrings; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TAmazonBucketResult;
var
  xml: string;
begin
  xml := GetBucketObjectVersionsXML(BucketName, OptionalParams, ResponseInfo, BucketRegion);
  Result := GetBucketInternal(xml, ResponseInfo);
end;

function TAmazonStorageService.GetRequestPaymentXML(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?requestPayment=';
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := '/' + BucketName + '/?requestPayment';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetRequestPayment(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TAmazonPayer;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, AuxNode: IXMLNode;
begin
  Result := ampUnknown;
  xml := GetRequestPaymentXML(BucketName, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit;
    end;

    RootNode := xmlDoc.DocumentElement;

    if AnsiSameText(RootNode.NodeName, 'RequestPaymentConfiguration') and RootNode.HasChildNodes then
    begin
      AuxNode := RootNode.ChildNodes.FindNode('Payer');
      if (AuxNode <> nil) and AuxNode.IsTextElement then
      begin
        if AnsiSameText(AuxNode.Text, 'Requester') then
          Result := ampRequester
        else
          Result := ampBucketOwner;
      end;
    end;
  end;
end;

function TAmazonStorageService.GetBucketVersioningXML(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?versioning=';
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := '/' + BucketName + '/?versioning';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetBucketVersioning(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, AuxNode: IXMLNode;
begin
  Result := false;
  xml := GetBucketVersioningXML(BucketName, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit;
    end;

    RootNode := xmlDoc.DocumentElement;

    if AnsiSameText(RootNode.NodeName, 'VersioningConfiguration') and RootNode.HasChildNodes then
    begin
      AuxNode := RootNode.ChildNodes.FindNode('Status');
      if (AuxNode <> nil) and AuxNode.IsTextElement then
        Result := AnsiSameText(AuxNode.Text, 'Enabled');
    end;
  end;
end;

function TAmazonStorageService.GetBucketMFADelete(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, AuxNode: IXMLNode;
begin
  Result := false;
  xml := GetBucketVersioningXML(BucketName, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit;
    end;

    RootNode := xmlDoc.DocumentElement;

    if AnsiSameText(RootNode.NodeName, 'VersioningConfiguration') and RootNode.HasChildNodes then
    begin
      AuxNode := RootNode.ChildNodes.FindNode('MfaDelete');
      if (AuxNode <> nil) and AuxNode.IsTextElement then
        Result := AnsiSameText(AuxNode.Text, 'Enabled');
    end;
  end;
end;

function TAmazonStorageService.GetBucketLifecycleXML(const ABucketName: string;
  AResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  LUrl: string;
  LHeaders: TStringList;
  LResponse: TCloudHTTP;
begin
  LResponse := nil;
  LHeaders := nil;
  try
    LUrl := GetConnectionInfo.StorageURL(ABucketName, BucketRegion) + '/?lifecycle=';
    LHeaders := InitHeaders(ABucketName, BucketRegion);
    LResponse := IssueGetRequest(LUrl, LHeaders, nil, '', AResponseInfo, Result);
    ParseResponseError(AResponseInfo, Result);
  finally
    LResponse.Free;
    LHeaders.Free;
  end;
end;

function TAmazonStorageService.ListMultipartUploadsXML(const BucketName: string;
  const OptionalParams: TStrings; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryParams: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/';

  QueryParams := TStringList.Create;
  QueryParams.Values['uploads'] := ' ';

  if (OptionalParams <> nil) and (OptionalParams.Count > 0) then
    QueryParams.AddStrings(OptionalParams);

  url := BuildQueryParameterString(url, QueryParams, False, True);

  Headers := InitHeaders(BucketName, BucketRegion);

  QueryPrefix := '/' + BucketName + '/?uploads';

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(QueryParams);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.ListMultipartUploads(const BucketName: string;
  const OptionalParams: TStrings; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): TAmazonMultipartUploadsResult;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, ItemNode, UploadItemNode: IXMLNode;
  Item: TAmazonMultipartUploadItem;
begin
  Result := nil;
  xml := ListMultipartUploadsXML(BucketName, OptionalParams, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit;
    end;

    RootNode := xmlDoc.DocumentElement;

    if AnsiSameText(RootNode.NodeName, 'ListMultipartUploadsResult') and RootNode.HasChildNodes then
    begin
      ItemNode := RootNode.ChildNodes.FindNode('Bucket');
      if (ItemNode = nil) or (not ItemNode.IsTextElement) then
        Exit;

      Result := TAmazonMultipartUploadsResult.Create(ItemNode.Text);

      ItemNode := RootNode.ChildNodes.First;

      while ItemNode <> nil do
      begin
        if AnsiSameText(ItemNode.NodeName, 'KeyMarker') then
          Result.KeyMarker := ItemNode.Text
        else if AnsiSameText(ItemNode.NodeName, 'UploadIdMarker') then
          Result.UploadIdMarker := ItemNode.Text
        else if AnsiSameText(ItemNode.NodeName, 'NextKeyMarker') then
          Result.NextKeyMarker := ItemNode.Text
        else if AnsiSameText(ItemNode.NodeName, 'NextUploadIdMarker') then
          Result.NextUploadIdMarker := ItemNode.Text
        else if AnsiSameText(ItemNode.NodeName, 'MaxUploads') then
          try
            Result.MaxUploads := StrToInt(ItemNode.Text);
          except
          end
        else if AnsiSameText(ItemNode.NodeName, 'IsTruncated') then
          Result.IsTruncated := AnsiSameText(ItemNode.Text, 'true')
        else if AnsiSameText(ItemNode.NodeName, 'Upload') and ItemNode.HasChildNodes then
        begin
          UploadItemNode := ItemNode.ChildNodes.FindNode('Key');
          if (UploadItemNode <> nil) and UploadItemNode.IsTextElement then
          begin
            Item := TAmazonMultipartUploadItem.Create(UploadItemNode.Text);

            UploadItemNode := ItemNode.ChildNodes.First;

            while UploadItemNode <> nil do
            begin
              if AnsiSameText(UploadItemNode.NodeName, 'UploadId') then
                Item.UploadId := UploadItemNode.Text
              else if AnsiSameText(UploadItemNode.NodeName, 'StorageClass') then
                Item.IsReducedRedundancyStorage := AnsiSameText(UploadItemNode.Text, 'REDUCED_REDUDANCY')
              else if AnsiSameText(UploadItemNode.NodeName, 'Initiated') then
                Item.DateInitiated := UploadItemNode.Text
              else if AnsiSameText(UploadItemNode.NodeName, 'Initiator') and UploadItemNode.HasChildNodes then
              begin
                Item.InitiatorId := GetChildText('ID', UploadItemNode);
                Item.InitiatorDisplayName := GetChildText('DisplayName', UploadItemNode);
              end
              else if AnsiSameText(UploadItemNode.NodeName, 'Owner') and UploadItemNode.HasChildNodes then
              begin
                Item.OwnerId := GetChildText('ID', UploadItemNode);
                Item.OwnerDisplayName := GetChildText('DisplayName', UploadItemNode);
              end;

              UploadItemNode := UploadItemNode.NextSibling;
            end;

            Result.UploadItems.Add(Item);
          end;
        end;

        ItemNode := ItemNode.NextSibling;
      end;
    end;
  end;
end;

function TAmazonStorageService.SetBucketACL(const BucketName: string;
  ACP: TAmazonAccessControlPolicy; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
var
  xml: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
begin
  if (BucketName = EmptyStr) or (ACP = nil) then
    Exit(False);

  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?acl=';

  xml := ACP.AsXML;

  contentStream := TStringStream.Create;
  contentStream.WriteString(xml);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';

  if ContentLength > 0 then
     Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(xml);

  QueryPrefix := '/' + BucketName + '/?acl';

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetBucketPolicy(const BucketName: string;
  Policy: TJSONObject; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  policyString: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
begin
  if (BucketName = EmptyStr) or (Policy = nil) then
    Exit(False);

  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?policy=';

  policyString := Policy.ToString;

  contentStream := TStringStream.Create;
  contentStream.WriteString(policyString);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';

   if ContentLength > 0 then
     Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(policyString);

  QueryPrefix := '/' + BucketName + '/?policy';

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 204);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetBucketLogging(const BucketName: string;
  LoggingInfo: TAmazonBucketLoggingInfo; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
var
  loggingString: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
begin
  if (BucketName = EmptyStr) then
    Exit(False);

  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?logging=';

  if LoggingInfo = nil then
    loggingString := TAmazonBucketLoggingInfo.GetDisableXML
  else
    loggingString := LoggingInfo.AsXML;

  contentStream := TStringStream.Create;
  contentStream.WriteString(loggingString);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';

  if ContentLength > 0 then
    Headers.Values['x-amz-content-sha256'] := TCloudSHA256Authentication.GetHashSHA256Hex(loggingString);

  QueryPrefix := '/' + BucketName + '/?logging';

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetBucketNotification(const BucketName: string;
  Events: TList<TAmazonNotificationEvent>; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
var
  xml: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
begin
  if (BucketName = EmptyStr)then
    Exit(False);

  contentStream := nil;
  Response := nil;
  try
    url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?notification=';
    Headers := InitHeaders(BucketName, BucketRegion);
    QueryPrefix := '/' + BucketName + '/?notification';

    xml := GetNotificationXML(Events);

    contentStream := TStringStream.Create;
    contentStream.WriteString(xml);
    contentStream.position := 0;
    ContentLength := contentStream.Size;

    Headers.Values['Content-Length'] := IntToStr(ContentLength);
    Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';
    if ContentLength > 0 then
       Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(xml);

    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    Response.Free;
    FreeAndNil(Headers);
    contentStream.Free;
  end;
end;

function TAmazonStorageService.SetBucketRequestPayment(const BucketName: string;
  Payer: TAmazonPayer; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  sb: TStringBuilder;
  xml: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
begin
  //must be a valid Payer
  if (BucketName = EmptyStr) or ((Payer <> ampRequester) and (Payer <> ampBucketOwner)) then
    Exit(False);

  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?requestPayment=';

{$IF RTLVERSION > 32}
  sb := TStringBuilder.Create(256);
{$ELSE}
  sb := TStringBuilder.Create;
{$ENDIF}
  try
    sb.Append('<RequestPaymentConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Payer>');
    if Payer = ampRequester then
      sb.Append('Requester')
    else
      sb.Append('BucketOwner');
    sb.Append('</Payer></RequestPaymentConfiguration>');

  {$IF RTLVERSION > 32}
    xml := sb.ToString(True);
  {$ELSE}
    xml := sb.ToString;
  {$ENDIF}
  finally
    sb.Free;
  end;

  contentStream := TStringStream.Create;
  contentStream.WriteString(xml);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';
  if ContentLength > 0 then
     Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(xml);

  QueryPrefix := '/' + BucketName + '/?requestPayment';

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetBucketVersioning(const BucketName: string;
  Enabled, MFADelete: Boolean; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
var
  sb: TStringBuilder;
  xml: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
  MFAInfoAvailable: Boolean;
begin
  if (BucketName = EmptyStr) then
    Exit(False);

  //MFA can only be used when the protocol is HTTPS
  MFAInfoAvailable := (GetConnectionInfo.MFASerialNumber <> EmptyStr) and
                      (GetConnectionInfo.MFAAuthCode <> EmptyStr) and
                       AnsiSameText(GetConnectionInfo.Protocol, 'https');

  //Fail if enabling MFA Delete but no MFA information is specified on the connection.
  if MFADelete and (not MFAInfoAvailable) then
    Exit(False);

  url := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?versioning=';

{$IF RTLVERSION > 32}
  sb := TStringBuilder.Create(256);
{$ELSE}
  sb := TStringBuilder.Create;
{$ENDIF}
  try
    sb.Append('<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>');
    if Enabled then
      sb.Append('Enabled')
    else
      sb.Append('Suspended');
    sb.Append('</Status><MfaDelete>');
    if MFADelete then
      sb.Append('Enabled')
    else
      sb.Append('Disabled');
    sb.Append('</MfaDelete></VersioningConfiguration>');

  {$IF RTLVERSION > 32}
    xml := sb.ToString(True);
  {$ELSE}
    xml := sb.ToString;
  {$ENDIF}
  finally
    sb.Free;
  end;

  contentStream := TStringStream.Create;
  contentStream.WriteString(xml);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';
  if ContentLength > 0 then
     Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(xml);

  //set the MFA Info if it is available
  if MFAInfoAvailable then
    Headers.Values['x-amz-mfa'] :=
       Format('%s %s', [GetConnectionInfo.MFASerialNumber, GetConnectionInfo.MFAAuthCode]);

  QueryPrefix := '/' + BucketName + '/?versioning';

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetBucketLifecycle(const BucketName: string;
  const LifeCycle: TAmazonLifeCycleConfiguration; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): boolean;
var
  LContentStream: TStringStream;
  LContentLength: Integer;
  LHeaders: TStringList;
  LUrl, LXml: string;
  LResponse: TCloudHTTP;
begin
  LResponse := nil;
  LHeaders := nil;
  LContentStream := nil;
  try
    LUrl := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?lifecycle=';
    LXml := LifeCycle.XML;

    LContentStream := TStringStream.Create;
    LContentStream.WriteString(LXml);
    LContentStream.Position := 0;
    LContentLength := LContentStream.Size;

    LHeaders := InitHeaders(BucketName, BucketRegion);
    LHeaders.Values['Content-Length'] := IntToStr(LContentLength);
    LHeaders.Values['Content-MD5'] := TNetEncoding.Base64.EncodeBytesToString(THashMD5.GetHashBytes(LXml));
    if LContentLength > 0 then
      LHeaders.Values['x-amz-content-sha256'] := TCloudSHA256Authentication.GetHashSHA256Hex(LXml);

    LResponse := IssuePutRequest(LUrl, LHeaders, nil, '', ResponseInfo, LContentStream);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 200);
  finally
    LContentStream.Free;
    LHeaders.Free;
    LResponse.Free;
  end;
end;

function TAmazonStorageService.DeleteObjectInternal(const BucketName, ObjectName, VersionId: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryParams: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  RespStr: string;
  MFAInfoAvailable: Boolean;
begin
  QueryParams := nil;

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion);

  if VersionId <> EmptyStr then
  begin
    QueryParams := TStringList.Create;
    QueryParams.Values['versionId'] := VersionId;
    url := BuildQueryParameterString(url, QueryParams, False, True);
  end;

  //MFA can only be used when the protocol is HTTPS and a versioned object is being deleted
  MFAInfoAvailable := (VersionId <> EmptyStr) and
                      (GetConnectionInfo.MFASerialNumber <> EmptyStr) and
                      (GetConnectionInfo.MFAAuthCode <> EmptyStr) and
                       AnsiSameText(GetConnectionInfo.Protocol, 'https');

  Headers := InitHeaders(BucketName, BucketRegion);

  //set the MFA Info if it is available
  if MFAInfoAvailable then
    Headers.Values['x-amz-mfa'] :=
       Format('%s %s', [GetConnectionInfo.MFASerialNumber, GetConnectionInfo.MFAAuthCode]);

  QueryPrefix := '/' + BucketName + '/' + ObjectName;

  Response := nil;
  try
    Response := IssueDeleteRequest(url, Headers, QueryParams, QueryPrefix, ResponseInfo, RespStr);
    ParseResponseError(ResponseInfo, RespStr);
    Result := (Response <> nil) and (Response.ResponseCode = 204);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(QueryParams);
  end;
end;

function TAmazonStorageService.DeleteObject(const BucketName, ObjectName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := DeleteObjectInternal(BucketName, ObjectName, EmptyStr, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.DeleteObjectVersion(const BucketName, ObjectName, VersionId: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := DeleteObjectInternal(BucketName, ObjectName, VersionId, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.DeleteBucketLifecycle(const BucketName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  LUrl: string;
  LHeaders: TStringList;
  LResponse: TCloudHTTP;
begin
  LResponse := nil;
  LHeaders := nil;
  try
    LUrl := GetConnectionInfo.StorageURL(BucketName, BucketRegion) + '/?lifecycle=';
    LHeaders := InitHeaders(BucketName, BucketRegion);
    LResponse := IssueDeleteRequest(LUrl, LHeaders, nil, '', ResponseInfo);
    Result := (LResponse <> nil) and (LResponse.ResponseCode = 204);
  finally
    LHeaders.Free;
    LResponse.Free;
  end;
end;

function TAmazonStorageService.GetObject(const BucketName, ObjectName: string;
  OptionalParams: TAmazonGetObjectOptionals; ObjectStream: TStream;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := GetObjectInternal(BucketName, ObjectName, EmptyStr, OptionalParams,
    ResponseInfo, ObjectStream, BucketRegion);
end;

function TAmazonStorageService.GetObject(const BucketName, ObjectName: string;
  ObjectStream: TStream; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := GetObject(BucketName, ObjectName, TAmazonGetObjectOptionals.Create,
    ObjectStream, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.GetObjectVersion(const BucketName, ObjectName, VersionId: string;
  OptionalParams: TAmazonGetObjectOptionals; ObjectStream: TStream;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := GetObjectInternal(BucketName, ObjectName, VersionId, OptionalParams,
    ResponseInfo, ObjectStream, BucketRegion);
end;

function TAmazonStorageService.GetObjectVersion(const BucketName, ObjectName, VersionId: string;
  ObjectStream: TStream; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := GetObjectVersion(BucketName, ObjectName, VersionId, TAmazonGetObjectOptionals.Create,
    ObjectStream, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.GetObjectInternal(const BucketName, ObjectName, VersionId: string;
  OptionalParams: TAmazonGetObjectOptionals; ResponseInfo: TCloudResponseInfo;
  ObjectStream: TStream; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  if (BucketName = EmptyStr)then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion);

  Headers := InitHeaders(BucketName, BucketRegion);
  OptionalParams.PopulateHeaders(Headers);

  QueryPrefix := Format('/%s/%s', [BucketName, ObjectName]);

  if VersionId <> EmptyStr then
  begin
    url := Format('%s?versionId=%s', [url, VersionId]);
    QueryPrefix := Format('%s?versionId=%s', [QueryPrefix, VersionId]);
  end;

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, ObjectStream);

    //A 404 error means that the object was deleted. So in a way the request would also
    //be successful when a 404 response code is returned, but the returned stream wouldn't be valid.
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetObjectACLXML(const BucketName, ObjectName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) then
    Exit;

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?acl=';

  Headers := InitHeaders(BucketName, BucketRegion);

  QueryPrefix := Format('/%s/%s?acl', [BucketName, ObjectName]);

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetObjectACL(const BucketName, ObjectName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TList<TAmazonGrant>;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, ListNode: IXMLNode;
begin
  Result := nil;
  xml := GetObjectACLXML(BucketName, ObjectName, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(nil);
    end;

    RootNode := xmlDoc.DocumentElement;

    if not AnsiSameText(RootNode.NodeName, 'AccessControlPolicy') then
      Exit(nil);

    Result := TList<TAmazonGrant>.Create;
    ListNode := RootNode.ChildNodes.FindNode('AccessControlList');

    if (ListNode = nil) then
      Exit(Result);

    PopulateGrants(ListNode, Result);
  end;
end;

function TAmazonStorageService.GetObjectTorrent(const BucketName, ObjectName: string;
  ObjectStream: TStream; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  if (BucketName = EmptyStr)then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?torrent=';
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := Format('/%s/%s?torrent', [BucketName, ObjectName]);

  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, ObjectStream);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.GetObjectMetadata(const BucketName, ObjectName: string;
  OptionalParams: TAmazonGetObjectOptionals; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): TStrings;
var
  Properties: TStrings;
begin
  GetObjectProperties(BucketName, ObjectName, TAmazonGetObjectOptionals.Create,
                      Properties, Result, ResponseInfo, BucketRegion);
  FreeAndNil(Properties);
end;

function TAmazonStorageService.GetObjectMetadata(const BucketName, ObjectName: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TStrings;
begin
  Result := GetObjectMetadata(BucketName, ObjectName, TAmazonGetObjectOptionals.Create,
    ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.GetObjectProperties(const BucketName, ObjectName: string;
  OptionalParams: TAmazonGetObjectOptionals; out Properties, Metadata: TStrings;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  CurrentHeaderName, QueryPrefix, url: string;
  Headers: TStringList;
  Response: TCloudHTTP;
  FreeResponseInfo: Boolean;
  I, Count: Integer;
begin
  Result := False;
  Properties := nil;
  Metadata := nil;

  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion);

  Headers := InitHeaders(BucketName, BucketRegion);
  try
    OptionalParams.PopulateHeaders(Headers);

    QueryPrefix := string.Format('/%s/%s', [BucketName, ObjectName]);

    FreeResponseInfo := ResponseInfo = nil;
    if FreeResponseInfo then
      ResponseInfo := TCloudResponseInfo.Create;

    Response := nil;
    try
      Response := IssueHeadRequest(url, Headers, nil, QueryPrefix, ResponseInfo);
      if (Response <> nil) and (Response.ResponseCode = 200) then
      begin
        Result := True;

        Properties := TStringList.Create;
        Metadata := TStringList.Create;

        Count := ResponseInfo.Headers.Count;
        for I := 0 to Count - 1 do
        begin
          CurrentHeaderName := ResponseInfo.Headers.Names[I];
          if AnsiStartsText('x-amz-meta-', CurrentHeaderName) then
          begin
            //strip the "x-amz-meta-" prefix from the name of the header,
            //to get the original metadata header name, as entered by the user.
            CurrentHeaderName := CurrentHeaderName.Substring(11);
            Metadata.Values[CurrentHeaderName] := ResponseInfo.Headers.ValueFromIndex[I];
          end
          else
            Properties.Values[CurrentHeaderName] := ResponseInfo.Headers.ValueFromIndex[I];
        end;
      end;
    finally
      Response.Free;
      if FreeResponseInfo then
        ResponseInfo.Free;
    end;
  finally
    Headers.Free;
  end;
end;

function TAmazonStorageService.GetObjectProperties(const BucketName, ObjectName: string;
  out Properties, Metadata: TStrings; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
begin
  Result := GetObjectProperties(BucketName, ObjectName, TAmazonGetObjectOptionals.Create,
                                Properties, Metadata, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.UploadObject(const BucketName, ObjectName: string;
  Content: TArray<Byte>; ReducedRedundancy: Boolean; Metadata, Headers: TStrings;
  ACL: TAmazonACLType; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  LHeaders: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  contentStream: TBytesStream;
  responseStr: string;
  ContentLength: Integer;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion);

  LHeaders := InitHeaders(BucketName, BucketRegion);
  //if unspecified amazon sets content-type to 'binary/octet-stream';

  if ReducedRedundancy then
    LHeaders.Values['x-amz-storage-class'] := CLASS_REDUCED_REDUNDANCY;

  LHeaders.Values['x-amz-acl'] := GetACLTypeString(ACL);

  if Headers <> nil then
    AddAndValidateHeaders(LHeaders,Headers);

  AddS3MetadataHeaders(LHeaders, Metadata);

  QueryPrefix := Format('/%s/%s', [BucketName, ObjectName]);

  contentStream := TBytesStream.Create(Content);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  if ContentLength > 0 then
    LHeaders.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetStreamToHashSHA256Hex(contentStream);
  LHeaders.Values['Content-Length'] := IntToStr(ContentLength);

  Response := nil;
  try
    Response := IssuePutRequest(url, LHeaders, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and ((Response.ResponseCode = 200) or (Response.ResponseCode = 100));
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(LHeaders);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetObjectACL(const BucketName, ObjectName: string;
  ACP: TAmazonAccessControlPolicy; Headers: TStrings; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
var
  xml: string;
  url: string;
  LHeaders: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Integer;
  contentStream: TStringStream;
  responseStr: string;
begin
  if (BucketName = EmptyStr) or (ACP = nil) then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?acl=';

  xml := ACP.AsXML;

  contentStream := TStringStream.Create;
  contentStream.WriteString(xml);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  LHeaders := InitHeaders(BucketName, BucketRegion);

  if Headers <> nil then
    LHeaders.AddStrings(Headers);

  LHeaders.Values['Content-Length'] := IntToStr(ContentLength);
  LHeaders.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';
  if ContentLength > 0 then
     LHeaders.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(xml);

  QueryPrefix := '/' + BucketName + '/' + ObjectName + '?acl';

  Response := nil;
  try
    Response := IssuePutRequest(url, LHeaders, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(LHeaders);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.SetObjectACL(const BucketName, ObjectName: string;
  ACL: TAmazonACLType; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  responseStr: string;
  contentStream: TStringStream;
begin
  if BucketName.IsEmpty then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?acl=';

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['x-amz-acl'] := GetACLTypeString(ACL);
  Headers.Values['Content-Length'] := '0';

  QueryPrefix := '/' + BucketName + '/' + ObjectName + '?acl';

  contentStream := TStringStream.Create;

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.CopyObject(const DestinationBucket, DestinationObjectName,
  SourceBucket, SourceObjectName: string; OptionalParams: TAmazonCopyObjectOptionals;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
begin
  Result := CopyObjectVersion(DestinationBucket, DestinationObjectName, SourceBucket,
    SourceObjectName, EmptyStr, OptionalParams, ResponseInfo, BucketRegion);
end;

function TAmazonStorageService.SetObjectMetadata(const BucketName, ObjectName: string;
  Metadata: TStrings; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  Optionals: TAmazonCopyObjectOptionals;
begin
  try
    Optionals := TAmazonCopyObjectOptionals.Create;
    Optionals.FCopyMetadata := False;
    Optionals.FMetadata.AddStrings(Metadata);

    Result := CopyObject(BucketName, ObjectName, BucketName, ObjectName, Optionals,
      ResponseInfo, BucketRegion);
  finally
    FreeAndNil(Optionals);
  end;
end;

procedure TAmazonStorageService.SortHeaders(const Headers: TStringList);
begin
  if (Headers <> nil) then
  begin
    Headers.CustomSort(CaseSensitiveHyphenCompare);
  end;
end;

                                                                   
// For Amazon, add a '=' between each query parameter name anad value, even if a parameter value is empty
function TAmazonStorageService.BuildQueryParameterString(const QueryPrefix: string; QueryParameters: TStringList;
                                                         DoSort, ForURL: Boolean): string;
var
  Count: Integer;
  I: Integer;
  lastParam, nextParam: string;
  QueryStartChar, QuerySepChar, QueryKeyValueSepChar: Char;
  CurrValue: string;
  CommaVal: string;
begin
  //if there aren't any parameters, just return the prefix
  if (QueryParameters = nil) or (QueryParameters.Count = 0) then
    Exit(QueryPrefix);

  if ForURL then
  begin
    //If the query parameter string is beign created for a URL, then
    //we use the default characters for building the strings, as will be required in a URL
    QueryStartChar := '?';
    QuerySepChar := '&';
    QueryKeyValueSepChar := '=';
  end
  else
  begin
    //otherwise, use the characters as they need to appear in the signed string
    QueryStartChar := FQueryStartChar;
    QuerySepChar := FQueryParamSeparator;
    QueryKeyValueSepChar := FQueryParamKeyValueSeparator;
  end;

  if DoSort and not QueryParameters.Sorted then
    SortQueryParameters(QueryParameters, ForURL);

  Count := QueryParameters.Count;

  lastParam := QueryParameters.Names[0];
  CurrValue := Trim(QueryParameters.ValueFromIndex[0]);

  //URL Encode the firs set of params
  URLEncodeQueryParams(ForURL, lastParam, CurrValue);

  Result := QueryPrefix + QueryStartChar + lastParam + QueryKeyValueSepChar + CurrValue;

  //in the URL, the comma character must be escaped. In the StringToSign, it shouldn't be.
  //this may need to be pulled out into a function which can be overridden by individual Cloud services.
  if ForURL then
    CommaVal := '%2c'
  else
    CommaVal := ',';

  //add the remaining query parameters, if any
  for I := 1 to Count - 1 do
  begin
    nextParam := Trim(QueryParameters.Names[I]);
    CurrValue := QueryParameters.ValueFromIndex[I];

    URLEncodeQueryParams(ForURL, nextParam, CurrValue);

    //match on key name only if the key names are not empty string.
    //if there is a key with no value, it should be formatted as in the else block
    if (lastParam <> EmptyStr) and (AnsiCompareText(lastParam, nextParam) = 0) then
      Result := Result + CommaVal + CurrValue
    else begin
      if (not ForURL) or (nextParam <> EmptyStr) then
        Result := Result + QuerySepChar + nextParam + QueryKeyValueSepChar + CurrValue;
      lastParam := nextParam;
    end;
  end;
end;

function TAmazonStorageService.CopyObjectVersion(const DestinationBucket,
  DestinationObjectName, SourceBucket, SourceObjectName, SourceVersionId: string;
  OptionalParams: TAmazonCopyObjectOptionals; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  responseStr: string;
  LSourceBucketName, LDestBucketName: string;
begin
  if (DestinationBucket = EmptyStr) or (DestinationObjectName = EmptyStr) or
     (SourceBucket = EmptyStr) or (SourceObjectName = EmptyStr) then
    Exit(False);

  LSourceBucketName := AnsiLowerCase(SourceBucket);
  LDestBucketName := AnsiLowerCase(DestinationBucket);

  url := BuildObjectURL(LDestBucketName, DestinationObjectName, BucketRegion);

  QueryPrefix := Format('/%s/%s', [LDestBucketName, DestinationObjectName]);

  Headers := InitHeaders(LDestBucketName, BucketRegion);
  Headers.Values['Content-Length'] := '0';

  if OptionalParams <> nil then
    OptionalParams.PopulateHeaders(Headers);

  if SourceVersionId <> EmptyStr then
    Headers.Values['x-amz-copy-source'] :=
      Format('/%s/%s?versionId=%s', [LSourceBucketName, SourceObjectName, SourceVersionId])
  else
    Headers.Values['x-amz-copy-source'] := Format('/%s/%s', [LSourceBucketName, SourceObjectName]);

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, nil, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.InitiateMultipartUploadXML(const BucketName, ObjectName: string;
  Metadata, Headers: TStrings; ACL: TAmazonACLType; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): string;
var
  url: string;
  LHeaders: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) then
    Exit(EmptyStr);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?uploads=';
  QueryPrefix := Format('/%s/%s?uploads', [BucketName, ObjectName]);

  LHeaders := InitHeaders(BucketName, BucketRegion);

  if Headers <> nil then
    LHeaders.AddStrings(Headers);

  AddS3MetadataHeaders(LHeaders, Metadata);

  LHeaders.Values['Content-Length'] := '0';
  LHeaders.Values['x-amz-acl'] := GetACLTypeString(ACL);

  Response := nil;
  try
    Response := IssuePostRequest(url, LHeaders, nil, QueryPrefix, ResponseInfo, nil, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(LHeaders);
  end;
end;

function TAmazonStorageService.InitiateMultipartUpload(const BucketName, ObjectName: string;
  Metadata, Headers: TStrings; ACL: TAmazonACLType; ResponseInfo: TCloudResponseInfo;
  BucketRegion: TAmazonRegion): string;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, IDNode: IXMLNode;
begin
  xml := InitiateMultipartUploadXML(BucketName, ObjectName, Metadata, Headers,
    ACL, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(EmptyStr);
    end;

    RootNode := xmlDoc.DocumentElement;

    if not AnsiSameText(RootNode.NodeName, 'InitiateMultipartUploadResult') then
      Exit(EmptyStr);

    IDNode := RootNode.ChildNodes.FindNode('UploadId');

    if (IDNode <> nil) and IDNode.IsTextElement then
      Result := IDNode.Text;
  end;
end;

function TAmazonStorageService.AbortMultipartUpload(const BucketName, ObjectName, UploadId: string;
  ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  responseStr: string;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?uploadId=' + UploadId;
  Headers := InitHeaders(BucketName, BucketRegion);
  QueryPrefix := Format('/%s/%s?uploadId=%s', [BucketName, ObjectName, UploadId]);

  Response := nil;
  try
    Response := IssueDeleteRequest(url, Headers, nil, QueryPrefix, ResponseInfo, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 204);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.UploadPart(const BucketName, ObjectName, UploadId: string;
  PartNumber: Integer; Content: TArray<Byte>; out Part: TAmazonMultipartPart;
  const ContentMD5: string; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  contentStream: TBytesStream;
  responseStr: string;
  FreeResponseInfo: Boolean;
  ContentLength: Int64;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) or (UploadId = EmptyStr) or (Content = nil) then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) +
    Format('?partNumber=%d&uploadId=%s', [PartNumber, UploadId]);

  Headers := InitHeaders(BucketName, BucketRegion);

  QueryPrefix := Format('/%s/%s', [BucketName, ObjectName]);
  QueryPrefix := Format('%s?partNumber=%d&uploadId=%s', [QueryPrefix, PartNumber, UploadId]);

  contentStream := TBytesStream.Create(Content);
  ContentLength := contentStream.Size;
  contentStream.position := 0;
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  Headers.Values['Content-Type'] := 'application/x-www-form-urlencoded; charset=utf-8';
  if ContentLength > 0 then
    Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetStreamToHashSHA256Hex(contentStream);

  if ContentMD5 <> EmptyStr then
    Headers.Values['Content-MD5'] := ContentMD5;

  FreeResponseInfo := ResponseInfo = nil;
  if FreeResponseInfo then
    ResponseInfo := TCloudResponseInfo.Create;

  Response := nil;
  try
    Response := IssuePutRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);

    if Result then
    begin
      Part.PartNumber := PartNumber;
      Part.ETag := ResponseInfo.Headers.Values['ETag'];
      Part.Size := ContentLength;
      Part.LastModified := ResponseInfo.Headers.Values['Date'];
    end;
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
    if FreeResponseInfo then
      ResponseInfo.Free;
  end;
end;

function TAmazonStorageService.CompleteMultipartUpload(const BucketName, ObjectName, UploadId: string;
  Parts: TList<TAmazonMultipartPart>; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): Boolean;
var
  xml: string;
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  ContentLength: Int64;
  contentStream: TStringStream;
  responseStr: string;
  sb: TStringBuilder;
  Part: TAmazonMultipartPart;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) or (UploadId = EmptyStr) or (Parts = nil) then
    Exit(False);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + '?uploadId=' + URLEncodeValue(UploadId);

{$IF RTLVERSION > 32}
  sb := TStringBuilder.Create(256);
{$ELSE}
  sb := TStringBuilder.Create;
{$ENDIF}
  try
    sb.Append('<CompleteMultipartUpload>');
    for Part In Parts do
      sb.Append(Part.AsXML);
    sb.Append('</CompleteMultipartUpload>');

  {$IF RTLVERSION > 32}
    xml := sb.ToString(True);
  {$ELSE}
    xml := sb.ToString;
  {$ENDIF}
  finally
    sb.Free;
  end;

  contentStream := TStringStream.Create;
  contentStream.WriteString(xml);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  Headers := InitHeaders(BucketName, BucketRegion);
  Headers.Values['Content-Length'] := IntToStr(ContentLength);
  // When the platform is not Windows, it's necessary to specify that we are sending binary content
  Headers.Values['Content-Type'] := 'application/octet-stream';
  if ContentLength > 0 then
     Headers.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetHashSHA256Hex(xml);

  QueryPrefix := '/' + BucketName + '/' + ObjectName + '?uploadId=' + UploadId;

  Response := nil;
  try
    Response := IssuePostRequest(url, Headers, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and (Response.ResponseCode = 200);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
    FreeAndNil(contentStream);
  end;
end;

function TAmazonStorageService.ListMultipartUploadPartsXML(const BucketName, ObjectName, UploadId: string;
  MaxParts, PartNumberMarker: Integer; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): string;
var
  url: string;
  Headers: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  QuerySuffix: string;
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) or (UploadId = EmptyStr)  then
    Exit(EmptyStr);

  QuerySuffix := '?uploadId=' + UploadId;

  if MaxParts > 0 then
    QuerySuffix := QuerySuffix + '&max-parts=' + IntToStr(MaxParts);

  if PartNumberMarker > 0 then
    QuerySuffix := QuerySuffix + '&part-number-marker=' + IntToStr(PartNumberMarker);

  url := BuildObjectURL(BucketName, ObjectName, BucketRegion) + QuerySuffix;

  QueryPrefix := Format('/%s/%s%s', [BucketName, ObjectName, QuerySuffix]);

  Headers := InitHeaders(BucketName, BucketRegion);
  Response := nil;
  try
    Response := IssueGetRequest(url, Headers, nil, QueryPrefix, ResponseInfo, Result);
    ParseResponseError(ResponseInfo, Result);
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(Headers);
  end;
end;

function TAmazonStorageService.ListMultipartUploadParts(const BucketName, ObjectName, UploadId: string;
  MaxParts, PartNumberMarker: Integer; ResponseInfo: TCloudResponseInfo; BucketRegion: TAmazonRegion): TAmazonListPartsResult;
var
  xml: string;
  xmlDoc: IXMLDocument;
  RootNode, ItemNode: IXMLNode;
  PartNumber: Integer;
  ETag: string;
  Part: TAmazonMultipartPart;
begin
  result := nil;
  xml := ListMultipartUploadPartsXML(BucketName, ObjectName, UploadId, MaxParts,
                                     PartNumberMarker, ResponseInfo, BucketRegion);

  if xml <> EmptyStr then
  begin
    xmlDoc := TXMLDocument.Create(nil);

    try
      xmlDoc.LoadFromXML(xml);
    except
      Exit(nil);
    end;

    RootNode := xmlDoc.DocumentElement;

    if not AnsiSameText(RootNode.NodeName, 'ListPartsResult') then
      Exit(nil);

    Result := TAmazonListPartsResult.Create(BucketName, ObjectName, UploadId);

    ItemNode := RootNode.ChildNodes.First;

    while ItemNode <> nil do
    begin
      if AnsiSameText(ItemNode.NodeName, 'Initiator') then
      begin
        Result.InitiatorId := GetChildText('ID', ItemNode);
        Result.InitiatorDisplayName := GetChildText('DisplayName', ItemNode);
      end
      else if AnsiSameText(ItemNode.NodeName, 'Owner') then
      begin
        Result.OwnerId := GetChildText('ID', ItemNode);
        Result.OwnerDisplayName := GetChildText('DisplayName', ItemNode);
      end
      else if AnsiSameText(ItemNode.NodeName, 'StorageClass') then
        Result.IsReducedRedundancyStorage := AnsiSameText(ItemNode.Text, 'REDUCED_REDUDANCY')
      else if AnsiSameText(ItemNode.NodeName, 'PartNumberMarker') then
        try
          Result.PartNumberMarker := StrToInt(ItemNode.Text)
        except
        end
      else if AnsiSameText(ItemNode.NodeName, 'NextPartNumberMarker') then
        try
          Result.NextPartNumberMarker := StrToInt(ItemNode.Text)
        except
        end
      else if AnsiSameText(ItemNode.NodeName, 'MaxParts') then
        try
          Result.MaxParts := StrToInt(ItemNode.Text)
        except
        end
      else if AnsiSameText(ItemNode.NodeName, 'IsTruncated') then
        Result.IsTruncated := AnsiSameText(ItemNode.Text, 'true')
      else if AnsiSameText(ItemNode.NodeName, 'Part') then
      begin
        try
          PartNumber := StrToInt(GetChildText('PartNumber', ItemNode));
          ETag := GetChildText('ETag', ItemNode);

          Part := TAmazonMultipartPart.Create(PartNumber, ETag);
          Part.LastModified := GetChildText('LastModified', ItemNode);
          Part.Size := StrToInt64(GetChildText('Size', ItemNode));

          Result.Parts.Add(Part);
        except
        end;
      end;

      ItemNode := ItemNode.NextSibling;
    end;
  end;
end;

end.
