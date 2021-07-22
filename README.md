# amazon-storage-service
A wrapper class that uses native delphi integration to amazon storage service.

![Delphi Supported Versions](https://img.shields.io/badge/Delphi%20Supported%20Versions-10.1%20and%20ever-blue.svg)
![Platforms](https://img.shields.io/badge/Supported%20platforms-Win32%20and%20Win64-red.svg)

## Prerequisites

`[Optional]` For ease I recommend using the Boss for installation

* [**Boss**](https://github.com/HashLoad/boss) - Dependency Manager for Delphi

## Installation using Boss (dependency manager for Delphi applications)

```html
boss install github.com/mateusvicente100/amazon-storage-service
```

## Manual Installation

Add the following folder to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*

```html
../amazon-storage-service/src
```

## Getting Started

You need to use Amazon.Storage.Service

```pascal
uses Amazon.Storage.Service;
```

First of all you need at once configure the amazon settings to connect in the server. This sould be done on start of your program.

```pascal
procedure InitializeAmazonService;
begin
  TAmazonStorageServiceConfig.GetInstance.AccessKey := 'your-access-key';
  TAmazonStorageServiceConfig.GetInstance.SecretKey := 'your-secret-key';
  TAmazonStorageServiceConfig.GetInstance.Region := TAmazonRegion.YourRegion;  
  TAmazonStorageServiceConfig.GetInstance.MainBucketName := 'your-main-bucket-name'; // Optional
  TAmazonStorageServiceConfig.GetInstance.Initialize;
end;
```

## List buckets

You can list all your buckets

```pascal
procedure ListAllBuckets;
var
  LBuckets: TStrings;
  I: Integer;
begin
  LBuckets := TAmazonStorageService.New.ListBuckets;
  try     
    for I := 0 to Pred(LBuckets.Count) do
      memoLog.Lines.Add(LBuckets.Names[I]);
  finally
    LBuckets.Free;
  end;
end;  
```

## Create a bucket

You can create a bucket sending the bucket name 

```pascal
procedure CreateBucket(const ABucketName: string);
begin
  TAmazonStorageService.New.CreateBucket(ABucketName);
end;  
```

## Delete a bucket

You can delete a bucket sending the bucket name 

```pascal
procedure CreateBucket(const ABucketName: string);
begin
  TAmazonStorageService.New.DeleteBucket(ABucketName);
end;  
```

## List files from a bucket

You can list all files from one specific bucket

```pascal
procedure ListAllFilesFromBucket(const ABucketName: string);
var
  LFiles: TAmazonBucketResult;
  LFile: TAmazonObjectResult;
begin
  LFiles := TAmazonStorageService.New.GetBucket(ABucketName);
  try    
    for LFile in LFiles.Objects do    
      memoLog.Lines.Add(LFile.Name);      
  finally
    LFiles.Free;
  end;
```

## Upload a file

You can upload a file using the file directory and main bucket name or using a specific bucket name

```pascal
procedure UploadFile(const AFileDirectory: string);
begin
  TAmazonStorageService.New.UploadFile(AFileDirectory);
end;  
```

## Delete a file

You can delete a file using the file name and main bucket name or using a specific bucket name

```pascal
procedure DeleteFile(const AFileName: string);
begin
  TAmazonStorageService.New.DeleteFile(AFileName);
end;  
```

## Download a file

You can download a file using the file name with the bucket main name or using a specific bucket name

```pascal
procedure DownloadFile(const AFileName: string);
begin
  TAmazonStorageService.New.DownloadFile(AFileName);
end;  
```