unit Amazon.Storage.Service.Intf;

interface

uses System.Classes, Amazon.Storage.Service.API;

type
  IAmazonStorageService = interface
    ['{FDDE1936-EFEB-4EE2-9853-9E56CE020BE2}']
    function DownloadFile(const AFileName: string): TMemoryStream;
    function ListBuckets: TStrings;
    function GetBucket(const ABucketName: string): TAmazonBucketResult;
    procedure CreateBucket(const ABucketName: string);
    procedure DeleteBucket(const ABucketName: string);
    procedure UploadFile(const AFilePath: string); overload;
    procedure UploadFile(const AFilePath, AFileName: string); overload;
    procedure UploadFile(const AFile: TMemoryStream; AFileName: string); overload;
    procedure DeleteFile(const AFileName: string);
  end;

implementation

end.
