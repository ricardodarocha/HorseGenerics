unit uFactory.Provider;

interface

uses uProvider.Firedac, System.SysUtils, System.JSON;

type

TProviderFactory = class
  class function New(const aFilename: TFilename): TProviderFiredac; overload;
  class function New(const aParametros: TJsonObject): TProviderFiredac; overload;
end;

implementation

{ TProviderFactory }

class function TProviderFactory.New(const aFilename: TFilename): TProviderFiredac;
begin
  Result := TProviderFiredac.Create(nil);
  Result.LoadConnection(aFilename);
end;

class function TProviderFactory.New(const aParametros: TJsonObject): TProviderFiredac;
begin
  Result := TProviderFiredac.Create(nil);
  Result.LoadConnection(aParametros);
end;

end.
