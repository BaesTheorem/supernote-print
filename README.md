# supernote-print

A "Supernote" printer for macOS. Pick it in any print dialog and the page
ends up on your Supernote.

Hackaday ran a piece on an e-reader firmware that speaks IPP so you can print
to it ([If it's electronic paper, why not print to it?](https://hackaday.com/2026/09/10/if-its-electronic-paper-why-not-print-to-it/)).
The Supernote's firmware is closed, so this does the same trick from the Mac
side instead: a local IPP printer catches the PDF and delivers it.

## How it works

1. `ippeveprinter` (already on every Mac) runs as a LaunchAgent on port 8641
   and accepts PDF jobs.
2. A CUPS queue named `Supernote` points at it, with a small PPD so the page
   size defaults to A5 (the A5X and Manta screen). A6 is there for the Nomad.
3. For each job, `bin/supernote-print-job` tries two routes in order:
   - Browse & Access. If the device is on the LAN with WiFi transfer switched
     on, the PDF is POSTed to the device's web server (port 8089) into
     `Document/Printed`, falling back to `Document` and then `INBOX` if that
     folder does not exist. The upload is read back from the device's file
     list before it counts as done.
   - Cloud sync folder. Otherwise the PDF is copied into a folder of your
     Google Drive / Dropbox / OneDrive sync tree and shows up on the device
     the next time you tap sync.
4. A notification tells you which route it took.

Files are named `2026-09-10 1904 Document title.pdf` so they sort by print
time on the device.

## Install

```sh
git clone https://github.com/BaesTheorem/supernote-print.git
cd supernote-print
./install.sh
```

The installer writes `~/.config/supernote-print/config.json` from
`config.example.json` on first run. Set `drive_folder` to wherever your
Supernote's cloud sync lands on this Mac, for example
`~/My Drive/Supernote/Document/Printed`. Leave it empty if you only want the
WiFi route. `device_host` can stay `auto`; the job scans the local /24 for a
Supernote and remembers the last address that answered.

`uninstall.sh` removes the queue and the LaunchAgent.

## Test it

```sh
lp -d Supernote -t "Hello Supernote" /etc/hosts
tail ~/Library/Logs/supernote-print/jobs.log
```

## Notes

- macOS 26 warns that PPD-based queues are deprecated. The `everywhere`
  driver works too but defaults to Letter and cannot be told about A5, since
  this build of `ippeveprinter` rejects both `-a` attribute files and `-P`
  PPDs. Recreate the queue with `-m everywhere` if a future macOS drops PPDs;
  you lose the A5 default and pick it per job instead.
- Browse & Access does not overwrite. Printing the same title twice in one
  minute gets a "refused" line in the log and falls through to the next
  folder, then to the sync folder.
- PostScript jobs are converted with `ps2pdf` if ghostscript is installed.
  With the shipped PPD, macOS always sends PDF, so this only matters for
  raw `lp` use.
- The upload protocol (multipart POST `file` to `/<folder>` on port 8089,
  listing JSON embedded in the page) is the one
  [supernote-sync](https://github.com/jbchouinard/supernote-sync) and the
  [Obsidian plugin](https://github.com/philips/supernote-obsidian-plugin) use.
