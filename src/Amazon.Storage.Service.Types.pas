unit Amazon.Storage.Service.Types;

interface

type
{$SCOPEDENUMS ON}
  TAmazonProtocol  = (http, https);
{$SCOPEDENUMS OFF}

  TAmazonProtocollHelper = record helper for TAmazonProtocol
    function GetValue: string;
  end;

implementation

uses TypInfo;

function TAmazonProtocollHelper.GetValue: string;
begin
  Result := GetEnumName(TypeInfo(TAmazonProtocol), Integer(Self));
end;

end.
