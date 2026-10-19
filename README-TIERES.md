# PCSX-ReARMed — versão TIERES

Este é o core `pcsx_rearmed_libretro.dll` distribuído com o
**RetroArch FFW TIERES** (comunidade WE Camp, Winning Eleven 2002 online via
Kaillera). É o PCSX-ReARMed original, no commit `8625c39`
(`r26l-84-g8625c39`), com duas mudanças: o tamanho do buffer de código do
Lightrec e o tratamento de ponteiros inválidos no Lightrec.

A branch `tieres` fica em cima desse commit; a `master` segue o upstream
[libretro/pcsx_rearmed](https://github.com/libretro/pcsx_rearmed).

## O que muda

### 1. Buffer de código de 32 MB

O dynarec Lightrec guarda o código compilado num espaço de **8 MB** no
Windows (`CODE_BUFFER_SIZE`, `libpcsxcore/lightrec/mem.h`). Aqui ele tem
**32 MB**, definido no `Makefile.libretro`. O código C da emulação é o
mesmo do upstream.

Em algumas máquinas o core avisa "Memory map is sub-par" e gera código maior.
Numa partida longa, esses 8 MB acabam. O log mostra
`Could not alloc even after removing old blocks!` e depois
`Unable to compile block!`, e daí vem um de três desfechos:

- o RetroArch fecha sem aviso (`Exiting at cycle ...`);
- o jogo congela;
- a emulação diverge da do outro jogador (desync).

As três coisas foram reproduzidas frame a frame com replays reais de partidas
online.

### 2. Ponteiro inválido não fecha mais o jogo

Alguns jogos leem ou gravam por um ponteiro que não aponta para nada. No
WorldCup26 PepeWEmx, a tela de memory card do modo Copa desenha um retângulo
por um ponteiro que vale `0x1000a000` quando:

- as Opções não foram carregadas do cartão no boot e o jogador entra em
  COPA → LOAD;
- ou o jogador salva a Copa depois de jogar uma rodada.

O interpretador do PCSX (`psxmem.c`) devolve todos os bits ligados numa
leitura de endereço sem mapa e ignora a escrita. O jogo segue sem perceber.

O Lightrec original quebra de dois jeitos:

- no código em C (`lightrec_rw`), ele marca `LIGHTREC_EXIT_SEGFAULT`, e o
  plugin chama `exit(1)`: o RetroArch fecha sem aviso nem registro no
  Windows;
- no código gerado, uma instrução já marcada como acesso direto trata o
  endereço como scratchpad ou BIOS. Ela soma o deslocamento da área e acessa
  a memória do PC ~250 MB fora dela, o que gera a queda `0xc0000005`.

Aqui (`deps/lightrec/lightrec.c`, `emitter.c`, `lightrec-private.h`):

- o caminho em C usa `lightrec_unmapped_ops`, que fazem como o interpretador
  (leitura = `0xff…`, escrita ignorada), e marca a instrução como acesso de
  hardware;
- nos acessos diretos gerados, só o que já cairia dentro dos buffers do PS1
  segue como antes. O resto lê de um buffer de `0xff` ou grava num buffer
  descartável.

Nenhum acesso que antes funcionava muda.

Validado em 2026-10-19 com o krec_harness:

- **COPA → LOAD sem as Opções e Save da Copa depois de uma rodada**, com os
  cartões inseridos como no M. Card da ISO:
  - o core anterior fecha nos dois casos;
  - este não fecha, com o dynarec nem com o interpretador do Lightrec;
  - as telas ficam idênticas às do interpretador do PCSX;
  - o cartão salvo fica byte a byte igual ao do interpretador.
- **Replays reais** (WorldCup26 e dois de Master League): 210 + 447 + 1402
  janelas de digest iguais às dos jogadores, sem desync.

## Compatibilidade

O core anuncia a mesma versão do oficial (`r26 8625c39`). A versão é tirada
de `TIERES_BASE`, não do HEAD desta branch. Assim, quem tem o core oficial e
quem tem este jogam juntos sem aviso no `[SYNC]`.

Validado em 2026-09-28 com o
[krec_harness](https://github.com/TIERES/kaillera-client/tree/master/tools/krec_harness),
que reproduz partidas `.krec` bit a bit contra os digests de RAM gravados
pelos próprios jogadores:

- **com 8 MB (oficial):** uma partida fecha no frame 79 152, outra congela a
  partir de ~8:43 e outra dessincroniza em ~23:30;
- **com 32 MB:**
  - essas partidas vão até o fim com a RAM igual à dos jogadores;
  - nas partidas de teste, as 920 janelas de digest ficaram todas iguais;
  - states do core oficial carregam neste e vice-versa ("Ir ao vivo!"), com
    emulação idêntica.

No pacote, o core vai acompanhado de `cores/pcsx_rearmed_libretro.dll.lck`.
É a trava do RetroArch que impede o atualizador de núcleos de trocá-lo pelo
nightly do buildbot.

## Build (Windows x64)

Num shell **MSYS2 MINGW64**:

```
git clone https://github.com/TIERES/pcsx_rearmed.git
cd pcsx_rearmed && git checkout tieres
bash tieres/build-win64.sh
```

O clone precisa do histórico completo (sem `--depth`), porque a versão vem de
`git describe`. O MSYS2 não tem `git`; o script usa o do Git for Windows.

## Atualizar para um commit novo do upstream

1. Faça rebase da `tieres` no commit novo e ajuste `TIERES_BASE`.
2. Compile e valide com o krec_harness (`audit` e `golive`), usando replays
   gravados com o core anterior.
3. Um commit novo do upstream **muda a versão anunciada**. Todos os
   jogadores precisam trocar de core juntos, e replays antigos podem deixar
   de reproduzir.

## Licença

GPLv2, como o PCSX-ReARMed (ver `COPYING`).
