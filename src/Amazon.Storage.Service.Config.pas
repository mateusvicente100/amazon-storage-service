unit Amazon.Storage.Service.Config;

interface

uses Amazon.Storage.Service.API;

type
  TAmazonStorageServiceConfig = class
  private
    FAccessKey: string;
    FSecretKey: string;
    FRegion: TAmazonRegion;
    FMainBucketName: string;
  public
    property AccessKey: string read FAccessKey write FAccessKey;
    property SecretKey: string read FSecretKey write FSecretKey;
    property Region: TAmazonRegion read FRegion write FRegion;
    property MainBucketName: string read FMainBucketName write FMainBucketName;
    function GetNewStorage: TAmazonStorageService;
    class function NewInstance: TObject; override;
    class function GetInstance: TAmazonStorageServiceConfig;
  end;

var
  AmazonStorageServiceConfig: TAmazonStorageServiceConfig;

implementation

function TAmazonStorageServiceConfig.GetNewStorage: TAmazonStorageService;
var
  LAmazonConnectionInfo: TAmazonConnectionInfo;
begin
  LAmazonConnectionInfo := TAmazonConnectionInfo.Create(nil);
  LAmazonConnectionInfo.Protocol := 'https';
  LAmazonConnectionInfo.UseDefaultEndpoints := False;
  LAmazonConnectionInfo.AccountName := FAccessKey;
  LAmazonConnectionInfo.AccountKey := FSecretKey;
  LAmazonConnectionInfo.Region := FRegion;
  Result := TAmazonStorageService.Create(LAmazonConnectionInfo);
end;

class function TAmazonStorageServiceConfig.GetInstance: TAmazonStorageServiceConfig;
begin
  Result := TAmazonStorageServiceConfig.Create;
end;

class function TAmazonStorageServiceConfig.NewInstance: TObject;
begin
  if not (Assigned(AmazonStorageServiceConfig)) then
    AmazonStorageServiceConfig := TAmazonStorageServiceConfig(inherited NewInstance);
  Result := AmazonStorageServiceConfig;
end;

initialization

finalization
  if Assigned(AmazonStorageServiceConfig) then
    AmazonStorageServiceConfig.Free;

end.
