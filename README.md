# BackUp

**Elixir Application to back up files & folders**


```elixir
[neil@Arch-Desktop back_up]$ iex -S mix
Erlang/OTP 22 [erts-10.4.1] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe]
Interactive Elixir (1.8.2) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> BackUp.set_start_folder "/home/neil/stuff"
%{backup_folder: "", start_folder: "/home/neil/stuff"}

iex(2)> BackUp.set_backup_folder "/home/neil/test_folder"
%{backup_folder: "/home/neil/test_folder", start_folder: "/home/neil/stuff"}

iex(3)> BackUp.start
```


