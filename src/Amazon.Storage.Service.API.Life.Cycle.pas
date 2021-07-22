{*******************************************************}
{                                                       }
{           CodeGear Delphi Runtime Library             }
{ Copyright(c) 2016-2019 Embarcadero Technologies, Inc. }
{              All rights reserved                      }
{                                                       }
{*******************************************************}

unit Amazon.Storage.Service.API.Life.Cycle;

interface

{$SCOPEDENUMS ON}

uses
  System.Classes, System.Generics.Collections;

type
  /// <summary>Supported transitions.</summary>
  TAmazonStorageClass = (Standard, StandardIA, Glacier, ReduceRedundancy);

  /// <summary>Class to store lifecycle transition.</summary>
  TAmazonLifeCycleTransition = record
  private
    /// <summary>Specifies the number of days after object creation when the specific rule action takes effect.</summary>
    FDays: Integer;
    /// <summary>Specifies the Amazon S3 storage class to which you want the object to transition.</summary>
    FStorageClass: TAmazonStorageClass;

    /// <summary>Return the XML representation.</summary>
    /// <returns>Return the XML representation.</returns>
    function GetXML: string;
  public
    /// <summary>Creates a new instance of TAmazonLifeCycleRule.</summary>
    /// <param name="ADays">Specifies the number of days after object creation when the specific rule action takes effect.</param>
    /// <param name="AStorageClass">Specifies the Amazon S3 storage class to which you want the object to transition.</param>
    /// <returns>Return a lifecycle transition.</returns>
    class function Create(ADays: Integer; AStorageClass: TAmazonStorageClass): TAmazonLifeCycleTransition; static;

    /// <summary>Specifies the number of days after object creation when the specific rule action takes effect.</summary>
    property Days: Integer read FDays;
    /// <summary>Specifies the Amazon S3 storage class to which you want the object to transition.</summary>
    property StorageClass: TAmazonStorageClass read FStorageClass;
    /// <summary>The XML representation.</summary>
    property XML: string read GetXML;
  end;

  /// <summary>Class to store lifecycle rules.</summary>
  TAmazonLifeCycleRule = record
  private
    /// <summary>Unique identifier for the rule. The value cannot be longer than 255 characters.</summary>
    FID: string;
    /// <summary>Object key prefix identifying one or more objects to which the rule applies.</summary>
    FPrefix: string;
    /// <summary>If Enabled, Amazon S3 executes the rule as scheduled. If Disabled, Amazon S3 ignores the rule.</summary>
    FStatus: boolean;
    /// <summary>List of stored transitions.</summary>
    FTransitions: TArray<TAmazonLifeCycleTransition>;
    /// <summary>Specifies a period in the object's lifetime when Amazon S3 should take the appropriate expiration action.</summary>
    FExpirationDays: Integer;
    /// <summary>Specifies the number of days an object is noncurrent before Amazon S3 can perform the associated action.</summary>
    FNoncurrentVersionTransitionDays: Integer;
    /// <summary>Specifies the Amazon S3 storage class to which you want the object to transition.</summary>
    FNoncurrentVersionTransitionStorageClass: TAmazonStorageClass;
    /// <summary>Specifies when noncurrent object versions expire. Upon expiration, Amazon S3 permanently deletes the noncurrent object versions.</summary>
    FNoncurrentVersionExpirationDays: Integer;

    /// <summary>Return a lifecycle transition.</summary>
    /// <param name="AIndex">The lifecycle index to obtain.</param>
    /// <returns>Return a lifecycle transition.</returns>
    function GetTransition(AIndex: Integer): TAmazonLifeCycleTransition;
    /// <summary>Return the XML representation.</summary>
    /// <returns>Return the XML representation.</returns>
    function GetXML: string;
  public
    /// <summary>Creates a new instance of TAmazonLifeCycleRule.</summary>
    /// <param name="AID">Unique identifier for the rule. The value cannot be longer than 255 characters.</param>
    /// <param name="APrefix">Object key prefix identifying one or more objects to which the rule applies.</param>
    /// <param name="AStatus">If Enabled, Amazon S3 executes the rule as scheduled. If Disabled, Amazon S3 ignores the rule.</param>
    /// <param name="ATransitions">List of transitions to store.</param>
    /// <param name="AExpirationDays">Specifies a period in the object's lifetime when Amazon S3 should take the appropriate expiration action.</param>
    /// <param name="ANoncurrentVersionTransitionDays">Specifies the number of days an object is noncurrent before Amazon S3 can perform the associated action.</param>
    /// <param name="ANoncurrentVersionTransitionStorageClass">Specifies the Amazon S3 storage class to which you want the object to transition.</param>
    /// <param name="ANoncurrentVersionExpirationDays">Specifies when noncurrent object versions expire. Upon expiration, Amazon S3 permanently deletes the noncurrent object versions.</param>
    /// <returns>Return a lifecycle rule.</returns>
    class function Create(const AID: string; const APrefix: string; AStatus: boolean;
      ATransitions: TArray<TAmazonLifeCycleTransition>; AExpirationDays, ANoncurrentVersionTransitionDays: Integer;
      ANoncurrentVersionTransitionStorageClass: TAmazonStorageClass; ANoncurrentVersionExpirationDays: Integer): TAmazonLifeCycleRule; static;
    /// <summary>Add a new transition.</summary>
    /// <param name="ADays">Specifies the number of days after object creation when the specific rule action takes effect.</param>
    /// <param name="AStorageClass">Specifies the Amazon S3 storage class to which you want the object to transition.</param>
    /// <returns>Return the index of the transition in the transition list.</returns>
    function AddTransition(ADays: Integer; AStorageClass: TAmazonStorageClass): Integer;
    /// <summary>Removes a transition in the transition list.</summary>
    /// <param name="AIndex">Specifies the index of the transition to remove.</param>
    procedure DeleteTransition(AIndex: Integer);

    /// <summary>Unique identifier for the rule. The value cannot be longer than 255 characters.</summary>
    property ID: string read FID;
    /// <summary>Object key prefix identifying one or more objects to which the rule applies.</summary>
    property Prefix: string read FPrefix;
    /// <summary>If Enabled, Amazon S3 executes the rule as scheduled. If Disabled, Amazon S3 ignores the rule.</summary>
    property Status: boolean read FStatus;
    /// <summary>List of stored transitions.</summary>
    property Transitions[Index: Integer]: TAmazonLifeCycleTransition read GetTransition; default;
    /// <summary>Specifies a period in the object's lifetime when Amazon S3 should take the appropriate expiration action.</summary>
    property ExpirationDays: Integer read FExpirationDays write FExpirationDays;
    /// <summary>Specifies the number of days an object is noncurrent before Amazon S3 can perform the associated action.</summary>
    property NoncurrentVersionTransitionDays: Integer read FNoncurrentVersionTransitionDays;
    /// <summary>Specifies the Amazon S3 storage class to which you want the object to transition.</summary>
    property NoncurrentVersionTransitionStorageClass: TAmazonStorageClass read FNoncurrentVersionTransitionStorageClass;
    /// <summary>Specifies when noncurrent object versions expire. Upon expiration, Amazon S3 permanently deletes the noncurrent object versions.</summary>
    property NoncurrentVersionExpirationDays: Integer read FNoncurrentVersionExpirationDays;
    /// <summary>The XML representation.</summary>
    property XML: string read GetXML;
  end;

  /// <summary>Class to store lifecycle configuration.</summary>
  TAmazonLifeCycleConfiguration = record
  private
    /// <summary>List of stored rules.</summary>
    FRules: TArray<TAmazonLifeCycleRule>;

    /// <summary>Return a lifecycle rule.</summary>
    /// <param name="AIndex">The lifecycle rule index to obtain.</param>
    /// <returns>Return a lifecycle rule.</returns>
    function GetRule(AIndex: Integer): TAmazonLifeCycleRule;
    /// <summary>Return the XML representation.</summary>
    /// <returns>Return the XML representation.</returns>
    function GetXML: string;
  public
    /// <summary>Creates a new instance of TAmazonLifeCycleConfiguration.</summary>
    /// <param name="ARules">List of rules to store.</param>
    /// <returns>Return a lifecycle configuration.</returns>
    class function Create(ARules: TArray<TAmazonLifeCycleRule>): TAmazonLifeCycleConfiguration; static;
    /// <summary>Add a new rule.</summary>
    /// <param name="AID">Unique identifier for the rule. The value cannot be longer than 255 characters.</param>
    /// <param name="APrefix">Object key prefix identifying one or more objects to which the rule applies.</param>
    /// <param name="AStatus">If Enabled, Amazon S3 executes the rule as scheduled. If Disabled, Amazon S3 ignores the rule.</param>
    /// <param name="ATransitions">List of transitions to store.</param>
    /// <param name="AExpirationDays">Specifies a period in the object's lifetime when Amazon S3 should take the appropriate expiration action.</param>
    /// <param name="ANoncurrentVersionTransitionDays">Specifies the number of days an object is noncurrent before Amazon S3 can perform the associated action.</param>
    /// <param name="ANoncurrentVersionTransitionStorageClass">Specifies the Amazon S3 storage class to which you want the object to transition.</param>
    /// <param name="ANoncurrentVersionExpirationDays">Specifies when noncurrent object versions expire. Upon expiration, Amazon S3 permanently deletes the noncurrent object versions.</param>
    /// <returns>Return the index of the rule in the rule list.</returns>
    function AddRule(const AID: string; const APrefix: string; AStatus: boolean;
      ATransitions: TArray<TAmazonLifeCycleTransition>; AExpirationDays, ANoncurrentVersionTransitionDays: Integer;
      ANoncurrentVersionTransitionStorageClass: TAmazonStorageClass;
      ANoncurrentVersionExpirationDays: Integer): Integer; overload;
    /// <summary>Add a new rule.</summary>
    /// <param name="ARule">A rule to add to the list of rules.</param>
    /// <returns>Return the index of the rule in the rule list.</returns>
    function AddRule(const ARule: TAmazonLifeCycleRule): Integer; overload;
    /// <summary>Removes a rule in the rule list.</summary>
    /// <param name="AIndex">Specifies the index of the rule to remove.</param>
    procedure DeleteRule(AIndex: Integer);

    /// <summary>List of stored rules.</summary>
    property Rules[Index: Integer]: TAmazonLifeCycleRule read GetRule; default;
    /// <summary>The XML representation.</summary>
    property XML: string read GetXML;
  end;

implementation

uses
  System.SysUtils,
  Xml.XMLIntf, Xml.XMLDoc,
  Data.Cloud.CloudResStrs;

const
  cLifeCycleConfiguration = 'LifeCycleConfiguration';
  cLifeCycleRule = 'Rule';
  cLifeCycleTransition = 'Transition';
  cStorageClass = 'StorageClass';
  cID = 'ID';
  cPrefix = 'Prefix';
  cStatus = 'Status';
  cExpiration = 'Expiration';
  cDays = 'Days';
  cNoncurrentVersionTransition = 'NoncurrentVersionTransition';
  cNoncurrentVersionExpiration = 'NoncurrentVersionExpiration';
  cNoncurrentDays = 'NoncurrentDays';
  cStandard = 'STANDARD';
  cStandardIA = 'STANDARD_IA';
  cGlacier = 'GLACIER';
  cReducedRedundancy = 'REDUCED_REDUNDANCY';
  cBooleanText: array[boolean] of string = ('Disabled', 'Enabled');

function WriteOpenTag(const ANAme: string): string;
begin
  Result := '<' + AName + '>';
end;

function WriteCloseTag(const AName: string): string;
begin
  Result := '</' + AName + '>';
end;

function WriteEmptyTag(const AName: string): string;
begin
  Result := '<' + AName + '/>';
end;

function WriteValueTag(const AName, AValue: string): string;
begin
  Result := WriteOpenTag(AName) + AValue + WriteCloseTag(AName);
end;

function GetStorageClassName(AValue: TAmazonStorageClass): string;
begin
  case AValue of
    TAmazonStorageClass.Standard: Result := cStandard;
    TAmazonStorageClass.StandardIA: Result := cStandardIA;
    TAmazonStorageClass.Glacier: Result := cGlacier;
    TAmazonStorageClass.ReduceRedundancy: Result := cReducedRedundancy;
  end;
end;

function GetStorageClassValue(const AName: string): TAmazonStorageClass;
begin
  if AName.Equals(cStandard) then Exit(TAmazonStorageClass.Standard);
  if AName.Equals(cStandardIA) then Exit(TAmazonStorageClass.StandardIA);
  if AName.Equals(cGlacier) then Exit(TAmazonStorageClass.Glacier);
  if AName.Equals(cReducedRedundancy) then Exit(TAmazonStorageClass.ReduceRedundancy);

  Result := TAmazonStorageClass.Standard;
end;

{ TAmazonLifeCycleTransition }

class function TAmazonLifeCycleTransition.Create(ADays: Integer; AStorageClass: TAmazonStorageClass): TAmazonLifeCycleTransition;
begin
  Result.FDays := ADays;
  Result.FStorageClass := AStorageClass;
end;

function TAmazonLifeCycleTransition.GetXML;
begin
  Result :=
    WriteOpenTag(cLifeCycleTransition) +
      WriteValueTag(cDays, FDays.ToString) +
      WriteValueTag(cStorageClass, GetStorageClassName(FStorageClass)) +
    WriteCloseTag(cLifeCycleTransition);
end;

{ TAmazonLifeCycleConfiguration.TRule }

function TAmazonLifeCycleRule.AddTransition(ADays: Integer; AStorageClass: TAmazonStorageClass): Integer;
begin
  Result := Length(FTransitions);
  FTransitions := FTransitions + [TAmazonLifeCycleTransition.Create(ADays, AStorageClass)];
end;

class function TAmazonLifeCycleRule.Create(const AID: string; const APrefix: string; AStatus: boolean;
  ATransitions: TArray<TAmazonLifeCycleTransition>; AExpirationDays, ANoncurrentVersionTransitionDays: Integer;
  ANoncurrentVersionTransitionStorageClass: TAmazonStorageClass; ANoncurrentVersionExpirationDays: Integer): TAmazonLifeCycleRule;
begin
  Result.FID := AID;
  Result.FPrefix := APrefix;
  Result.FStatus := AStatus;
  Result.FExpirationDays := AExpirationDays;
  Result.FTransitions := ATransitions;
  Result.FExpirationDays := AExpirationDays;
  Result.FNoncurrentVersionTransitionDays := ANoncurrentVersionTransitionDays;
  Result.FNoncurrentVersionTransitionStorageClass := ANoncurrentVersionTransitionStorageClass;
  Result.FNoncurrentVersionExpirationDays := ANoncurrentVersionExpirationDays;
end;

procedure TAmazonLifeCycleRule.DeleteTransition(AIndex: Integer);
var
  I: Integer;
  LLength: Integer;
begin
  LLength := Length(FTransitions);

  if (AIndex < 0) or (AIndex > LLength-1) then
    raise ERangeError.Create(SRangeCheckException);

  for I := AIndex to LLength-2 do
    FTransitions[I] := FTransitions[I+1];
  SetLength(FTransitions, LLength-1);
end;

function TAmazonLifeCycleRule.GetTransition(AIndex: Integer): TAmazonLifeCycleTransition;
begin
  if (AIndex < 0) or (AIndex > Length(FTransitions)-1) then
    raise ERangeError.Create(SRangeCheckException);

  Result := FTransitions[AIndex];
end;

function TAmazonLifeCycleRule.GetXML: string;
var
  I: Integer;
begin
  Result :=
    WriteOpenTag(cLifeCycleRule) +
      WriteValueTag(cID, ID) +
      WriteValueTag(cPrefix, FPrefix) +
      WriteValueTag(cStatus, cBooleanText[FStatus]);

  for I := Low(FTransitions) to High(FTransitions) do
    Result := Result + FTransitions[I].XML;

  if FExpirationDays > 0 then
    Result := Result +
      WriteOpenTag(cExpiration) +
        WriteValueTag(cDays, FExpirationDays.ToString) +
      WriteCloseTag(cExpiration);

  if FNoncurrentVersionTransitionDays > 0 then
    Result := Result +
      WriteOpenTag(cNoncurrentVersionTransition) +
        WriteValueTag(cNoncurrentDays, FNoncurrentVersionTransitionDays.ToString) +
        WriteValueTag(cStorageClass, GetStorageClassName(FNoncurrentVersionTransitionStorageClass)) +
      WriteCloseTag(cNoncurrentVersionTransition);

  if FNoncurrentVersionExpirationDays > 0 then
    Result := Result +
      WriteOpenTag(cNoncurrentVersionExpiration) +
        WriteValueTag(cNoncurrentDays, FNoncurrentVersionExpirationDays.ToString) +
      WriteCloseTag(cNoncurrentVersionExpiration);

  Result := Result + WriteCloseTag(cLifeCycleRule);
end;

{ TAmazonLifeCycleConfiguration }

function TAmazonLifeCycleConfiguration.AddRule(const AID: string; const APrefix: string; AStatus: boolean;
  ATransitions: TArray<TAmazonLifeCycleTransition>; AExpirationDays, ANoncurrentVersionTransitionDays: Integer;
  ANoncurrentVersionTransitionStorageClass: TAmazonStorageClass; ANoncurrentVersionExpirationDays: Integer): Integer;
begin
  Result := AddRule(TAmazonLifeCycleRule.Create(AID, APrefix, AStatus, ATransitions, AExpirationDays,
    ANoncurrentVersionTransitionDays, ANoncurrentVersionTransitionStorageClass, ANoncurrentVersionExpirationDays));
end;

function TAmazonLifeCycleConfiguration.AddRule(const ARule: TAmazonLifeCycleRule): Integer;
begin
  Result := Length(FRules);
  FRules := FRules + [ARule];
end;

class function TAmazonLifeCycleConfiguration.Create(ARules: TArray<TAmazonLifeCycleRule>): TAmazonLifeCycleConfiguration;
begin
  Result.FRules := ARules;
end;

procedure TAmazonLifeCycleConfiguration.DeleteRule(AIndex: Integer);
var
  I: Integer;
  LLength: Integer;
begin
  LLength := Length(FRules);

  if (AIndex < 0) or (AIndex > LLength-1) then
    raise ERangeError.Create(SRangeCheckException);

  for I := AIndex to LLength-2 do
    FRules[I] := FRules[I+1];
  SetLength(FRules, LLength-1);
end;

function TAmazonLifeCycleConfiguration.GetRule(AIndex: Integer): TAmazonLifeCycleRule;
begin
  if (AIndex < 0) or (AIndex > Length(FRules)-1) then
    raise ERangeError.Create(SRangeCheckException);

  Result := FRules[AIndex];
end;

function TAmazonLifeCycleConfiguration.GetXML: string;
var
  I: Integer;
begin
  Result := WriteOpenTag(cLifeCycleConfiguration);
  for I := Low(FRules) to High(FRules) do
    Result := Result + FRules[I].XML;
  Result := Result + WriteCloseTag(cLifeCycleConfiguration);
end;

end.
