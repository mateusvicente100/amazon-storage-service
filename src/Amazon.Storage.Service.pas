unit Amazon.Storage.Service;

interface

uses Amazon.Storage.Service.Intf, System.Classes, Amazon.Storage.Service.API, Amazon.Storage.Service.Config, System.SysUtils,
  IdCustomHTTPServer, Data.Cloud.CloudAPI;

type
  TAmazonRegion = Amazon.Storage.Service.API.TAmazonRegion;
  TAmazonStorageServiceConfig = Amazon.Storage.Service.Config.TAmazonStorageServiceConfig;
  TAmazonBucketResult = Amazon.Storage.Service.API.TAmazonBucketResult;
  TAmazonObjectResult = Amazon.Storage.Service.API.TAmazonObjectResult;
  TAmazonStorageService = class(TInterfacedObject, IAmazonStorageService)
  private
    function Storage: Amazon.Storage.Service.API.TAmazonStorageService;
    function Configuration: TAmazonStorageServiceConfig;
    function GetBucketName(const ABucketName: string): string;
    function GetFileContentType(const AFilePath: string): string;
    function DownloadFile(const AFileName: string; const ABucketName: string = ''): TMemoryStream;
    function ListBuckets: TStrings;
    function GetBucket(const ABucketName: string): TAmazonBucketResult;
    procedure CreateBucket(const ABucketName: string);
    procedure DeleteBucket(const ABucketName: string);
    procedure UploadFile(const AFilePath: string; const ABucketName: string = ''); overload;
    procedure UploadFile(const AFile: TMemoryStream; AFileName: string; const ABucketName: string = ''); overload;
    procedure DeleteFile(const AFileName: string; const ABucketName: string = '');
  public
    class function New: IAmazonStorageService;
  end;

implementation

uses Winapi.Windows;

function TAmazonStorageService.Storage: Amazon.Storage.Service.API.TAmazonStorageService;
begin
  Result := TAmazonStorageServiceConfig.GetInstance.GetStorage;
end;

procedure TAmazonStorageService.UploadFile(const AFile: TMemoryStream; AFileName: string; const ABucketName: string);
var
  LFilePath: string;
  LTempFolder: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @LTempFolder);
  LFilePath := StrPas(LTempFolder) + AFileName;
  try
    AFile.Position := 0;
    AFile.SaveToFile(LFilePath);
    UploadFile(LFilePath, ABucketName);
  finally
    if FileExists(LFilePath) then
      DeleteFile(LFilePath);
  end;
end;

procedure TAmazonStorageService.UploadFile(const AFilePath, ABucketName: string);
var
  LBinaryReader: TBinaryReader;
  LBucketName: string;
  LFileContent: TBytes;
  LFileInformation: TStringList;
  LResponseInfo: TCloudResponseInfo;
begin
  try
    if not FileExists(AFilePath) then
      raise Exception.Create('Não foi possível encontrar o arquivo no diretório informado!');

    LBucketName := GetBucketName(ABucketName);
    if LBucketName.Trim.IsEmpty then
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
      if not Self.Storage.UploadObject(LBucketName, ExtractFileName(AFilePath), LFileContent, False, LFileInformation, nil,
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

function TAmazonStorageService.Configuration: TAmazonStorageServiceConfig;
begin
  Result := TAmazonStorageServiceConfig.GetInstance;
end;

procedure TAmazonStorageService.CreateBucket(const ABucketName: string);
var
  LResponseInfo: TCloudResponseInfo;
begin
  LResponseInfo := TCloudResponseInfo.Create;
  try
    Self.Storage.CreateBucket(ABucketName, TAmazonACLType.amzbaPrivate, Self.Configuration.Region, LResponseInfo);
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
    Self.Storage.DeleteBucket(ABucketName, LResponseInfo, Self.Configuration.Region);
    if LResponseInfo.StatusCode <> 204 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

procedure TAmazonStorageService.DeleteFile(const AFileName, ABucketName: string);
var
  LBucketName: string;
begin
  try
    LBucketName := GetBucketName(ABucketName);
    if LBucketName.Trim.IsEmpty then
      raise Exception.Create('Não foi informado o bucket name de onde o arquivo se encontra!');
    Self.Storage.DeleteObject(LBucketName, AFileName);
  except
    on E:Exception do
      raise Exception.Create('Erro ao excluir o arquivo. O seguinte erro ocorreu: ' + sLineBreak + E.Message);
  end;
end;

function TAmazonStorageService.DownloadFile(const AFileName: string; const ABucketName: string = ''): TMemoryStream;
var
  LBucketName: string;
begin
  Result := nil;
  try
    LBucketName := GetBucketName(ABucketName);
    if LBucketName.Trim.IsEmpty then
      raise Exception.Create('Não foi informado o bucket name de onde o arquivo se encontra!');
    Result := TMemoryStream.Create;
    Self.Storage.GetObject(LBucketName, AFileName, Result);
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
    Result := Self.Storage.GetBucket(ABucketName, nil, LResponseInfo);
    if LResponseInfo.StatusCode <> 200 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

function TAmazonStorageService.GetBucketName(const ABucketName: string): string;
begin
  Result := ABucketName;
  if ABucketName.Trim.IsEmpty then
    Result := Self.Configuration.MainBucketName;
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
    Result := Self.Storage.ListBuckets(LResponseInfo);
    if LResponseInfo.StatusCode <> 200 then
      raise Exception.CreateFmt('%d - %s', [LResponseInfo.StatusCode, LResponseInfo.StatusMessage]);
  finally
    LResponseInfo.Free;
  end;
end;

class function TAmazonStorageService.New: IAmazonStorageService;
begin
  Result := TAmazonStorageService.Create;
end;

end.
