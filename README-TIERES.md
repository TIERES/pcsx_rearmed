# PCSX-ReARMed — versão TIERES

Este é o core `pcsx_rearmed_libretro.dll` distribuído com o
**RetroArch FFW TIERES** (comunidade WE Camp, Winning Eleven 2002 online via
Kaillera). É o PCSX-ReARMed original, no commit `8625c39`
(`r26l-84-g8625c39`), com uma única mudança de build.

A branch `tieres` fica em cima desse commit; a `master` segue o upstream
[libretro/pcsx_rearmed](https://github.com/libretro/pcsx_rearmed).

## O que muda

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
