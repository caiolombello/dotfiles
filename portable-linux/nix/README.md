# Nix opcional — módulo rascunho

`home.nix` é um módulo Home Manager mínimo implementado em fonte, não uma instalação standalone completa nem uma configuração ativável já validada. Reutiliza exatamente os três arquivos comuns e declara sete CLIs. Não instala Nix, altera login shell, habilita serviços, ativa contas ou copia configuração corporativa.

Alvo provisório: Linux genérico. A configuração standalone do host, criada somente depois de aprovação de TI, deve importar este módulo e definir `home.username`, `home.homeDirectory` e `home.stateVersion` com dados/versão confirmados. Não inferir nome de conta ou diretório a partir do notebook de origem; não atualizar stateVersion automaticamente. Selecionar release compatível de Nixpkgs/Home Manager e guardar a seleção revisada. Não há flake.lock gerado: sem Nix/rede nesta fase, não inventamos um lock ou pin alegadamente validado.

Verificação atual: checagem local de delimitadores, referências existentes, allowlist de pacotes/arquivos e ausência de imports externos/secrets. Isso **não substitui** parser/eval/build Nix. Nix não está instalado neste equipamento; parse e avaliação completos são pendências explícitas. Depois de TI aprovar ambiente de ensaio apropriado, usar parser/eval e build, inspecionar outputs e diff da ativação antes de qualquer switch. Não executar switch nesta preparação.

Nix pode precisar admin para `/nix`, mesmo single-user; não contornar a política de TI. Cache/downloads dependem de rede/proxy permitido; não adicionar caches ou desligar TLS. Nix store é legível por outros usuários: nenhum segredo literal, nem mesmo de repo privado. Dados mutáveis e WIP precisam de backup separado. Rollback depende de gerações preservadas; garbage collection pode remover esse caminho.

Fallback permanece `restore.py` e instalação das ferramentas pelo método aprovado. Preferências Code opcionais não entram neste módulo nem no restore inicial; revisar/mesclar separadamente com configuração existente se Code estiver aprovado.

Fontes oficiais: [instalação Home Manager](https://nix-community.github.io/home-manager/installation.html), [configuração](https://nix-community.github.io/home-manager/usage/configuration.html), [instalação Nix](https://nix.dev/manual/nix/stable/installation/installing-binary.html), [arquivos locais e store](https://nix.dev/tutorials/working-with-local-files.html), [garbage collection](https://nix.dev/manual/nix/stable/package-management/garbage-collection.html).
