#  STHAL Dependency

Since `STHAL` is a legacy dependency we renaming `ST` dependencies with prefix `__ST` for example `__STHAL` to mark them as **internal dependency**.
Public interface should not have this. This allows us to replace `STHAL` down the line with a different HAL resolution dependency. 



