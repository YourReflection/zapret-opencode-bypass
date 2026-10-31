# zapret-opencode-bypass

**Keep `opencode` (and models.dev / npm) reachable on networks that drop post-quantum TLS ClientHellos — no VPN.**

Windows service + watchdog around [zapret](https://github.com/bol-van/zapret) (`winws`),
scoped to a short hostlist. One double-click install, survives reboots, self-heals.

## The problem

Some ISPs' DPI drops or resets TLS connections whose ClientHello spans two TCP
segments — which is exactly what modern clients send, because of the post-quantum
hybrid key share (`X25519MLKEM768`, ClientHello ≈ 1.5 KB):

- **opencode** (Bun ≥ 1.4.1, Node 24 / OpenSSL 3.5, Chrome/Edge 124+) — requests hang
  for minutes or fail with `ECONNRESET`;
- `curl.exe` on Windows (Schannel, small ClientHello) — works fine;
- with a VPN — works fine (ClientHello hidden inside the tunnel).

Full diagnosis, measurements and upstream discussion:
**[anomalyco/opencode#60399](https://github.com/anomalyco/opencode/issues/60399)**.

This is not an opencode bug — any modern TLS client is affected. An upstream fix
(a classical-groups retry / TLS option) is being discussed there; until it ships,
this is the working mitigation.

## What it does

zapret (`winws.exe`) intercepts outbound packets via the WinDivert driver and
**desynchronizes the TLS handshake from the DPI's point of view**: the DPI sees a
harmless fake ClientHello (SNI `www.google.com`), while the real handshake with
the real SNI goes through untouched. Encryption is **not** changed, traffic does
**not** go through third parties — it is not a VPN. Only hosts from the list are
affected.

## Install

1. Download the repo as ZIP and extract anywhere (path without spaces is best).
2. Run **`install.cmd`** (accept the UAC prompt).
   - downloads `bol-van/zapret-win-bundle` (official binaries) to `C:\zapret-opencode`
   - installs the **`winws-opencode`** Windows service (start type: auto — starts
     before logon, so it survives reboots)
   - installs the **`zapret-opencode-watchdog`** scheduled task (runs as SYSTEM
     every 5 min; restarts the service if it ever dies, e.g. after antivirus
     removed the driver)
3. Verify: open <https://opencode.ai> in a browser, or just run opencode.

Windows 10/11 x64. No binaries are stored in this repo — they are fetched from the
official zapret-win-bundle at install time.

## Hostlist

Default: `opencode.ai` (all subdomains), `models.dev`, `registry.npmjs.org`.

Edit `C:\zapret-opencode\files\list-opencode.txt` (one domain per line,
lowercase; subdomains match automatically), then restart:

```
sc stop winws-opencode && sc start winws-opencode
```

Your edited hostlist survives reinstalls.

## Stop / remove

| Action | Command |
|---|---|
| Stop | `zapret-opencode-stop.cmd` |
| Start again | `service_opencode_create.cmd` |
| Status | `sc query winws-opencode` |
| Full removal (service + watchdog + folder) | `service_opencode_delete.cmd` |

## Troubleshooting

1. **Not working?** `sc query winws-opencode` → must be `RUNNING`.
   Task Manager should show `winws.exe`.
2. **Service keeps dying** → antivirus is eating `WinDivert64.sys` (signed by
   Microsoft, it is a legitimate packet-interception driver, false positive).
   Add `C:\zapret-opencode` to AV exclusions, then `service_opencode_create.cmd`.
3. **Still blocked with the service stopped?** → that is *not* the PQ-ClientHello
   DPI rule: if `curl https://opencode.ai` also fails while `winws` is stopped,
   the host is blocked by IP/domain — zapret cannot help, you need a VPN/proxy.
4. **Another desync strategy** may be needed if your ISP changes its DPI:
   edit the argument line in `service_opencode_create.cmd`, then rerun it.
   Community-proven alternatives live in
   [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)
   and in [the issue thread](https://github.com/anomalyco/opencode/issues/60399).

## Manual one-shot run (no service)

`zapret-opencode.cmd` starts `winws.exe` in the background until reboot.
Does nothing if the service is already running (avoids two competing filters).

## Credits & licenses

- **[bol-van/zapret](https://github.com/bol-van/zapret)** — the actual DPI-desync
  engine (`winws.exe`), GPL-3.0. Not included in this repo; downloaded from
- **[bol-van/zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle)** —
  official Windows build (v72+), used as-is.
- **WinDivert** — packet interception driver (LGPL), part of the official bundle,
  signed by Microsoft (WHQL).
- Desync strategy for this scenario: as tested and recommended by participants of
  [anomalyco/opencode#60399](https://github.com/anomalyco/opencode/issues/60399).

Scripts in this repository (installer, service/watchdog wrappers, hostlist) are
MIT-licensed — see [LICENSE](LICENSE).

## Русская версия

**Проблема:** провайдерский DPI рвёт TLS-хендшейки с post-quantum ключом
(`X25519MLKEM768`, ClientHello ≈ 1.5 КБ = два TCP-сегмента) → opencode висит
минутами / `ECONNRESET`, а `curl` и VPN работают. Разбор:
[anomalyco/opencode#60399](https://github.com/anomalyco/opencode/issues/60399).

**Решение:** zapret (winws) маскирует начало TLS-рукопожатия от DPI — не VPN,
шифрование не меняется, работает только для сайтов из списка.

**Установка:** распаковать → запустить `install.cmd` (UAC «Да»). Ставит службу
`winws-opencode` (автозапуск после перезагрузки) и watchdog (каждые 5 минут
проверяет и поднимает службу, если её прибил антивирус).

**Остановить:** `zapret-opencode-stop.cmd`. **Удалить полностью:**
`service_opencode_delete.cmd`. **Список сайтов:**
`C:\zapret-opencode\files\list-opencode.txt`, после правки — `sc stop winws-opencode && sc start winws-opencode`.

**Не работает?** `sc query winws-opencode` → должен быть `RUNNING`. Если сайт
не открывается и с ОСТАНОВЛЕННЫМ winws — это не этот DPI, нужен VPN/прокси.
Подробности — в README выше.
