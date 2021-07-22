unit Amazon.Storage.Service.Config;

interface

uses Amazon.Storage.Service.API;

type
  TAmazonStorageServiceConfig = class
  private
    FStorage: TAmazonStorageService;
    FConnectionInfo: TAmazonConnectionInfo;
    FMainBucketName: string;
    function GetAccessKey: string;
    function GetSecretKey: string;
    function GetAmazonRegion: TAmazonRegion;
    procedure SetAccessKey(const AValue: string);
    procedure SetSecretKey(const AValue: string);
    procedure SetAmazonRegion(const AValue: TAmazonRegion);
    procedure CreateConnectionInfo;
  public
    property AccessKey: string read GetAccessKey write SetAccessKey;
    property SecretKey: string read GetSecretKey write SetSecretKey;
    property Region: TAmazonRegion read GetAmazonRegion write SetAmazonRegion;
    property MainBucketName: string read FMainBucketName write FMainBucketName;
    function GetStorage: TAmazonStorageService;
    procedure Inicializar;
    class function NewInstance: TObject; override;
    class function GetInstance: TAmazonStorageServiceConfig;
    destructor Destroy; override;
  end;

var
  AmazonStorageServiceConfig: TAmazonStorageServiceConfig;

implementation

procedure TAmazonStorageServiceConfig.CreateConnectionInfo;
begin
  FConnectionInfo := TAmazonConnectionInfo.Create(nil);
  FConnectionInfo.Protocol := 'https';
  FConnectionInfo.UseDefaultEndpoints := False;
end;

destructor TAmazonStorageServiceConfig.Destroy;
begin
  FConnectionInfo.Free;
  if Assigned(FStorage) then
    FStorage.Free;
  inherited;
end;

function TAmazonStorageServiceConfig.GetAccessKey: string;
begin
  Result := FConnectionInfo.AccountName;
end;

function TAmazonStorageServiceConfig.GetAmazonRegion: TAmazonRegion;
begin
  Result := FConnectionInfo.Region;
end;

function TAmazonStorageServiceConfig.GetStorage: TAmazonStorageService;
begin
  Result := FStorage;
end;

class function TAmazonStorageServiceConfig.GetInstance: TAmazonStorageServiceConfig;
begin
  Result := TAmazonStorageServiceConfig.Create;
end;

function TAmazonStorageServiceConfig.GetSecretKey: string;
begin
  Result := FConnectionInfo.AccountKey;
end;

procedure TAmazonStorageServiceConfig.Inicializar;
begin
  if Assigned(FStorage) then
    FStorage.Free;
  FStorage := TAmazonStorageService.Create(FConnectionInfo);
end;

class function TAmazonStorageServiceConfig.NewInstance: TObject;
begin
  if not (Assigned(AmazonStorageServiceConfig)) then
  begin
    AmazonStorageServiceConfig := TAmazonStorageServiceConfig(inherited NewInstance);
    AmazonStorageServiceConfig.CreateConnectionInfo;
  end;
  Result := AmazonStorageServiceConfig;
end;

procedure TAmazonStorageServiceConfig.SetAccessKey(const AValue: string);
begin
  FConnectionInfo.AccountName := AValue;
end;

procedure TAmazonStorageServiceConfig.SetAmazonRegion(const AValue: TAmazonRegion);
begin
  FConnectionInfo.Region := AValue;
end;

procedure TAmazonStorageServiceConfig.SetSecretKey(const AValue: string);
begin
  FConnectionInfo.AccountKey := AValue;
end;

initialization

finalization
  if Assigned(AmazonStorageServiceConfig) then
    AmazonStorageServiceConfig.Free;

end.
