# BackUp

**Steps to run the app**


```elixir
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
iex(6)> BackUp.set_backup_folder "/home/neil/test_folder_5"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_2",
   "/home/neil/test_folder_3", "/home/neil/test_folder_4",
   "/home/neil/test_folder_5"],
  start_folder: "/home/neil/stuff"
}
iex(7)> BackUp.remove_backup_folder "/home/neil/test_folder_3"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_2",
   "/home/neil/test_folder_4", "/home/neil/test_folder_5"],
  start_folder: "/home/neil/stuff"
}
iex(8)> BackUp.remove_backup_folder "/home/neil/test_folder_4"
%{
  backup_folders: ["/home/neil/test_folder_1", "/home/neil/test_folder_2",
   "/home/neil/test_folder_5"],
  start_folder: "/home/neil/stuff"
}
iex(9)> BackUp.start
```


