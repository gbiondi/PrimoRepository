# PrimoRepository

Questo repository contiene uno script bash semplice per copiare tutti i file
da una cartella A a una cartella B.

## Uso di `script.sh` (copia tutti i file)

Esempi rapidi:

1) Copia tutto (ricorsivo, preservando attributi) da A a B usando rsync quando disponibile:

```bash
./script.sh /path/to/A /path/to/B
```

2) Test (dry-run) — non modifica nulla (richiede rsync):

```bash
./script.sh --dry-run /path/to/A /path/to/B
```

3) Forza la creazione della destinazione senza prompt:

```bash
./script.sh --force /path/to/A /path/to/B
```

Nota: su Windows esegui lo script usando Git Bash, WSL, o un'installazione di bash compatibile.
