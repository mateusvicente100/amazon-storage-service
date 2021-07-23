unit Amazon.Storage.Service.Config;

interface

uses Amazon.Storage.Service.API, Amazon.Storage.Service.Types;

type
  TAmazonStorageServiceConfig = class
  private
    FAccessKey: string;
    FSecretKey: string;
    FRegion: TAmazonRegion;
    FMainBucketName: string;
    FProtocol: TAmazonProtocol;
  public
    property AccessKey: string read FAccessKey write FAccessKey;
    property SecretKey: string read FSecretKey write FSecretKey;
    property Region: TAmazonRegion read FRegion write FRegion;
    property Protocol: TAmazonProtocol read FProtocol write FProtocol;
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
  LAmazonConnectionInfo.Protocol := FProtocol.GetValue;
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
  begin
    AmazonStorageServiceConfig := TAmazonStorageServiceConfig(inherited NewInstance);
    AmazonStorageServiceConfig.Protocol := TAmazonProtocol.http;
  end;
  Result := AmazonStorageServiceConfig;
end;

initialization

finalization
  if Assigned(AmazonStorageServiceConfig) then
    AmazonStorageServiceConfig.Free;

end.
