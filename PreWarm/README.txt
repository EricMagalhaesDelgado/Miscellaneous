webapps_prewarm.ctf
A aplicação webapps_prewarm.mlapp foi escrita como alternativa à versão da Mathworks - localizada em %PROGRAMFILES%\MATLAB\MATLAB Runtime\R2024a\bin\win64 - e contempla os módulos 35002 (mcr_graphics), 35003 (mcr_non_interactive), 35010 (mcr_numerics) e 35500 (mcr_webapps).

Trata-se de uma aplicação composta de uma figura vazia, mas que inicializa o modo de operação paralelo do MATLAB, além de mapear os toolboxes necessários para os webapps. 

Esse mapeamento demanda a realização dos seguintes passos, quando da compilação como webapp, gerando o arquivo .CTF.

(1) Coloca-se um breakpoint na linha 657 do arquivo %PROGRAMFILES%\MATLAB\R2024a\toolbox\matlab\depfun\+matlab\+depfun\+internal\Completion.m
>> edit matlab.depfun.internal.Completion

(2) Executa a compilação (webapp).

(3) Ignora a primeira vez em que o MATLAB parar no supracitado breakpoint.

(4) Na segunda vez em que o MATLAB parar no breakpoint, executa-se, no prompt do MATLAB, o comando com os IDs dos produtos que devem ser mapeados em memória pelo Runtime. Abaixo um exemplo com a lista de produtos requeridos pelo webapp SCH.
>> product_external_ids = {35000 35002 35003 35010 35119 35180 35256 35500}

(5) Substitui-se a versão da Mathworks pelo novo arquivo.