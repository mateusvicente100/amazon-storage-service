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

First of all you need at once configure the amazon settings to connect in the server

```pascal
procedure InitializeAmazonService;
begin
  TAmazonStorageServiceConfig.GetInstance.AccessKey := 'your-access-key';
  TAmazonStorageServiceConfig.GetInstance.SecretKey := 'your-secret-key';
  TAmazonStorageServiceConfig.GetInstance.Region := TAmazonRegion.YourRegion;  
  TAmazonStorageServiceConfig.GetInstance.MainBucketName := 'your-main-bucket-name'; // Optional
  TAmazonStorageServiceConfig.GetInstance.Inicializar;
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
```