# BackUp

## Steps to run the app

1. Open the back_up/priv/backup_configs/folders.txt file
2. Configure the relevant backup scenario
3. You can have *many* destination folders
4. Make sure the destination folders don't overlap
5. Open a command line
6. Navigate to the **back_up** folder
7. Execute the commands below

```elixir
[neil@Arch-Desktop back_up]$ iex -S mix
Erlang/OTP 22 [erts-10.4.1] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe]

Interactive Elixir (1.8.2) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> BackUp.start
```

Will print "ALL DONE" when finished backing up.