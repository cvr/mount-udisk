# mount-udisk.sh
Simple command line interface (cli) in bash to mount mass storage devices such as USB disks and hard drives.  Mounts partitions by volume label.

## Usage
```sh
mount-udisk.sh <label> [rw|ro|u]
```
where `<label>` is the volume label.  The media is mounted on `/media/<label>`.

## Options:
  * `rw`    mount read-write (default) 
  * `ro`    mount read-only
  * `u`     unmount

## Caveats:
  * No spaces in volume label. Won't work.

## Copyright notice

Copyright (C) 2016 by Carlos Veiga Rodrigues. All rights reserved.
author:  maxdev137 <maxdev137@sbcglobal.net> (original)
         Carlos Veiga Rodrigues <cvrodrigues@gmail.com>

This bash script was originally made by maxdev137 and made available at
http://stackoverflow.com/questions/483460/ with the GNU GPL v3 copyright.
Originally it was a frontend to `udisks`. I made changes to output a list
of available devices using `lsblk` and added commands to use `udisksctl`
and `gvfs-mount` (the later are commented).

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For more details consult the GNU General Public License at:
http://www.gnu.org/licenses/gpl.html

