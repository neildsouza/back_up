# BackUp

**Steps to run the app**


Will print "All done" when finished backing up.


```elixir
[neil@Arch-Desktop back_up]$ iex -S mix

Erlang/OTP 22 [erts-10.4.1] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe]
Interactive Elixir (1.8.2) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> BackUp.set_start_folder "/home/neil/stuff"
%{backup_folders: [], start_folder: "/home/neil/stuff"}

iex(2)> BackUp.set_backup_folder "/home/neil/test_folder_1"
%{
  backup_folders: ["/home/neil/test_folder_1"],
  start_folder: "/home/neil/stuff"
}

iex(3)> BackUp.set_backup_folder "/home/neil/test_folder_2"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_2"],
  start_folder: "/home/neil/stuff"
}

iex(4)> BackUp.set_backup_folder "/home/neil/test_folder_3"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_2",
   "/home/neil/test_folder_3"],
  start_folder: "/home/neil/stuff"
}

iex(5)> BackUp.set_backup_folder "/home/neil/test_folder_4"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_2",
   "/home/neil/test_folder_3", "/home/neil/test_folder_4"],
  start_folder: "/home/neil/stuff"
}

iex(6)> BackUp.remove_backup_folder "/home/neil/test_folder_2"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_3",
   "/home/neil/test_folder_4"],
  start_folder: "/home/neil/stuff"
}

iex(7)> BackUp.start
```


