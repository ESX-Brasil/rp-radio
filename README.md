# rp-radio
Um rádio no jogo que utiliza a API de rádio esx_mumble_voip para FiveM

#### Note
Por padrão, o rádio está desativado (destinado a ser usado como um item do jogo) para fornecer aos jogadores o rádio por padrão no client.lua na parte superior, altere `Radio.Has` para` true`, se você quiser faça com que ele seja um item, veja as respostas na postagem no fórum FiveM; há um tutorial para adicioná-lo como um item do ESX.

A exportação que é usada para dar / receber rádio dos players é `export:["rp-radio"]:SetRadio(true/false)` ou o evento `Radio.Set`

### Requerimento

- [ESX Mumble VOIP](https://github.com/ESX-Brasil/esx_mumble_voip)

### Exportações
Getters

| Exportação       | Descrição                                           | Tipo de retorno |
| ---------------- | --------------------------------------------------- | --------------- |
| IsRadioOpen      | Verifique se o jogador está segurando o rádio       | bool            |
| IsRadioOn        | Verifique se o rádio está ligado                    | bool            |
| IsRadioAvailable | Verifique se o jogador tem um rádio                 | bool            |
| IsRadioEnabled   | Verifique se o rádio está ativado                   | bool            |
| CanRadioBeUsed   | Verifique se o rádio pode ser usado                 | bool            |

Setters

| Exportação                      | Descrição                                                           | Parâmetros    |
| ------------------------------- | ------------------------------------------------------------------- | ------------- |
| SetRadioEnabled                 | Defina se o rádio está ativado ou não                               | bool          |
| SetRadio                        | Defina se o jogador tem um rádio ou não                             | bool          |
| SetAllowRadioWhenClosed         | Permitir que o jogador transmita quando fechado                     | bool          |
| AddPrivateFrequency             | Tornar uma frequência privada                                       | int           |
| RemovePrivateFrequency          | Tornar pública uma frequência privada                               | int           |
| GivePlayerAccessToFrequency     | Conceda a um jogador acesso para usar uma frequência privada        | int           |
| RemovePlayerAccessToFrequency   | Remova o acesso de um jogador para usar uma frequência privada      | int           |
| GivePlayerAccessToFrequencies   | Conceda a um jogador acesso para usar várias frequências privadas   | int, int, ... |
| RemovePlayerAccessToFrequencies | Remova o acesso de um jogador para usar várias frequências privadas | int, int, ... |

### Comandos

| Comando    | Descrição                       |
| ---------- | ------------------------------- |
| /radio     | Abrir / fechar o rádio          |
| /frequencia| Escolha a frequência de rádio   |

### Eventos

| Evento       | Descrição                               | Parâmetros             |
| ------------ | --------------------------------------- | ---------------------- |
| Radio.Toggle | Abre / fecha o rádio                    | none                   |
| Radio.Set    | Defina se o jogador tem um rádio ou não | bool                   |

### Preview

- [ESXBrasil - RP Radinho](https://streamable.com/rfwp3h)

# Servidores Iceline Hosting e ESX Brasil

![Iceline hosting](https://cdn.discordapp.com/attachments/704310570098229309/704331510203023490/banner.gif)

Você está pensando em abrir um servidor FiveM por conta própria? 
[Iceline Hosting](https://iceline-hosting.com/billing/aff.php?aff=122) fornece servidores de jogos, VPS de jogos de ponta com proteção contra DDoS incluída e muito mais!

Existe um complemento de suporte gerenciado opcional disponível para servidores de jogos e VPS de jogos que adicionam os seguintes serviços:

- Investigação e correção de erros em relação ao servidor ou scripts de terceiros
- Instalando scripts ou software de terceiros
- Recuperação de dados perdidos

Vá para [Iceline Hosting](https://iceline-hosting.com/billing/aff.php?aff=122) e use o código promocional `ESXBRAZIL` para ganha 20% no primeiro mês em servidor.
Ele da descontos em outros serviços da empresa.

