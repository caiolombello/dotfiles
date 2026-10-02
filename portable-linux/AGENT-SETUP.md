# Setup consumível por agentes e operadores

Contrato: `setup.py` é offline, plan-first e não instala ferramentas. `restore.py`
continua compatível como ensaio simples de três arquivos; não duplicar a lógica
nova em outro bootstrap. Todos os comandos abaixo usam somente HOME temporário.
Nenhum setup foi aplicado ao notebook de origem.

Sem `--allow-live-home`, mutações só aceitam subdiretórios de `/tmp` ou `/var/tmp`
e recusam HOME atual/da conta. Alterar `TMPDIR` não amplia esse escopo. Flags não
substituem autorização: aplicação real exige aprovação específica do host/TI e
nunca faz parte desta preparação.

## Perfis

| Perfil | Destinos/configuração | Ferramentas verificadas pelo doctor |
| --- | --- | --- |
| base (sempre incluído) | Vim, aliases Git em Zsh, Git com `user.useConfigOnly=true` | python3, git, zsh, vim |
| dev (opcional) | Cinco preferências de formatação Code, sem extensões/providers | tmux, rg, jq, fzf |
| machine (opcional) | EDITOR/VISUAL por nome allowlisted dentro de Zsh e metadata local da máquina | Editor escolhido: vim/nvim/code/zed |
| ai (opcional) | Orientação declarativa em `.config/personal-ai/AGENTS.md` | Sem CLI/conta/provider obrigatório |

Perfis são aditivos; mudar para um conjunto menor não faz prune dos arquivos de
perfis anteriores. `verify` confere o conjunto selecionado; para retirar um perfil,
usar rollback da transação adequada após revisão, ou planejar integração manual.
Não remover configurações ativas por inferência.

Manifests: `manifest.json` fixa três fontes base; `profile-manifest.json` fixa
preferências dev e orientação AI. Destinos são também fixados no código. Machine
e identidade são geradas a partir de esquema restrito, sem eval/source externo.
Um hash detecta drift, não autentica um manifesto adulterado junto com as fontes.

## Primeiro ensaio

Executar a partir de `portable-linux/`, com Python 3, sem instalar nada:

```sh
scratch_home=$(mktemp -d)
python3 setup.py plan --home "$scratch_home"
python3 setup.py doctor --home "$scratch_home"
```

`doctor` inicialmente retorna 2 porque os dotfiles ainda não estão aplicados;
isso é esperado e não autoriza instalação. Revisar o JSON de `plan`: somente
destinos previstos, ações create/update/unchanged, nenhum conflict. O plano não
imprime nome/e-mail reais, apenas hashes e indicador de identidade explícita.

Após revisar, passar literalmente o `plan_id` de 64 caracteres retornado:

```sh
python3 setup.py apply --home "$scratch_home" --plan-id <PLAN_ID_REVISADO>
python3 setup.py verify --home "$scratch_home"
python3 setup.py doctor --home "$scratch_home"
```

Os textos entre `<...>` são placeholders; não colar esses exemplos sem substituir.
Não usar `eval` para consumir JSON. Após apply, `verify` precisa exit 0. Doctor
precisa exit 0 para declarar ferramentas/destino prontos; se faltarem executáveis,
ele informa os nomes e retorna 2, sem executar/download de binários. Instalação é
etapa separada pelo método aprovado do SO/TI.

Alternativa executável, sem placeholders de plan_id: gerar arquivo de plano,
ler/revisar seu JSON e só então executar o segundo bloco. Não automatizar a revisão.

```sh
plan_file=$(mktemp)
python3 setup.py plan --home "$scratch_home" > "$plan_file"
cat "$plan_file"
```

```sh
plan_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["plan_id"])' "$plan_file")
python3 setup.py apply --home "$scratch_home" --plan-id "$plan_id"
python3 setup.py verify --home "$scratch_home"
```

## Identidade Git pessoal

Sem configuração local, `user.useConfigOnly=true` impede Git de inventar identidade;
não se define user.name/email globalmente. Copiar o template para um arquivo
`config.local.json` **fora do repo ou ignorado**, editar localmente e substituir
placeholders; não fornecer credenciais ou e-mail real em chat/logs públicos.

`personal_identity` exige somente name/email; `personal_roots` exige subdiretórios
concretos do HOME selecionado. `${HOME}` é a única substituição permitida; glob,
traversal, raiz inteira do HOME, controls ou expressões shell são rejeitados.
Git recebe includeIf somente para essas pastas pessoais e um arquivo pessoal novo.
Não copiar includeIf, hosts/acessos ou identidade de empregadores.

```sh
python3 setup.py plan --home "$scratch_home" --config <CONFIG_LOCAL_REVISADA> --profile dev --profile machine --profile ai
python3 setup.py apply --home "$scratch_home" --config <CONFIG_LOCAL_REVISADA> --profile dev --profile machine --profile ai --plan-id <PLAN_ID_REVISADO>
python3 setup.py verify --home "$scratch_home" --config <CONFIG_LOCAL_REVISADA> --profile dev --profile machine --profile ai
```

Usar exatamente os mesmos perfis/config durante plan/apply/verify. Testes verificam
identidade dentro da pasta pessoal e ausência fora dela. Não criar configuração
corporativa por este mecanismo; a política do host define sua camada separada.

## Atualizações, verificação e rollback

Arquivo existente não gerenciado com bytes diferentes é conflict e não é tocado.
Se os bytes já forem iguais, é unchanged. Update só é permitido quando o hash atual
coincide com o estado gerenciado previamente. Fonte/destino/config/estado que mudar
depois da revisão invalida o plan_id. Sem overwrite/force.

Um apply revisado pode adotar arquivos com bytes exatamente iguais às fontes sem
alterá-los, registrando somente a gestão local. Repetir apply sobre o mesmo estado
gerenciado é no-op; isso permite atualização posterior sem presumir propriedade
de um arquivo existente diferente.

Apply registra transaction ID, backups dos arquivos gerenciados alterados e
estado anterior em `.local/state/personal-dotfiles`. Cada escrita de arquivo é
atômica; a transação de múltiplos arquivos **não é atomicidade global**. Os arquivos
runtime têm modo restrito e podem conter identidade pessoal; nunca publicar ou
enviar o journal/`config.local.json` por inferência.

```sh
python3 setup.py rollback-plan --home "$scratch_home" --transaction <TRANSACTION_ID>
python3 setup.py rollback --home "$scratch_home" --transaction <TRANSACTION_ID> --plan-id <ROLLBACK_PLAN_ID_REVISADO>
```

Rollback só aceita a transação ativa mais recente e recusa edição do usuário,
backup/journal alterado, paths fora da allowlist ou operações duplicadas. Restaura
bytes anteriores verificados e move arquivos que a transação criou para o journal,
preservando seus bytes. Não usa unlink/rmtree/prune nem remove diretórios. Não
rodar rollback em HOME real sem autorização específica; o comando é mutação.

Falha/crash entre arquivos: preservar tudo; `doctor` relata transactions prepared.
Não repetir apply/rollback cegamente, não apagar journal e não declarar sucesso.
Rollback automático de transação incompleta não está implementado: revisar backups,
hashes e destinos, obter autorização para recuperação manual por arquivo. Scripts,
hooks e configurações recuperadas nunca são executados para "consertar" a falha.

## Exit codes

| Código | Significado e ação |
| --- | --- |
| 0 | Operação planejada/verificada concluída; plan/apply/verify têm funções diferentes |
| 2 | Doctor: ferramentas/destinos ausentes; informar e resolver pelo processo aprovado |
| 3 | Input/esquema/path unsafe ou tentativa live sem autorização/flag; corrigir input |
| 4 | Drift, conflito, integridade, plan_id/estado/journal inválido; preservar e replanejar/revisar |
| 5 | Falha de I/O; preservar e inspecionar eventual journal preparado |

## Testes e Linux limpo

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
zsh -n files/zshrc
python3 -m json.tool manifest.json > /dev/null
python3 -m json.tool profile-manifest.json > /dev/null
```

Testes usam somente fixtures temporárias e HOME/ambiente isolados. Fixtures ficam
preservadas, sem limpeza/deleção automática. Nenhum script recuperado ou serviço
é executado. Há workflow proposto para runner descartável Ubuntu 24.04, action de
checkout pinada por SHA, contents:read e sem persistência de credenciais. Isso não
escolhe distro do notebook nem certifica Linux limpo até o workflow ser realmente executado e seus resultados verificados. Na preparação local, bwrap foi impedido pela
política de namespaces; não houve contorno, instalação ou acesso ao daemon Docker.

Pin do checkout obtido no [commit oficial de v7.0.1](https://github.com/actions/checkout/commit/3d3c42e5aac5ba805825da76410c181273ba90b1).

## Nix e limites

Home Manager permanece opcional e não instalado/avaliado. Reaproveita os arquivos
base, incluindo Git explícito, mas perfis dinâmicos/identidade não têm integração
Home Manager completa. Não misturar dois gerenciadores sobre os mesmos destinos:
symlinks Home Manager são recusados por este bootstrap. Sem lock inventado ou
alegação de reprodutibilidade Nix. SO/TI, identidade, stateVersion e inputs/pins
exigem configuração e avaliação/build posteriores em ambiente autorizado.

O módulo AI é somente orientação, sem provider, endpoint, token, MCP, skills massivas,
históricos, sessões ou mudança de permissões. Backup dos 13 arquivos pendentes e
arquivamento de repos IA continuam fora desta entrega e suspensos. Não declarar
backup completo ou ambiente real configurado porque o ensaio passou.
