# mac-fancurve

A fan curve for an Apple Silicon MacBook Pro. A small daemon reads the CPU and GPU die
temperatures and sets both fans from the hottest one. I wrote it for an M3 Max that runs a
local LLM on the GPU for hours: with the stock fan control the machine got hot enough to
drain the battery while plugged in.

## What it does

- Under 50 C the fans belong to macOS (on a MacBook Pro they are usually off).
- From 50 C to 70 C the target speed rises in a straight line from each fan's minimum to
  its maximum. At 70 C and above both fans run at full speed.
- When the temperature has stayed at or under 45 C for a minute, the fans go back to macOS.
- The daemon starts at boot (a LaunchDaemon) and takes control again after sleep.
- If a sensor or a fan limit cannot be read, it gives the fans back to macOS. It never
  forces a fan to a speed it could not compute.

The thresholds are the four numbers at the top of `fancurve.sh`.

## Install

Needs the Xcode Command Line Tools (`xcode-select --install`).

```sh
./install.sh
```

It builds the `smc` command from [smcFanControl](https://github.com/hholtmann/smcFanControl)
(GPL-2.0, downloaded at install time, not part of this repo), installs it with the daemon
in `/usr/local/bin`, and adds one sudoers rule so the `fans` command can change the mode
without a password. `./uninstall.sh` removes all of it and returns the fans to macOS.

## Use

```sh
fans status   # mode, speeds
fans curve    # follow the temperature (default)
fans max      # both fans at full speed
fans auto     # leave the fans to macOS
```

## Notes

- Tested on one machine: MacBook Pro 16" M3 Max. The sensor keys in `fancurve.sh` are the
  M3 Pro/Max die sensors; other chips use other keys (`smc -l` lists them).
- macOS still throttles and protects the hardware whatever this script does.
