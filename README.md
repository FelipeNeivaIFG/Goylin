# Goylin
### W.I.P.

## Descrição

Goylin é uma distribuição Linux baseada em Arch, desenvolvida para o Instituto Federal de Goiás (IFG), visando um sistema leve e otimizado para as necessidades da instituição em salas de aula e laboratórios. Incentivando alternativas open-source, essa escolha promove liberdade de software, reduz custos e incentiva colaboração.
Suporte hardwares antigos, promovendo inclusão digital ao permitir acesso tecnológico a alunos de baixa renda, reduzindo desperdício eletrônico e democratizando a educação digital.

## Dependencias
```bash
sudo pacman -S --needed bash coreutils util-linux pacman arch-install-scripts grep awk sed sudo lsof attr wipefs timedatectl gimp inkscape
```

## Configuração
Arquivos com sufixo `.proto` devem ser configurados e renomeados.

- installer/utils/secrets.sh.proto
- installer/utils/pacman_goylin.conf.proto
- utils/pacman_dev.conf.proto
- installer/etc/hosts.proto


## Instalador - installer/
O **Instalador Goylin** é um script Bash que automatiza a instalação.
- Instalação padrão requer conexão a um repositorio Goylin.
- Instalação de desenvolmimento requer copia local do repositório Goylin em `/srv/http/`.

```bash
sudo ./goylin-installer.sh [-d] [-l] [-*]
```

### Flags

- `-d`: Usa configurações padrão (pula prompts e instala a configuração padrão em `installer/utils/installConf.sh`.)
- `-l`: Instalação para desenvolvimento local.
- `-*`: Ajuda

### Opções de Configuração
Sem a flag `-d`, o script solicita:

- **Dispositivo Alvo**: Ex.: `sda`, `nvme0n1`.
- **Tipo de Disco**: HDD, NVMe ou SSD (padrão: `SSD`).
- **Manter Partição Home**: `y` ou `N`.
- **Tipo de CPU**: AMD, Intel ou Intel sem Vulkan (padrão: Intel sem Vulkan, para `Intel HD Graphics 4000` ou inferior).
- **Perfil**: Perfil de instalação (padrão: `Base`).