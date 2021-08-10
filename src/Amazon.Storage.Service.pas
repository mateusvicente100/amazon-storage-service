unit Amazon.Storage.Service;

interface

uses Amazon.Storage.Service.Intf, System.Classes, Amazon.Storage.Service.API, Amazon.Storage.Service.Config, System.SysUtils,
  IdCustomHTTPServer, Data.Cloud.CloudAPI, Amazon.Storage.Service.Types, System.Math;

type
  TAmazonRegion = Amazon.Storage.Service.API.TAmazonRegion;
  TAmazonStorageServiceConfig = Amazon.Storage.Service.Config.TAmazonStorageServiceConfig;
  TAmazonBucketResult = Amazon.Storage.Service.API.TAmazonBucketResult;
  TAmazonObjectResult = Amazon.Storage.Service.API.TAmazonObjectResult;
  TAmazonProtocol = Amazon.Storage.Service.Types.TAmazonProtocol;
  TAmazonStorageService = class(TInterfacedObject, IAmazonStorageService)
  private
    FStorage: Amazon.Storage.Service.API.TAmazonStorageService;
    FBucketName: string;
    function Configuration: TAmazonStorageServiceConfig;
    function GetFileContentType(const AFilePath: string): string;
    function DownloadFile(const AFileName: string): TMemoryStream;
    function ListBuckets: TStrings;
    function GetBucket(const ABucketName: string): TAmazonBucketResult;
    procedure CreateBucket(const ABucketName: string);
    procedure DeleteBucket(const ABucketName: string);
    procedure UploadFile(const AFilePath: string); overload;
    procedure UploadFile(const AFilePath, AFileName: string); overload;
    procedure UploadFile(const AFile: TMemoryStream; AFileName: string); overload;
    procedure DeleteFile(const AFileName: string);
    constructor Create(const ABucketName: string);
  public
    class function New(const ABucketName: string = ''): IAmazonStorageService;
    destructor Destroy; override;
  end;

implementation

uses Winapi.Windows;

procedure TAmazonStorageService.UploadFile(const AFilePath, AFileName: string);
var
  LBinaryReader: TBinaryReader;
  LFileContent: TBytes;
  LFileInformation: TStringList;
  LResponseInfo: TCloudResponseInfo;
begin
  try
    if not FileExists(AFilePath) then
      raise Exception.Create('Não foi possível encontrar o arquivo no diretório informado!');

    if FBucketName.Trim.IsEmpty then
      raise Exception.Create('Não foi informado o bucket name de onde o arquivo deverá ficar salvo!');

    LBinaryReader := TBinaryReader.Create(AFilePath);
    try
      LFileContent := LBinaryReader.ReadBytes(LBinaryReader.BaseStream.Size);
    finally
      LBinaryReader.Free;
    end;

    LFileInformation := TStringList.Create;
    LResponseInfo := TCloudResponseInfo.Create;
    try
      LFileInformation.Add('Content-type=' + GetFileContentType(AFilePath));
      if not FStorage.UploadObject(FBucketName, AFileName, LFileContent, False, LFileInformation, nil,
         TAmazonACLType.amzbaPrivate, LResponseInfo) then
        raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
    finally
      LResponseInfo.Free;
      LFileInformation.Free;
    end;
  except
    on E:Exception do
      raise Exception.Create('Não foi possível fazer o upload do arquivo. O seguinte erro ocorreu: ' + sLineBreak + E.Message);
  end;
end;

procedure TAmazonStorageService.UploadFile(const AFile: TMemoryStream; AFileName: string);
var
  LFilePath: string;
  LTempFolder: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @LTempFolder);
  LFilePath := StrPas(LTempFolder) + FormatDateTime('hhmmss', Now) + Random(1000).ToString +
               StringReplace(AFileName,'/','_',[rfReplaceAll, rfIgnoreCase]);
  try
    AFile.Position := 0;
    AFile.SaveToFile(LFilePath);
    Self.UploadFile(LFilePath, AFileName);
  finally
    if FileExists(LFilePath) then
      DeleteFile(LFilePath);
  end;
end;

procedure TAmazonStorageService.UploadFile(const AFilePath: string);
begin
  Self.UploadFile(AFilePath, ExtractFileName(AFilePath));
end;

function TAmazonStorageService.Configuration: TAmazonStorageServiceConfig;
begin
  Result := TAmazonStorageServiceConfig.GetInstance;
end;

constructor TAmazonStorageService.Create(const ABucketName: string);
begin
  FStorage := TAmazonStorageServiceConfig.GetInstance.GetNewStorage;
  FBucketName := ABucketName;
  if ABucketName.Trim.IsEmpty then
    FBucketName := Self.Configuration.MainBucketName;
end;

procedure TAmazonStorageService.CreateBucket(const ABucketName: string);
var
  LResponseInfo: TCloudResponseInfo;
begin
  LResponseInfo := TCloudResponseInfo.Create;
  try
    FStorage.CreateBucket(ABucketName, TAmazonACLType.amzbaPrivate, Self.Configuration.Region, LResponseInfo);
    if LResponseInfo.StatusCode <> 200 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

procedure TAmazonStorageService.DeleteBucket(const ABucketName: string);
var
  LResponseInfo: TCloudResponseInfo;
begin
  LResponseInfo := TCloudResponseInfo.Create;
  try
    FStorage.DeleteBucket(ABucketName, LResponseInfo, Self.Configuration.Region);
    if LResponseInfo.StatusCode <> 204 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

procedure TAmazonStorageService.DeleteFile(const AFileName: string);
begin
  try
    if FBucketName.Trim.IsEmpty then
      raise Exception.Create('Não foi informado o bucket name de onde o arquivo se encontra!');
    FStorage.DeleteObject(FBucketName, AFileName);
  except
    on E:Exception do
      raise Exception.Create('Erro ao excluir o arquivo. O seguinte erro ocorreu: ' + sLineBreak + E.Message);
  end;
end;

destructor TAmazonStorageService.Destroy;
begin
  FStorage.ConnectionInfo.Free;
  FStorage.Free;
  inherited;
end;

function TAmazonStorageService.DownloadFile(const AFileName: string): TMemoryStream;
begin
  Result := nil;
  try
    if FBucketName.Trim.IsEmpty then
      raise Exception.Create('Não foi informado o bucket name de onde o arquivo se encontra!');
    Result := TMemoryStream.Create;
    FStorage.GetObject(FBucketName, AFileName, Result);
    Result.Position := 0;
  except
    on E:Exception do
    begin
      if Assigned(Result) then
        Result.Free;
      raise Exception.Create('Erro ao fazer download do arquivo. O seguinte erro ocorreu: ' + sLineBreak + E.Message);
    end;
  end;
end;

function TAmazonStorageService.GetBucket(const ABucketName: string): TAmazonBucketResult;
var
  LResponseInfo: TCloudResponseInfo;
begin
  LResponseInfo := TCloudResponseInfo.Create;
  try
    Result := FStorage.GetBucket(ABucketName, nil, LResponseInfo);
    if LResponseInfo.StatusCode <> 200 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

function TAmazonStorageService.GetFileContentType(const AFilePath: string): string;
var
  LMIMETable: TIdThreadSafeMimeTable;
begin
  LMIMETable := TIdThreadSafeMimeTable.Create(True);
  try
    Result := LMIMETable.GetFileMIMEType(AFilePath);
  finally
    LMIMETable.Free;
  end;
end;

function TAmazonStorageService.ListBuckets: TStrings;
var
  LResponseInfo: TCloudResponseInfo;
begin
  LResponseInfo := TCloudResponseInfo.Create;
  try
    Result := FStorage.ListBuckets(LResponseInfo);
    if LResponseInfo.StatusCode <> 200 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

class function TAmazonStorageService.New(const ABucketName: string = ''): IAmazonStorageService;
begin
  Result := TAmazonStorageService.Create(ABucketName);
end;

end.
