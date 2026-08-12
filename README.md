# BySteel Carlock

Sistema de chaves, fecho central, lockpick e alarmes para servidores FiveM com ESX Legacy.

O recurso permite instalar alarmes por oficinas autorizadas, torna o arrombamento mais demorado em viaturas protegidas, alerta as autoridades através do `dynamic_dispatch` e regista as ações importantes num webhook STAFF.

## Funcionalidades

- Trancar e destrancar viaturas próprias através da tecla `L` ou do `ox_target`.
- Partilhar e remover chaves temporárias entre jogadores.
- Arrombar viaturas trancadas com o item `lockpick`.
- Instalar alarmes com o item `vehicle_alarm`.
- Restringir a instalação por job e nível mínimo.
- Configurar o nome de cada oficina apresentado nos logs.
- Aumentar automaticamente a duração da lockpick em viaturas com alarme.
- Ativar buzina e luzes intermitentes durante o arrombamento.
- Enviar dispatch com blip `161`, cor `1` e matrícula da viatura.
- Remover o alarme da base de dados 15 segundos após um arrombamento bem-sucedido.
- Enviar logs Discord para arrombamentos e instalações.

## Requisitos

- [ESX Legacy](https://github.com/esx-framework/esx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- `fx_notify`
- `dynamic_dispatch`

O recurso assume que a tabela de veículos do servidor se chama `owned_vehicles` e contém uma coluna `plate`.

## Instalação

1. Extrai a pasta `bysteel_carlock` para a diretoria de recursos do servidor.
2. Importa o ficheiro `install.sql` na base de dados utilizada pelo ESX.
3. Confirma que os itens `lockpick` e `vehicle_alarm` existem no `ox_inventory`.
4. Configura os jobs, oficinas, tempos e dispatch em `configs/config.lua`.
5. Configura o webhook STAFF em `server/logs.lua`.
6. Adiciona `ensure bysteel_carlock` depois das dependências no `server.cfg`.
7. Reinicia o servidor. Reiniciar apenas o recurso também funciona depois da primeira instalação SQL.

Exemplo de ordem de arranque:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure ox_target
ensure ox_inventory
ensure fx_notify
ensure dynamic_dispatch
ensure bysteel_carlock
```

## Base de dados

O ficheiro `install.sql` cria, se ainda não existir, a seguinte coluna:

```sql
`vehicle_alarm` TINYINT(1) NOT NULL DEFAULT 0
```

Valores utilizados:

| Valor | Estado |
|---:|---|
| `0` | Sem alarme |
| `1` | Alarme instalado |

O SQL é idempotente: pode ser executado novamente sem apagar os alarmes já instalados.

## Itens do ox_inventory

Adiciona os itens em `ox_inventory/data/items.lua` caso ainda não existam. Não dupliques uma entrada já presente.

```lua
['lockpick'] = {
    label = 'Lockpick',
    weight = 100,
    stack = true,
    close = true,
    description = 'Ferramenta utilizada para forçar fechaduras de viaturas.'
},

['vehicle_alarm'] = {
    label = 'Alarme de viatura',
    weight = 1000,
    stack = true,
    close = true,
    description = 'Sistema de alarme para instalação numa viatura.'
},
```

Reinicia o `ox_inventory` ou o servidor depois de adicionar os itens.

## Configurar mecânicos e oficinas

Os jobs autorizados são definidos em `BySteel.AlarmInstallation.AllowedJobs`:

```lua
AllowedJobs = {
    mechanic = 0,
    bennys = 2,
},
```

O número corresponde ao nível mínimo:

- `mechanic = 0` permite todos os níveis desse job.
- `bennys = 2` permite apenas nível 2 ou superior.
- Um job ausente da tabela não pode instalar alarmes.

Define também o nome público da oficina para os logs STAFF:

```lua
WorkshopLabels = {
    mechanic = 'Los Santos Customs',
    bennys = 'Benny\'s Original Motor Works',
},
```

A autorização é verificada no cliente para apresentar a opção e novamente no servidor antes de atualizar a base de dados ou remover o item.

## Instalação de alarmes

1. Um funcionário autorizado aproxima-se de uma viatura registada em `owned_vehicles`.
2. Seleciona **Instalar alarme** através do `ox_target`.
3. O servidor confirma o job, nível, item, matrícula e estado atual do alarme.
4. Após o progresso terminar, `vehicle_alarm` passa para `1` e um item é consumido.
5. A instalação é enviada para os logs STAFF com mecânico, oficina, cargo e matrícula.

Não é possível instalar outro alarme numa viatura que já tenha `vehicle_alarm = 1`.

## Lockpick e comportamento do alarme

- A opção de lockpick aparece apenas em viaturas trancadas.
- Sem alarme, o progresso demora 7 segundos por predefinição.
- Com alarme, o progresso demora 14 segundos por predefinição.
- O dispatch é enviado assim que o arrombamento começa numa viatura protegida.
- As luzes piscam e a buzina toca durante a tentativa.
- Se a tentativa for cancelada, o alarme permanece instalado.
- Se a abertura terminar com sucesso, o alarme continua durante mais 15 segundos.
- No fim desses 15 segundos, a base de dados é atualizada para `vehicle_alarm = 0`.
- A lockpick é consumida apenas quando o arrombamento termina com sucesso.

Os tempos podem ser alterados em `BySteel.Lockpick`:

```lua
Duration = 7000,

Alarm = {
    Duration = 14000,
    PostUnlockDuration = 15000,
    BlinkInterval = 450,
    HornDuration = 400,
}
```

Todos os valores de duração estão em milissegundos.

## Dispatch

A integração é configurada em `BySteel.Lockpick.Alarm`:

```lua
DispatchJobs = { 'police' },
DispatchMessage = 'Tentativa de furto de viatura',
DispatchCode = '10-60',
DispatchBlip = 161,
DispatchColor = 1,
```

O evento enviado segue este formato:

```lua
TriggerServerEvent(
    'dynamic_dispatch:CreateDispatch',
    jobs,
    message,
    code,
    coords,
    blip,
    color
)
```

Para alertar mais departamentos, adiciona os respetivos jobs a `DispatchJobs`.

## Logs STAFF

Abre `server/logs.lua` e coloca o webhook privado no campo:

```lua
Webhook = 'COLOCA_AQUI_O_WEBHOOK_DISCORD'
```

O webhook encontra-se num ficheiro carregado apenas pelo servidor e não é enviado aos clientes.

São registados:

- Carro assaltado com lockpick: jogador, ID, Discord, identificador ESX, matrícula e presença de alarme.
- Instalação de alarme: mecânico, ID, Discord, identificador ESX, oficina, job, cargo e matrícula.

Se não pretenderes utilizar logs, define `Enabled = false` no mesmo ficheiro.

## Configuração rápida

| Opção | Localização | Predefinição |
|---|---|---:|
| Item de lockpick | `BySteel.Lockpick.Item` | `lockpick` |
| Duração sem alarme | `BySteel.Lockpick.Duration` | `7000` |
| Duração com alarme | `BySteel.Lockpick.Alarm.Duration` | `14000` |
| Duração após abertura | `BySteel.Lockpick.Alarm.PostUnlockDuration` | `15000` |
| Item do alarme | `BySteel.AlarmInstallation.Item` | `vehicle_alarm` |
| Duração da instalação | `BySteel.AlarmInstallation.Duration` | `10000` |
| Jobs autorizados | `BySteel.AlarmInstallation.AllowedJobs` | `mechanic` |
| Blip do dispatch | `BySteel.Lockpick.Alarm.DispatchBlip` | `161` |
| Cor do dispatch | `BySteel.Lockpick.Alarm.DispatchColor` | `1` |

## Export disponível

O recurso mantém o export de servidor para partilhar uma chave:

```lua
local success = exports['bysteel_carlock']:shareKey(playerId, plate)
```

O retorno é `true` quando a chave foi atribuída e `false` quando os dados são inválidos ou o jogador já possuía essa chave.

## Resolução de problemas

### A opção de instalar não aparece

- Confirma que `BySteel.AlarmInstallation.Enabled` está definido como `true`.
- Confirma o nome exato do job em `AllowedJobs`.
- Confirma que o nível do jogador é igual ou superior ao configurado.
- Confirma que `BySteel.targetSupport` está definido como `true`.

### A instalação indica que a viatura não está registada

- Confirma que a matrícula existe em `owned_vehicles.plate`.
- Confirma que o script de garagem guarda as matrículas no mesmo formato utilizado pelo ESX.

### O dispatch não aparece

- Confirma que `dynamic_dispatch` arranca antes do carlock.
- Confirma os nomes dos jobs em `DispatchJobs`.
- Confirma que a versão do dispatch aceita os argumentos de blip e cor apresentados acima.

### Os logs não chegam ao Discord

- Confirma o webhook em `server/logs.lua`.
- Confirma que `Enabled = true`.
- Verifica a consola por mensagens `[bysteel_carlock] Falha ao enviar log STAFF`.

## Licença

Este programa é software livre: pode ser redistribuído e/ou modificado sob os termos da GNU General Public License, conforme publicada pela Free Software Foundation, na versão 3 da licença ou, por opção do utilizador, qualquer versão posterior.

Consulta o ficheiro `LICENSE` para os termos completos da `GPL-3.0-or-later`.

Copyright © 2026 BySteel.
