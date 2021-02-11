program pAplicacaoTeste;

uses
  Vcl.Forms,
  uAplicacaoTeste in 'uAplicacaoTeste.pas' {frmAplicacaoTeste},
  uDados in 'uDados.pas' {DMDados: TDataModule},
  uProvider.Firedac in 'uProvider.Firedac.pas' {ProviderFiredac: TDataModule},
  uApi in 'uApi.pas',
  uController.Api in 'Controller\uController.Api.pas',
  uModel.Consulta in 'Models\uModel.Consulta.pas',
  uModel.Indicador in 'Models\uModel.Indicador.pas',
  uModel.Medicao in 'Models\uModel.Medicao.pas',
  uFactory.Provider in 'Factory\uFactory.Provider.pas',
  uController.ORM in 'Controller\uController.ORM.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  ReportMemoryLeaksOnShutdown := True;
  Application.CreateForm(TfrmAplicacaoTeste, frmAplicacaoTeste);
  Application.CreateForm(TProviderFiredac, ProviderFiredac);
  Application.Run;
end.
