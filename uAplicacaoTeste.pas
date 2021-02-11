unit uAplicacaoTeste;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,

  Horse,

  {$REGION'JSON'}
  Horse.Jhonson,
  System.JSON,
  {$ENDREGION}

  {$REGION 'EXCEPTION'}
  Horse.HandleException,
  {$ENDREGION}

  {$REGION 'QUERY'}
   Horse.Query,
   FireDAC.Comp.Client,
   Data.DB,
  {$ENDREGION}

  Horse.BasicAuthentication, Vcl.StdCtrls;

type
  TfrmAplicacaoTeste = class(TForm)
    labelStatus: TLabel;
  private

  public

  end;

var
  frmAplicacaoTeste: TfrmAplicacaoTeste;
  Usuario: string;
  ASenha: string;

implementation

{$R *.dfm}

uses uDados,

  {$REGION 'Domínios'}
  uApi
  {$ENDREGION}

;

initialization

begin

  {$REGION 'Authentication'}
  THorse.Use(HorseBasicAuthentication(
    function(const AUsername, APassword: string): Boolean

  begin
      Usuario:= AUsername;
      ASenha := APassword;
      Result := AUsername.Equals('admin') and APassword.Equals('123');
    end));
  {$ENDREGION}

  {$REGION 'Midlewares'}
  THorse.Use(Jhonson);
  THorse.Use(HandleException);
  THorse.Use(Query);
  {$ENDREGION}

  {$REGION 'Api'}
    uApi.Dominios.Publicar;
  {$ENDREGION}

//  try
    THorse.Listen(9000);

//    frmAplicacaoTeste.LabelStatus.Caption := 'On-line';
//    frmAplicacaoTeste.LabelStatus.Font.Color := clGreen;
//  except
//    ON e:Exception do
//    begin
//      frmAplicacaoTeste.LabelStatus.Caption := 'Erro';
//      frmAplicacaoTeste.LabelStatus.Hint := e.ClassName + '|' + e.message;
//      frmAplicacaoTeste.LabelStatus.Font.Color := clRed;
//      frmAplicacaoTeste.LabelStatus.Showhint := true;
//    end;
//  end;
end;

end.
