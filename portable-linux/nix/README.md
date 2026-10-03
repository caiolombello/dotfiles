# Nix/Home Manager standalone — ensaio sem ativação

Configuração standalone Linux preparada em fonte, ainda **sem parse/eval/build Nix**.
O módulo `home.nix` existente era válido como módulo mínimo, mas faltavam inputs,
identidade de ensaio e ponto de entrada. Ele foi preservado; `../flake.nix` fornece
Nixpkgs/Home Manager e `rehearsal.nix` fornece somente uma identidade sintética.
Nenhuma configuração do notebook ou identidade corporativa foi importada.

## Inputs e alvo

Releases compatíveis: Nixpkgs `nixos-26.05` e Home Manager `release-26.05`, conforme
[orientação oficial standalone](https://raw.githubusercontent.com/nix-community/home-manager/release-26.05/docs/manual/installation/standalone.md).
Refs consultadas em 2026-10-03 e fixadas por revisões reais:

- Nixpkgs: `774debe7a0d1b496e35677ad955a1011c6ff74f3`.
- Home Manager: `e5fcd298a00f08b6e8390baf04aa8edb62203070`; nixpkgs segue o mesmo input.

Os pins de revisão são seleção de fonte, não lock nem evidência de avaliação.
`flake.lock` ainda não existe: somente `nix flake lock` autorizado poderá gerar seus
narHashes e metadados reais. Não inventar hash, timestamp ou lock à mão.
Alvos: avaliação `x86_64-linux` e `aarch64-linux`; build somente x86_64 no CI proposto.
O fixture novo usa username `personal-rehearsal`, HOME `/tmp/personal-home-manager-rehearsal`
e stateVersion `26.05`; não identifica pessoa/host e jamais deve ser ativado.
Num host futuro, stateVersion é a versão inicial escolhida conscientemente, não
campo para acompanhar upgrades automaticamente.

## Exportação mínima e comandos reais

A partir de `portable-linux/`, o comando local de exportação não precisa Nix:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 nix/validate.py
```

Ele preserva scratch e copia somente seis fontes públicas fixas: flake, módulo,
fixture e os três dotfiles. Não exporta o repo inteiro, configs locais, journals,
skills, inventários ou WIP. Nenhum arquivo de HOME é lido. Conferir o diff dessas
seis fontes antes do ensaio; a allowlist sozinha não torna uma fonte modificada segura.
O caminho `source` retornado é o único que deve entrar no Nix store.

Em ambiente descartável **já autorizado com Nix instalado**, após revisão:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 nix/validate.py --build
```

O comando usa HOME temporário, não herda tokens/credenciais, não aceita nixConfig
de flakes, gera lock real, confere revisões, avalia os dois alvos, constrói a geração
x86_64 e compara os três arquivos gerados byte a byte. Nunca executa `activate`,
`home-manager switch`, `nix profile install`, serviços ou garbage collection.
Usa o cache oficial padrão; não adiciona cache/credencial nem desativa TLS/sandbox.
Exit 0 com `validation.json` só ocorre após todas essas verificações; falta de Nix
retorna 2 antes de exportar. Outras falhas retornam não zero e preservam o scratch.

Equivalentes manuais, depois de entrar no diretório `source` exportado:

```sh
nix --extra-experimental-features 'nix-command flakes' flake lock
nix --extra-experimental-features 'nix-command flakes' eval --no-update-lock-file --raw '.#homeConfigurations.rehearsal-x86_64-linux.activationPackage.drvPath'
nix --extra-experimental-features 'nix-command flakes' eval --no-update-lock-file --raw '.#homeConfigurations.rehearsal-aarch64-linux.activationPackage.drvPath'
nix --extra-experimental-features 'nix-command flakes' build --no-update-lock-file --no-link --print-out-paths '.#packages.x86_64-linux.default'
```

Esses comandos escrevem store/downloads no ambiente isolado; não são comandos para
executar no notebook de origem. Um build não ativa configuração e não testa rollback
Home Manager real. Rollback do bootstrap foi testado separadamente; gerações Home
Manager dependem de retenção e podem sumir após GC. Nunca misturar HM e bootstrap
sobre os mesmos destinos (o bootstrap recusa symlinks).

## Plano de CI — depende de aprovação específica

Workflow proposto: `.github/workflows/nix-rehearsal.yml`, Ubuntu 24.04 descartável.
Publicar esse workflow em branch nova dispara push/PR e instala software no runner;
é uma nova execução externa, exige aprovação específica antes de publicar.
Não houve publicação ou execução nesta fase.

1. Checkout oficial pinado, contents:read, credenciais não persistidas.
2. Baixar distribuição oficial Nix **2.35.2** e checksum via HTTPS; verificar checksum.
3. Executar instalador oficial single-user só no runner, sem daemon/canais/alterar
   profile shell. O instalador pode usar sudo para `/nix` **do runner**, nunca do host.
4. Executar `validate.py --build`; nenhuma ativação, nenhum volume/home do notebook.
5. Preservar só lock gerado e relatórios de hashes/build em artifact por sete dias.
   Não fazer commit automático, upload de HOME, pacote result ou logs privados.

Download/checksum do mesmo distribuidor verifica integridade, não é assinatura
independente. A disponibilidade do tarball/checksum e as opções do instalador serão
conferidas na execução; qualquer falha deve parar, sem trocar fonte/desligar checks.
Nix 2.35.2 foi confirmado na [página oficial](https://nixos.org/download/) e
[tag oficial](https://github.com/NixOS/nix/tree/2.35.2).
[Upload artifact v4.6.2](https://github.com/actions/upload-artifact/tree/ea165f8d65b6e75b540449e92b4886f43607fa02)
está pinado por SHA verificado. Sem caches adicionais, self-hosted runner ou secrets.
Após sucesso real, revisar artifact, lock/input graph e outputs antes de incorporar
lock ao repo; a aprovação de CI não autoriza merge ou ativação de host.

## Limites atuais e recuperação futura

Nix ausente localmente; Docker socket e namespaces já bloqueados. Não contornar
permissões/kernel, instalar runtime no notebook ou dizer que a checagem de fontes
é parse/build. O incremento local é preparado, não validado pelo Nix ainda.
Perfis dev/machine/AI e identidade por pasta do bootstrap não foram reimplementados
nesta camada: Home Manager contém somente base e sete CLIs. Não copiar includeIf,
providers/MCP, tokens ou identidade real para obter paridade automática.

Para notebook futuro: confirmar SO/arquitetura/TI, definir módulo de host com
username/HOME/stateVersion explícitos, revisar destinos e backup antes de ativar.
Secrets nunca entram em Git/flake/store, mesmo com repo privado. Reauth é manual.
Nix opcional não substitui o sistema; fallback `setup.py` continua disponível.
Backup/arquivamento dos 13 arquivos excluídos permanece suspenso e independente.

Fontes oficiais: [instalador Nix](https://nix.dev/manual/nix/stable/installation/installing-binary.html),
[geração de lock](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-lock.html),
[store e arquivos locais](https://nix.dev/tutorials/working-with-local-files.html).
