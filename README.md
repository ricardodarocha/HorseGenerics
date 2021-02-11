# Horse Generics

Publishes an [GET PUT POST DELETE] API easily to a list of &lt;T> classes using generics and Horse

# Motivation

With basic infrastructure of HORSE
{AUTHENTICATION}
{JSON}
{EXCEPTION}
Create a new endpoint with one line of code for a model = Class <T> 

# How it works

Use Generic Controller  **TApiController<T>** to create [GET PUT POST DELETE] routes in your API 
 
```Delphi
class function Dominios.Publish: String;

begin
  TApiController<TConsulta>.Publicar('/consulta');
  TApiController<TMedicao>.Publicar('/medicao');
end;
```

It returns
```Shell
GET /consulta/
GET /consulta/:codigo
POST /consulta/
PUT /consulta/:codigo
DELETE /consulta/:codigo
```

# Requires

Horse https://github.com/HashLoad/horse

Dataset.Serialize https://github.com/viniciussanchez/dataset-serialize

Ricardo Rocha pinned projects https://github.com/ricardodarocha/

  https://github.com/ricardodarocha/RttiInterceptor
  
  https://github.com/ricardodarocha/EntityMapper
  
  https://github.com/ricardodarocha/SqlExtrator
