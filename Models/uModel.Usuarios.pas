unit Model.Usuarios;

interface 

uses System.Classes;

type 


TUsuarios = class
  ID: GUID;
  Codigo: INTEGER;
  Nome: VARCHAR;
  email: VARCHAR;
  Senha: VARCHAR;
  Data: TIMESTAMP;
  Owner: VARCHAR;
  Icone: INTEGER;
  Nivel: INTEGER;
  Departamento: INTEGER;
  Contrato: VARCHAR;
end;
 implementation 

end.
