# Dotfiles pessoais portáveis

Base para Linux genérico: arquivos originais de Vim, Zsh e Git, restauração offline em HOME temporário e módulo Home Manager opcional. Incremento em revisão; publicação autorizada em PR draft, sem merge, instalação ou setup nesta máquina. Não é backup completo de projetos ou dados mutáveis.

Para agentes e operadores, começar por [AGENT-SETUP.md](AGENT-SETUP.md) e pelo `AGENTS.md` da raiz. `setup.py` adiciona perfis base/dev/machine/ai, plan-id, doctor, verify e rollback preservando bytes. `restore.py` mantém compatibilidade com o ensaio simples anterior. Ver [config.example.json](config.example.json) para identidade pessoal local com placeholders; nunca preencher identidade real no repo.

## Conteúdo e proveniência

| Arquivo | Conteúdo |
| --- | --- |
| `files/vimrc` | Preferência pessoal revisada e reescrita: `set mouse=c` |
| `files/zshrc` | Aliases pessoais revisados e reescritos: `gs` e `gd`, somente consulta Git |
| `files/gitconfig` | `color.ui=auto` e `user.useConfigOnly=true`; identidade explícita somente em pastas pessoais configuradas |
| `optional/code-settings.json` | Cinco preferências de formatação observadas e reescritas; não aplicadas automaticamente |
| `tool-list.txt` | Baseline proposta de sete CLIs; versões e instaladores dependem do SO/TI |
| `nix/home.nix` | Módulo Home Manager rascunho reaproveitando os três arquivos comuns |
| `setup.py` | Plano, doctor, apply/verify e rollback transacional sem instalador |
| `optional/ai/AGENTS.md` | Orientação opcional declarativa, sem credenciais/provider/permissões |

Não reproduz integralmente prompt, completions, gerenciadores de linguagens, GUI, extensões ou sessões do ambiente original. Não inclui perfis corporativos, includeIf/hosts/acessos, dados de trabalho ou configs de agentes/providers. Nenhuma configuração ativa é carregada pelo restore.

## Ensaio offline

Requer Python 3. `manifest.json` fixa os três arquivos e seus hashes SHA-256. O default é dry-run. `--apply` copia exclusivamente para um diretório vazio sob o diretório temporário do SO; recusa HOME ativo, destinos existentes, symlinks e drift. Não configura permissões de conta ou serviço; os arquivos novos de ensaio têm modo local restrito.

```sh
scratch_home=$(mktemp -d)
python3 restore.py --scratch-home "$scratch_home"
python3 restore.py --scratch-home "$scratch_home" --apply
python3 restore.py --scratch-home "$scratch_home" --verify
```

Não regenerar hashes para silenciar drift: revisar a alteração primeiro. Manifesto não é assinatura; adulteração conjunta de arquivos/manifesto exige revisão independente. Testes locais de restauração/preservação foram executados em Linux. Isso não certifica outro SO/distro ou restauração real.

## Integração em outro notebook

Confirmar SO, arquitetura e política de TI. Selecionar versões e instalar ferramentas apenas pelo método aprovado. Revisar/mesclar cada configuração preservando os arquivos existentes; o restore é para ensaio, não integração automática no HOME real. Preferências opcionais Code devem ser mescladas somente se o editor estiver aprovado.

Definir nome/e-mail Git pessoal manualmente pelo fluxo apropriado. Identidade corporativa segue configuração separada do empregador, sem importar includeIf, hosts ou acessos antigos. Reautenticar contas pessoais via fluxo oficial e MFA/passkey; criar chaves novas conforme política. Não copiar senhas, tokens, auth.json, cookies, chaves privadas, wallets ou sessões. Secrets não entram em Git, arquivos Nix ou Nix store, mesmo com repo privado.

Projetos/WIP precisam de plano independente: selecionar apenas código pessoal aprovado, revisar histórico/diffs por arquivo, preservar staged/unstaged e arquivos novos allowlisted, conferir hashes e testar restauração scratch. Nunca copiar HOME, .config, perfis de navegador ou diretórios de clientes inteiros. Dados mutáveis só entram após confirmação explícita de caminhos e titularidade.

## Nix opcional

O módulo em `nix/home.nix` declara sete CLIs e os três dotfiles comuns. `flake.nix` e `nix/rehearsal.nix` acrescentam entrada standalone com inputs oficiais fixados e identidade sintética Linux, sem ativação. `nix/validate.py` exporta somente seis fontes para ensaio e pode gerar lock/eval/build em ambiente Nix autorizado. Nix continua ausente localmente. O CI autorizado com Nix 2.35.2 gerou o flake.lock real, avaliou x86_64/ARM64 e construiu x86_64, sem ativação. O lock foi revisado e incorporado à branch; reutilização e checks do commit atual devem passar antes de merge. Ver [nix/README.md](nix/README.md).

Nix pode precisar admin para /nix, inclusive single-user; não contornar TI. Se Nix não for autorizado, manter os arquivos comuns e ferramentas instaladas pelo mecanismo aprovado. Drivers/GPU/audio, VPN, login, agentes de segurança e GUI ficam fora da primeira camada.

## Versionamento e publicação

Revisar o diff e testes deste incremento antes de aprovar publicação específica. Não adicionar inventários da máquina, config.local.json, journals, relatórios de outros projetos, patches não auditados ou histórico de outros repos. Conferir dono, destino e visibilidade reais do remoto antes de enviar; não presumir que um repositório existente seja privado. Esta base não configura remotes nem executa commit/push automaticamente.
